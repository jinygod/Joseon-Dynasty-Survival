export interface GooglePurchase {
  purchaseState: string;
  lineItems: Array<{ productId: string; quantity: number }>;
  obfuscatedExternalAccountId?: string;
  orderId?: string;
  raw: unknown;
}

export interface GooglePlayClient {
  getProductPurchase(
    packageName: string,
    productId: string,
    purchaseToken: string,
  ): Promise<GooglePurchase>;
  consume(
    packageName: string,
    productId: string,
    purchaseToken: string,
  ): Promise<void>;
}

interface ProductPurchaseV2Json {
  purchaseStateContext?: { purchaseState?: string };
  productLineItem?: Array<{
    productId?: string;
    productOfferDetails?: { quantity?: number };
  }>;
  obfuscatedExternalAccountId?: string;
  orderId?: string;
}

export function parseGooglePurchase(
  raw: ProductPurchaseV2Json,
): GooglePurchase {
  return {
    purchaseState: raw.purchaseStateContext?.purchaseState ?? "UNKNOWN",
    lineItems: (raw.productLineItem ?? []).map((item: {
      productId?: string;
      productOfferDetails?: { quantity?: number };
    }) => ({
      productId: item.productId ?? "",
      quantity: item.productOfferDetails?.quantity ?? 1,
    })),
    obfuscatedExternalAccountId: raw.obfuscatedExternalAccountId,
    orderId: raw.orderId,
    raw,
  };
}

interface ServiceAccount {
  client_email: string;
  private_key: string;
  token_uri?: string;
}

function base64Url(value: Uint8Array | string) {
  const bytes = typeof value === "string"
    ? new TextEncoder().encode(value)
    : value;
  let binary = "";
  for (const byte of bytes) binary += String.fromCharCode(byte);
  return btoa(binary).replaceAll("+", "-").replaceAll("/", "_").replaceAll(
    "=",
    "",
  );
}

async function serviceToken(account: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = base64Url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = base64Url(JSON.stringify({
    iss: account.client_email,
    scope: "https://www.googleapis.com/auth/androidpublisher",
    aud: account.token_uri ?? "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));
  const der = Uint8Array.from(
    atob(account.private_key.replace(/-----[^-]+-----|\s/g, "")),
    (c) => c.charCodeAt(0),
  );
  const key = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(`${header}.${claims}`),
  );
  const assertion = `${header}.${claims}.${
    base64Url(new Uint8Array(signature))
  }`;
  const response = await fetch(
    account.token_uri ?? "https://oauth2.googleapis.com/token",
    {
      method: "POST",
      headers: { "content-type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion,
      }),
    },
  );
  if (!response.ok) throw new Error("google authentication failed");
  return (await response.json()).access_token;
}

export function createGooglePlayClient(
  credentialsJson: string,
): GooglePlayClient {
  const account = JSON.parse(credentialsJson) as ServiceAccount;
  const call = async (url: string, init?: RequestInit) => {
    const response = await fetch(url, {
      ...init,
      headers: {
        ...init?.headers,
        authorization: `Bearer ${await serviceToken(account)}`,
      },
    });
    if (!response.ok) throw new Error(`google api ${response.status}`);
    return response;
  };
  return {
    async getProductPurchase(packageName, _productId, purchaseToken) {
      const url =
        `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${
          encodeURIComponent(packageName)
        }/purchases/productsv2/tokens/${encodeURIComponent(purchaseToken)}`;
      const raw = await (await call(url)).json();
      return parseGooglePurchase(raw);
    },
    async consume(packageName, productId, purchaseToken) {
      const url =
        `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${
          encodeURIComponent(packageName)
        }/purchases/products/${encodeURIComponent(productId)}/tokens/${
          encodeURIComponent(purchaseToken)
        }:consume`;
      await call(url, { method: "POST" });
    },
  };
}
