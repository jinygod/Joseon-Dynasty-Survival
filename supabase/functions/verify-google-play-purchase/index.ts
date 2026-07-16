import { PurchaseRequest } from "../_shared/contracts.ts";
import {
  type AuthAdapter,
  createSupabaseAuth,
  requirePermanentUser,
} from "../_shared/auth.ts";
import { boundedJson, HttpError, json, respond } from "../_shared/http.ts";
import {
  createGooglePlayClient,
  type GooglePlayClient,
} from "../_shared/google_play_client.ts";

export interface VerifyDeps {
  expectedPackage: string;
  auth: AuthAdapter;
  catalog: {
    findProduct(
      id: string,
    ): Promise<{ grantAmount: number; active: boolean } | null>;
  };
  google: GooglePlayClient;
  economy: {
    grantPurchase(
      input: Record<string, unknown>,
    ): Promise<{ balance: number; debt: number; duplicate: boolean }>;
  };
}

export async function handler(
  request: Request,
  deps: VerifyDeps,
): Promise<Response> {
  return await respond(async () => {
    if (request.method !== "POST") {
      return json(405, { code: "method_not_allowed" });
    }
    const user = await requirePermanentUser(request, deps.auth);
    let parsed: unknown;
    try {
      parsed = await boundedJson(request, 16_384);
    } catch (error) {
      throw error;
    }
    let body;
    try {
      body = PurchaseRequest.parse(parsed);
    } catch (error) {
      throw new HttpError(
        400,
        error instanceof Error && error.message === "unknown_product"
          ? "unknown_product"
          : "invalid_body",
      );
    }
    if (body.packageName !== deps.expectedPackage) {
      throw new HttpError(400, "package_mismatch");
    }
    const product = await deps.catalog.findProduct(body.productId);
    if (!product?.active) throw new HttpError(400, "unknown_product");
    const purchase = await deps.google.getProductPurchase(
      body.packageName,
      body.productId,
      body.purchaseToken,
    );
    if (purchase.purchaseState === "PENDING") {
      return json(202, { accepted: false, code: "purchase_pending" });
    }
    if (purchase.purchaseState !== "PURCHASED") {
      throw new HttpError(422, "purchase_invalid");
    }
    if (purchase.obfuscatedExternalAccountId !== user.id) {
      throw new HttpError(422, "account_mismatch");
    }
    if (
      purchase.lineItems.length !== 1 ||
      purchase.lineItems[0].productId !== body.productId ||
      purchase.lineItems[0].quantity !== 1
    ) {
      throw new HttpError(422, "product_mismatch");
    }
    const result = await deps.economy.grantPurchase({
      userId: user.id,
      productId: body.productId,
      purchaseToken: body.purchaseToken,
      orderId: purchase.orderId ?? null,
      grantAmount: product.grantAmount,
      rawVerification: purchase.raw,
    });
    if (
      purchase.lineItems[0].consumptionState !== "CONSUMPTION_STATE_CONSUMED"
    ) {
      try {
        await deps.google.consume(
          body.packageName,
          body.productId,
          body.purchaseToken,
        );
      } catch {
        throw new HttpError(503, "consume_retry_required");
      }
    }
    return json(200, { accepted: true, duplicate: result.duplicate });
  });
}

if (import.meta.main) {
  const { createBackend } = await import("../_shared/backend.ts");
  const backend = await createBackend(Deno.env.get("SUPABASE_DB_URL")!);
  const deps: VerifyDeps = {
    expectedPackage: Deno.env.get("ANDROID_PACKAGE_NAME")!,
    auth: createSupabaseAuth(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    ),
    google: createGooglePlayClient(
      Deno.env.get("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON")!,
    ),
    catalog: backend.catalog,
    economy: backend.economy,
  };
  Deno.serve((request) => handler(request, deps));
}
