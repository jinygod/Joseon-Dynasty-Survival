import { boundedJson, HttpError, json, respond } from "../_shared/http.ts";

interface NotificationDeps {
  pubsub: { authenticate(request: Request): Promise<boolean> };
  economy: {
    refund(
      input: {
        purchaseToken: string;
        eventId: string;
        notificationType: number;
      },
    ): Promise<{ balance: number; debt: number }>;
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
      oneTimeProductNotification?: {
        purchaseToken?: string;
        notificationType?: number;
      };
    };
    try {
      event = JSON.parse(atob(envelope.message.data));
    } catch {
      throw new HttpError(400, "invalid_body");
    }
    const notice = event.oneTimeProductNotification;
    if (!notice?.purchaseToken || typeof notice.notificationType !== "number") {
      throw new HttpError(400, "invalid_body");
    }
    if (notice.notificationType !== 2) return json(200, { ignored: true });
    const result = await deps.economy.refund({
      purchaseToken: notice.purchaseToken,
      eventId: envelope.message.messageId,
      notificationType: notice.notificationType,
    });
    return json(200, result);
  });
}

if (import.meta.main) {
  const { createBackend } = await import("../_shared/backend.ts");
  const backend = await createBackend(Deno.env.get("SUPABASE_DB_URL")!);
  const audience = Deno.env.get("PUBSUB_AUDIENCE")!;
  const email = Deno.env.get("PUBSUB_SERVICE_ACCOUNT_EMAIL")!;
  Deno.serve((request) =>
    handler(request, {
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
