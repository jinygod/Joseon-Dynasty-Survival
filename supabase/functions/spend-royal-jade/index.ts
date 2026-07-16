import {
  type AuthAdapter,
  createSupabaseAuth,
  requirePermanentUser,
} from "../_shared/auth.ts";
import { boundedJson, HttpError, json, respond } from "../_shared/http.ts";

interface SpendDeps {
  auth: AuthAdapter;
  economy: { spend(userId: string, sku: string): Promise<unknown> };
}

export async function handler(
  request: Request,
  deps: SpendDeps,
): Promise<Response> {
  return await respond(async () => {
    if (request.method !== "POST") {
      return json(405, { code: "method_not_allowed" });
    }
    const user = await requirePermanentUser(request, deps.auth);
    const body = await boundedJson(request, 4096) as Record<string, unknown>;
    if (
      !body || Object.keys(body).some((key) => key !== "sku") ||
      typeof body.sku !== "string" || body.sku.length > 128
    ) {
      throw new HttpError(400, "invalid_body");
    }
    return json(200, await deps.economy.spend(user.id, body.sku));
  });
}

if (import.meta.main) {
  const { createBackend } = await import("../_shared/backend.ts");
  const backend = await createBackend(Deno.env.get("SUPABASE_DB_URL")!);
  const auth = createSupabaseAuth(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  Deno.serve((request) => handler(request, { auth, economy: backend.economy }));
}
