import {
  type AuthAdapter,
  createSupabaseAuth,
  requirePermanentUser,
} from "../_shared/auth.ts";
import { boundedJson, HttpError, json, respond } from "../_shared/http.ts";

interface DeleteDeps {
  auth: AuthAdapter & { deleteUser(userId: string): Promise<unknown> };
  accounts: { pseudonymizeAndDelete(userId: string): Promise<unknown> };
}

export async function handler(
  request: Request,
  deps: DeleteDeps,
): Promise<Response> {
  return await respond(async () => {
    if (request.method !== "POST") {
      return json(405, { code: "method_not_allowed" });
    }
    const user = await requirePermanentUser(request, deps.auth);
    const body = await boundedJson(request, 1024) as Record<string, unknown>;
    if (!body || Object.keys(body).length !== 1 || body.confirm !== "DELETE") {
      throw new HttpError(400, "confirmation_required");
    }
    if (
      !user.authenticatedAt || Date.now() - user.authenticatedAt > 10 * 60_000
    ) throw new HttpError(403, "recent_authentication_required");
    await deps.accounts.pseudonymizeAndDelete(user.id);
    await deps.auth.deleteUser(user.id);
    return json(200, { deleted: true });
  });
}

if (import.meta.main) {
  const { createBackend } = await import("../_shared/backend.ts");
  const backend = await createBackend(Deno.env.get("SUPABASE_DB_URL")!);
  const auth = createSupabaseAuth(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  ) as DeleteDeps["auth"];
  Deno.serve((request) =>
    handler(request, { auth, accounts: backend.accounts })
  );
}
