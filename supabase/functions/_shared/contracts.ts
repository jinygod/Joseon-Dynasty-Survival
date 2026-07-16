export const PRODUCT_GRANTS = {
  royal_jade_small: 100,
  royal_jade_medium: 550,
  royal_jade_large: 1200,
} as const;

export type ProductId = keyof typeof PRODUCT_GRANTS;

export interface PurchaseRequest {
  productId: ProductId;
  purchaseToken: string;
  packageName: string;
}

export function parsePurchaseRequest(value: unknown): PurchaseRequest {
  if (!value || typeof value !== "object" || Array.isArray(value)) throw new Error("invalid_body");
  const body = value as Record<string, unknown>;
  const keys = Object.keys(body);
  if (keys.some((key) => !["productId", "purchaseToken", "packageName"].includes(key))) throw new Error("invalid_body");
  if (typeof body.productId !== "string" || !(body.productId in PRODUCT_GRANTS)) throw new Error("unknown_product");
  if (typeof body.purchaseToken !== "string" || body.purchaseToken.length < 1 || body.purchaseToken.length > 4096) throw new Error("invalid_body");
  if (typeof body.packageName !== "string" || body.packageName.length < 1 || body.packageName.length > 255) throw new Error("invalid_body");
  return body as unknown as PurchaseRequest;
}
