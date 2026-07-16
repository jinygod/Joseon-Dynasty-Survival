import {
  type AuthAdapter,
  createSupabaseAuth,
  requirePermanentUser,
} from "../_shared/auth.ts";
import { boundedJson, HttpError, json, respond } from "../_shared/http.ts";
import { isValidProgress } from "../_shared/progress_contract.ts";

interface SyncProgressInput {
  userId: string;
  schemaVersion: number;
  progress: Record<string, unknown>;
  expectedRevision: number | null;
}

interface SyncProgressResult {
  revision: number;
  progress: Record<string, unknown>;
  applied: boolean;
}

interface SyncProgressDeps {
  auth: AuthAdapter;
  progress: {
    sync(input: SyncProgressInput): Promise<SyncProgressResult | null>;
  };
}

const maxProgressBytes = 65_536;
const maxRequestBytes = 70_000;

function isObject(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function containsPaidField(value: unknown): boolean {
  if (Array.isArray(value)) return value.some(containsPaidField);
  if (!isObject(value)) return false;
  return Object.entries(value).some(([key, child]) =>
    key === "royal_jade" || containsPaidField(child)
  );
}

export async function handler(
  request: Request,
  deps: SyncProgressDeps,
): Promise<Response> {
  return await respond(async () => {
    if (request.method !== "POST") {
      return json(405, { code: "method_not_allowed" });
    }
    const user = await requirePermanentUser(request, deps.auth);
    const body = await boundedJson(request, maxRequestBytes);
    if (!isObject(body)) throw new HttpError(400, "invalid_body");
    const keys = Object.keys(body);
    const schemaVersion = body.schemaVersion;
    const progress = body.progress;
    const expectedRevision = body.expectedRevision;
    if (
      keys.length !== 3 ||
      !keys.includes("schemaVersion") ||
      !keys.includes("progress") ||
      !keys.includes("expectedRevision") ||
      !Number.isSafeInteger(schemaVersion) ||
      (schemaVersion as number) <= 0 ||
      !isObject(progress) ||
      !(expectedRevision === null ||
        (Number.isSafeInteger(expectedRevision) &&
          (expectedRevision as number) >= 0))
    ) {
      throw new HttpError(400, "invalid_body");
    }
    if (containsPaidField(progress)) {
      throw new HttpError(400, "paid_progress_forbidden");
    }
    const progressBytes = new TextEncoder().encode(JSON.stringify(progress))
      .byteLength;
    if (progressBytes > maxProgressBytes) {
      throw new HttpError(413, "progress_too_large");
    }
    if (!isValidProgress(schemaVersion as number, progress)) {
      throw new HttpError(400, "invalid_progress");
    }
    const result = await deps.progress.sync({
      userId: user.id,
      schemaVersion: schemaVersion as number,
      progress,
      expectedRevision: expectedRevision as number | null,
    });
    if (result == null) {
      throw new HttpError(409, "progress_revision_mismatch");
    }
    return json(200, {
      revision: result.revision,
      progress: result.progress,
      conflict: !result.applied,
    });
  });
}

if (import.meta.main) {
  const { createBackend } = await import("../_shared/backend.ts");
  const backend = await createBackend(Deno.env.get("SUPABASE_DB_URL")!);
  const auth = createSupabaseAuth(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );
  Deno.serve((request) =>
    handler(request, { auth, progress: backend.progress })
  );
}
