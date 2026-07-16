import { HttpError } from "./http.ts";

export interface AuthUser {
  id: string;
  isAnonymous: boolean;
  authenticatedAt?: number;
}

export interface AuthAdapter {
  verifyJwt(token: string): Promise<AuthUser>;
  deleteUser?(userId: string): Promise<unknown>;
}

export async function requirePermanentUser(
  request: Request,
  auth: AuthAdapter,
): Promise<AuthUser> {
  const authorization = request.headers.get("authorization");
  if (!authorization?.startsWith("Bearer ") || authorization.length <= 7) {
    throw new HttpError(401, "missing_authorization");
  }
  let user: AuthUser;
  try {
    user = await auth.verifyJwt(authorization.slice(7));
  } catch {
    throw new HttpError(401, "invalid_authorization");
  }
  if (!user?.id) throw new HttpError(401, "invalid_authorization");
  if (user.isAnonymous) throw new HttpError(403, "permanent_user_required");
  return user;
}

export function createSupabaseAuth(url: string, key: string): AuthAdapter {
  const headers = (token: string) => ({
    authorization: `Bearer ${token}`,
    apikey: key,
  });
  return {
    async verifyJwt(token) {
      const response = await fetch(`${url}/auth/v1/user`, {
        headers: headers(token),
      });
      if (!response.ok) throw new Error("invalid token");
      const user = await response.json();
      return {
        id: user.id,
        isAnonymous: user.is_anonymous === true,
        authenticatedAt: user.last_sign_in_at
          ? Date.parse(user.last_sign_in_at)
          : undefined,
      };
    },
    async deleteUser(userId) {
      const response = await fetch(
        `${url}/auth/v1/admin/users/${encodeURIComponent(userId)}`,
        {
          method: "DELETE",
          headers: { authorization: `Bearer ${key}`, apikey: key },
        },
      );
      if (!response.ok) throw new Error("auth deletion failed");
    },
  };
}
