import { boundedJson, HttpError, json, respond } from "../_shared/http.ts";
import {
  createGooglePlayClient,
  type GooglePlayClient,
} from "../_shared/google_play_client.ts";

interface NotificationDeps {
  expectedPackage: string;
  pubsub: { authenticate(request: Request): Promise<boolean> };
  catalog: {
    findProduct(
      id: string,
    ): Promise<{ grantAmount: number; active: boolean } | null>;
  };
  google: GooglePlayClient;
  economy: {
    refund(
      input: {
        purchaseToken: string;
        eventId: string;
        refundType: number;
      },
    ): Promise<Record<string, unknown>>;
    grantPurchase(
      input: Record<string, unknown>,
    ): Promise<{ balance: number; debt: number; duplicate: boolean }>;
  };
}

export async function handler(
  request: Request,
  deps: NotificationDeps,
): Promise<Response> {
  return await respond(async () => {
    if (request.method !== "POST") {
      return json(405, { code: "method_not_allowed" });
    }
    if (!await deps.pubsub.authenticate(request)) {
      throw new HttpError(401, "invalid_pubsub_authorization");
    }
    const envelope = await boundedJson(request, 16_384) as {
      message?: { messageId?: string; data?: string };
    };
    if (!envelope?.message?.messageId || !envelope.message.data) {
      throw new HttpError(400, "invalid_body");
    }
    let event: {
      packageName?: string;
      oneTimeProductNotification?: {
        purchaseToken?: string;
        notificationType?: number;
        sku?: string;
      };
      voidedPurchaseNotification?: {
        purchaseToken?: string;
        productType?: number;
        refundType?: number;
      };
    };
    try {
      event = JSON.parse(atob(envelope.message.data));
    } catch {
      throw new HttpError(400, "invalid_body");
    }
    if (event.packageName !== deps.expectedPackage) {
      throw new HttpError(400, "package_mismatch");
    }
    const voided = event.voidedPurchaseNotification;
    if (voided) {
      if (
        !voided.purchaseToken || typeof voided.productType !== "number" ||
        typeof voided.refundType !== "number"
      ) {
        throw new HttpError(400, "invalid_body");
      }
      if (voided.productType !== 2) {
        return json(200, { ignored: true, reason: "non_one_time_product" });
      }
      const result = await deps.economy.refund({
        purchaseToken: voided.purchaseToken,
        eventId: envelope.message.messageId,
        refundType: voided.refundType,
      });
      if (result.reason === "unknown_token") {
        throw new HttpError(503, "purchase_not_found_retry");
      }
      return json(200, result);
    }
    const notice = event.oneTimeProductNotification;
    if (!notice?.purchaseToken || typeof notice.notificationType !== "number") {
      throw new HttpError(400, "invalid_body");
    }
    if (notice.notificationType === 1) {
      if (!notice.sku) throw new HttpError(400, "invalid_body");
      const product = await deps.catalog.findProduct(notice.sku);
      if (!product?.active) {
        throw new HttpError(503, "reconciliation_retry_required");
      }
      const purchase = await deps.google.getProductPurchase(
        deps.expectedPackage,
        notice.sku,
        notice.purchaseToken,
      );
      const lineItem = purchase.lineItems[0];
      if (
        purchase.purchaseState !== "PURCHASED" ||
        !purchase.obfuscatedExternalAccountId ||
        purchase.lineItems.length !== 1 ||
        lineItem.productId !== notice.sku ||
        lineItem.quantity !== 1
      ) {
        throw new HttpError(503, "reconciliation_retry_required");
      }
      const result = await deps.economy.grantPurchase({
        userId: purchase.obfuscatedExternalAccountId,
        productId: notice.sku,
        purchaseToken: notice.purchaseToken,
        orderId: purchase.orderId ?? null,
        grantAmount: product.grantAmount,
        rawVerification: purchase.raw,
      });
      if (lineItem.consumptionState !== "CONSUMPTION_STATE_CONSUMED") {
        try {
          await deps.google.consume(
            deps.expectedPackage,
            notice.sku,
            notice.purchaseToken,
          );
        } catch {
          throw new HttpError(503, "consume_retry_required");
        }
      }
      return json(200, { accepted: true, duplicate: result.duplicate });
    }
    if (notice.notificationType === 2) {
      return json(200, { ignored: true, reason: "pending_cancelled" });
    }
    return json(200, { ignored: true, reason: "unknown_one_time_type" });
  });
}

if (import.meta.main) {
  const { createBackend } = await import("../_shared/backend.ts");
  const backend = await createBackend(Deno.env.get("SUPABASE_DB_URL")!);
  const google = createGooglePlayClient(
    Deno.env.get("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON")!,
  );
  const audience = Deno.env.get("PUBSUB_AUDIENCE")!;
  const email = Deno.env.get("PUBSUB_SERVICE_ACCOUNT_EMAIL")!;
  Deno.serve((request) =>
    handler(request, {
      expectedPackage: Deno.env.get("ANDROID_PACKAGE_NAME")!,
      catalog: backend.catalog,
      google,
      pubsub: {
        async authenticate(req) {
          const token = req.headers.get("authorization")?.replace(
            /^Bearer /,
            "",
          );
          if (!token) return false;
          const response = await fetch(
            `https://oauth2.googleapis.com/tokeninfo?id_token=${
              encodeURIComponent(token)
            }`,
          );
          if (!response.ok) return false;
          const claims = await response.json();
          return claims.aud === audience && claims.email === email &&
            claims.email_verified === "true";
        },
      },
      economy: backend.economy,
    })
  );
}
