// deno-lint-ignore-file require-await
import { handler as verifyPurchase } from "../verify-google-play-purchase/index.ts";
import { handler as notification } from "../google-play-notification/index.ts";
import { handler as spend } from "../spend-royal-jade/index.ts";
import { handler as deleteAccount } from "../delete-account/index.ts";

function equal(actual: unknown, expected: unknown, message = "values differ") {
  if (JSON.stringify(actual) !== JSON.stringify(expected)) {
    throw new Error(
      `${message}: ${JSON.stringify(actual)} !== ${JSON.stringify(expected)}`,
    );
  }
}

async function body(response: Response) {
  return await response.json();
}

function request(payload: unknown, token = "permanent-token", method = "POST") {
  return new Request("http://local.test", {
    method,
    headers: {
      authorization: `Bearer ${token}`,
      "content-type": "application/json",
    },
    body: method === "POST" ? JSON.stringify(payload) : undefined,
  });
}

function verifyDeps(overrides: Record<string, unknown> = {}) {
  const ledgerEntries: string[] = [];
  let balance = 0;
  const tokens = new Map<string, number>();
  let consumeFailures = 0;
  const deps = {
    expectedPackage: "com.example.game",
    auth: {
      verifyJwt: async (token: string) => ({
        id: "user-1",
        isAnonymous: token === "anonymous-token",
      }),
    },
    catalog: {
      findProduct: async (id: string) =>
        id === "royal_jade_small" ? { grantAmount: 100, active: true } : null,
    },
    google: {
      getProductPurchase: async (
        _pkg: string,
        productId: string,
        _token: string,
      ) => ({
        purchaseState: "PURCHASED",
        productIds: [productId],
        orderId: "order-1",
        raw: {},
      }),
      consume: async () => {
        if (consumeFailures++ === 0 && overrides.failConsumeOnce) {
          throw new Error("consume failed");
        }
      },
    },
    economy: {
      grantPurchase: async (
        input: { purchaseToken: string; grantAmount: number },
      ) => {
        const duplicate = tokens.has(input.purchaseToken);
        if (!duplicate) {
          balance += input.grantAmount;
          tokens.set(input.purchaseToken, balance);
          ledgerEntries.push(input.purchaseToken);
        }
        return {
          balance: tokens.get(input.purchaseToken)!,
          debt: 0,
          duplicate,
        };
      },
    },
    ledgerEntries,
    ...overrides,
  };
  return deps;
}

Deno.test("missing JWT is rejected", async () => {
  const response = await verifyPurchase(
    new Request("http://local.test", { method: "POST", body: "{}" }),
    verifyDeps(),
  );
  equal(response.status, 401);
  equal((await body(response)).code, "missing_authorization");
});

Deno.test("anonymous JWT is rejected", async () => {
  const response = await verifyPurchase(
    request({
      productId: "royal_jade_small",
      purchaseToken: "t",
      packageName: "com.example.game",
    }, "anonymous-token"),
    verifyDeps(),
  );
  equal(response.status, 403);
  equal((await body(response)).code, "permanent_user_required");
});

Deno.test("malformed purchase body is rejected", async () => {
  const response = await verifyPurchase(
    request({ productId: "royal_jade_small", amount: 999 }),
    verifyDeps(),
  );
  equal(response.status, 400);
  equal((await body(response)).code, "invalid_body");
});

Deno.test("package mismatch is rejected before Google", async () => {
  const response = await verifyPurchase(
    request({
      productId: "royal_jade_small",
      purchaseToken: "t",
      packageName: "evil.pkg",
    }),
    verifyDeps(),
  );
  equal(response.status, 400);
  equal((await body(response)).code, "package_mismatch");
});

Deno.test("unknown product is rejected", async () => {
  const response = await verifyPurchase(
    request({
      productId: "unknown",
      purchaseToken: "t",
      packageName: "com.example.game",
    }),
    verifyDeps(),
  );
  equal(response.status, 400);
  equal((await body(response)).code, "unknown_product");
});

Deno.test("pending purchase grants nothing", async () => {
  const deps = verifyDeps({
    google: {
      getProductPurchase: async () => ({
        purchaseState: "PENDING",
        productIds: ["royal_jade_small"],
        raw: {},
      }),
      consume: async () => {},
    },
  });
  const response = await verifyPurchase(
    request({
      productId: "royal_jade_small",
      purchaseToken: "t",
      packageName: "com.example.game",
    }),
    deps,
  );
  equal(response.status, 202);
  equal((await body(response)).accepted, false);
  equal(deps.ledgerEntries.length, 0);
});

Deno.test("invalid Google purchase grants nothing", async () => {
  const deps = verifyDeps({
    google: {
      getProductPurchase: async () => ({
        purchaseState: "CANCELLED",
        productIds: ["royal_jade_small"],
        raw: {},
      }),
      consume: async () => {},
    },
  });
  const response = await verifyPurchase(
    request({
      productId: "royal_jade_small",
      purchaseToken: "t",
      packageName: "com.example.game",
    }),
    deps,
  );
  equal(response.status, 422);
  equal(deps.ledgerEntries.length, 0);
});

Deno.test("purchased token grants trusted catalog amount", async () => {
  const deps = verifyDeps();
  const response = await verifyPurchase(
    request({
      productId: "royal_jade_small",
      purchaseToken: "token-1",
      packageName: "com.example.game",
    }),
    deps,
  );
  equal(response.status, 200);
  const result = await body(response);
  equal(result.balance, 100);
  equal(result.accepted, true);
  equal(result.duplicate, false);
  equal(deps.ledgerEntries.length, 1);
});

Deno.test("duplicate verified token returns one grant", async () => {
  const deps = verifyDeps();
  const first = await verifyPurchase(
    request({
      productId: "royal_jade_small",
      purchaseToken: "token-1",
      packageName: "com.example.game",
    }),
    deps,
  );
  const second = await verifyPurchase(
    request({
      productId: "royal_jade_small",
      purchaseToken: "token-1",
      packageName: "com.example.game",
    }),
    deps,
  );
  const firstBody = await body(first);
  const secondBody = await body(second);
  equal(firstBody.balance, 100);
  equal(secondBody.balance, 100);
  equal(firstBody.accepted, true);
  equal(firstBody.duplicate, false);
  equal(secondBody.accepted, true);
  equal(secondBody.duplicate, true);
  equal(deps.ledgerEntries.length, 1);
});

Deno.test("consume failure remains retryable without duplicate grant", async () => {
  const deps = verifyDeps({ failConsumeOnce: true });
  const first = await verifyPurchase(
    request({
      productId: "royal_jade_small",
      purchaseToken: "token-1",
      packageName: "com.example.game",
    }),
    deps,
  );
  const second = await verifyPurchase(
    request({
      productId: "royal_jade_small",
      purchaseToken: "token-1",
      packageName: "com.example.game",
    }),
    deps,
  );
  equal((await body(first)).consumePending, true);
  equal((await body(second)).balance, 100);
  equal(deps.ledgerEntries.length, 1);
});

Deno.test("PubSub authentication failure is rejected", async () => {
  const response = await notification(
    request({ message: { data: "e30=" } }, "bad"),
    {
      pubsub: { authenticate: async () => false },
      economy: { refund: async () => ({ balance: 0, debt: 0 }) },
    },
  );
  equal(response.status, 401);
});

Deno.test("refund notification creates debt when funds were spent", async () => {
  let input: unknown;
  const event = btoa(
    JSON.stringify({
      oneTimeProductNotification: {
        purchaseToken: "token-1",
        notificationType: 2,
      },
    }),
  );
  const response = await notification(
    request({ message: { messageId: "event-1", data: event } }, "pubsub"),
    {
      pubsub: { authenticate: async () => true },
      economy: {
        refund: async (value: unknown) => {
          input = value;
          return { balance: 0, debt: 75 };
        },
      },
    },
  );
  equal(response.status, 200);
  equal((await body(response)).debt, 75);
  equal(input, {
    purchaseToken: "token-1",
    eventId: "event-1",
    notificationType: 2,
  });
});

Deno.test("spend endpoint returns trusted atomic result", async () => {
  const response = await spend(request({ sku: "test_cosmetic" }), {
    auth: { verifyJwt: async () => ({ id: "user-1", isAnonymous: false }) },
    economy: {
      spend: async () => ({
        entitlementKey: "cosmetic.test",
        balance: 25,
        duplicate: false,
      }),
    },
  });
  equal(response.status, 200);
  equal((await body(response)).balance, 25);
});

Deno.test("account deletion pseudonymizes purchase audit before auth deletion", async () => {
  const calls: string[] = [];
  const response = await deleteAccount(request({ confirm: "DELETE" }), {
    auth: {
      verifyJwt: async () => ({
        id: "user-1",
        isAnonymous: false,
        authenticatedAt: Date.now(),
      }),
      deleteUser: async () => calls.push("auth"),
    },
    accounts: { pseudonymizeAndDelete: async () => calls.push("database") },
  });
  equal(response.status, 200);
  equal(calls, ["database", "auth"]);
});
