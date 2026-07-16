// deno-lint-ignore-file require-await
import { handler as verifyPurchase } from "../verify-google-play-purchase/index.ts";
import { handler as notification } from "../google-play-notification/index.ts";
import { handler as spend } from "../spend-royal-jade/index.ts";
import { handler as deleteAccount } from "../delete-account/index.ts";
import { parseGooglePurchase } from "../_shared/google_play_client.ts";

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
        lineItems: [{
          productId,
          quantity: 1,
          consumptionState: "CONSUMPTION_STATE_YET_TO_BE_CONSUMED",
        }],
        obfuscatedExternalAccountId: "user-1",
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

function notificationDeps(overrides: Record<string, unknown> = {}) {
  const base = {
    expectedPackage: "com.example.game",
    pubsub: { authenticate: async () => true },
    catalog: {
      findProduct: async (id: string) =>
        id === "royal_jade_small" ? { grantAmount: 100, active: true } : null,
    },
    google: {
      getProductPurchase: async () => ({
        purchaseState: "PURCHASED",
        lineItems: [{
          productId: "royal_jade_small",
          quantity: 1,
          consumptionState: "CONSUMPTION_STATE_YET_TO_BE_CONSUMED",
        }],
        obfuscatedExternalAccountId: "user-1",
        raw: {},
      }),
      consume: async () => {},
    },
    economy: {
      refund: async () => ({ balance: 0, debt: 0 }),
      grantPurchase: async () => ({
        balance: 100,
        debt: 0,
        duplicate: false,
      }),
    },
  };
  return {
    ...base,
    ...overrides,
    pubsub: { ...base.pubsub, ...overrides.pubsub as object },
    catalog: { ...base.catalog, ...overrides.catalog as object },
    google: { ...base.google, ...overrides.google as object },
    economy: { ...base.economy, ...overrides.economy as object },
  };
}

Deno.test("ProductPurchaseV2 parser keeps account and line item quantity", () => {
  equal(
    parseGooglePurchase({
      purchaseStateContext: { purchaseState: "PURCHASED" },
      obfuscatedExternalAccountId: "user-1",
      productLineItem: [{
        productId: "royal_jade_small",
        productOfferDetails: {
          quantity: 1,
          consumptionState: "CONSUMPTION_STATE_YET_TO_BE_CONSUMED",
        },
      }],
      orderId: "order-1",
    }),
    {
      purchaseState: "PURCHASED",
      lineItems: [{
        productId: "royal_jade_small",
        quantity: 1,
        consumptionState: "CONSUMPTION_STATE_YET_TO_BE_CONSUMED",
      }],
      obfuscatedExternalAccountId: "user-1",
      orderId: "order-1",
      raw: {
        purchaseStateContext: { purchaseState: "PURCHASED" },
        obfuscatedExternalAccountId: "user-1",
        productLineItem: [{
          productId: "royal_jade_small",
          productOfferDetails: {
            quantity: 1,
            consumptionState: "CONSUMPTION_STATE_YET_TO_BE_CONSUMED",
          },
        }],
        orderId: "order-1",
      },
    },
  );
});

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

Deno.test("purchase without obfuscated account id is rejected", async () => {
  const deps = verifyDeps({
    google: {
      getProductPurchase: async () => ({
        purchaseState: "PURCHASED",
        productIds: ["royal_jade_small"],
        lineItems: [{
          productId: "royal_jade_small",
          quantity: 1,
          consumptionState: "CONSUMPTION_STATE_YET_TO_BE_CONSUMED",
        }],
        raw: {},
      }),
      consume: async () => {},
    },
  });
  const response = await verifyPurchase(
    request({
      productId: "royal_jade_small",
      purchaseToken: "token-no-account",
      packageName: "com.example.game",
    }),
    deps,
  );
  equal(response.status, 422);
  equal((await body(response)).code, "account_mismatch");
  equal(deps.ledgerEntries.length, 0);
});

Deno.test("purchase for another obfuscated account is rejected", async () => {
  const deps = verifyDeps({
    google: {
      getProductPurchase: async () => ({
        purchaseState: "PURCHASED",
        productIds: ["royal_jade_small"],
        lineItems: [{
          productId: "royal_jade_small",
          quantity: 1,
          consumptionState: "CONSUMPTION_STATE_YET_TO_BE_CONSUMED",
        }],
        obfuscatedExternalAccountId: "user-2",
        raw: {},
      }),
      consume: async () => {},
    },
  });
  const response = await verifyPurchase(
    request({
      productId: "royal_jade_small",
      purchaseToken: "token-wrong-account",
      packageName: "com.example.game",
    }),
    deps,
  );
  equal(response.status, 422);
  equal((await body(response)).code, "account_mismatch");
  equal(deps.ledgerEntries.length, 0);
});

Deno.test("multi-quantity purchase is rejected", async () => {
  const deps = verifyDeps({
    google: {
      getProductPurchase: async () => ({
        purchaseState: "PURCHASED",
        productIds: ["royal_jade_small"],
        lineItems: [{
          productId: "royal_jade_small",
          quantity: 2,
          consumptionState: "CONSUMPTION_STATE_YET_TO_BE_CONSUMED",
        }],
        obfuscatedExternalAccountId: "user-1",
        raw: {},
      }),
      consume: async () => {},
    },
  });
  const response = await verifyPurchase(
    request({
      productId: "royal_jade_small",
      purchaseToken: "token-quantity",
      packageName: "com.example.game",
    }),
    deps,
  );
  equal(response.status, 422);
  equal((await body(response)).code, "product_mismatch");
  equal(deps.ledgerEntries.length, 0);
});

Deno.test("multiple Google line items are rejected", async () => {
  const deps = verifyDeps({
    google: {
      getProductPurchase: async () => ({
        purchaseState: "PURCHASED",
        productIds: ["royal_jade_small", "royal_jade_medium"],
        lineItems: [
          {
            productId: "royal_jade_small",
            quantity: 1,
            consumptionState: "CONSUMPTION_STATE_YET_TO_BE_CONSUMED",
          },
          {
            productId: "royal_jade_medium",
            quantity: 1,
            consumptionState: "CONSUMPTION_STATE_YET_TO_BE_CONSUMED",
          },
        ],
        obfuscatedExternalAccountId: "user-1",
        raw: {},
      }),
      consume: async () => {},
    },
  });
  const response = await verifyPurchase(
    request({
      productId: "royal_jade_small",
      purchaseToken: "token-multiple",
      packageName: "com.example.game",
    }),
    deps,
  );
  equal(response.status, 422);
  equal((await body(response)).code, "product_mismatch");
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
  equal(result, { accepted: true, duplicate: false });
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
  equal(firstBody, { accepted: true, duplicate: false });
  equal(secondBody, { accepted: true, duplicate: true });
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
  equal(first.status, 503);
  equal(await body(first), { code: "consume_retry_required" });
  equal(second.status, 200);
  equal(await body(second), { accepted: true, duplicate: true });
  equal(deps.ledgerEntries.length, 1);
});

Deno.test("already consumed purchase is accepted without consuming again", async () => {
  let consumeCalls = 0;
  const deps = verifyDeps({
    google: {
      getProductPurchase: async () => ({
        purchaseState: "PURCHASED",
        lineItems: [{
          productId: "royal_jade_small",
          quantity: 1,
          consumptionState: "CONSUMPTION_STATE_CONSUMED",
        }],
        obfuscatedExternalAccountId: "user-1",
        raw: {},
      }),
      consume: async () => {
        consumeCalls++;
      },
    },
  });
  const response = await verifyPurchase(
    request({
      productId: "royal_jade_small",
      purchaseToken: "consumed-token",
      packageName: "com.example.game",
    }),
    deps,
  );
  equal(response.status, 200);
  equal(await body(response), { accepted: true, duplicate: false });
  equal(consumeCalls, 0);
});

Deno.test("response loss retry grants once and does not consume twice", async () => {
  let lookupCalls = 0;
  let consumeCalls = 0;
  const deps = verifyDeps({
    google: {
      getProductPurchase: async () => ({
        purchaseState: "PURCHASED",
        lineItems: [{
          productId: "royal_jade_small",
          quantity: 1,
          consumptionState: lookupCalls++ === 0
            ? "CONSUMPTION_STATE_YET_TO_BE_CONSUMED"
            : "CONSUMPTION_STATE_CONSUMED",
        }],
        obfuscatedExternalAccountId: "user-1",
        raw: {},
      }),
      consume: async () => {
        consumeCalls++;
      },
    },
  });
  const payload = {
    productId: "royal_jade_small",
    purchaseToken: "response-loss-token",
    packageName: "com.example.game",
  };
  const first = await verifyPurchase(request(payload), deps);
  const retry = await verifyPurchase(request(payload), deps);
  equal(await body(first), { accepted: true, duplicate: false });
  equal(await body(retry), { accepted: true, duplicate: true });
  equal(deps.ledgerEntries.length, 1);
  equal(consumeCalls, 1);
});

Deno.test("PubSub authentication failure is rejected", async () => {
  const response = await notification(
    request({ message: { data: "e30=" } }, "bad"),
    notificationDeps({ pubsub: { authenticate: async () => false } }),
  );
  equal(response.status, 401);
});

Deno.test("one-time pending cancellation is ignored without refund", async () => {
  let calls = 0;
  const event = btoa(JSON.stringify({
    packageName: "com.example.game",
    oneTimeProductNotification: {
      purchaseToken: "token-pending",
      notificationType: 2,
    },
  }));
  const response = await notification(
    request({ message: { messageId: "event-pending", data: event } }, "pubsub"),
    notificationDeps({
      economy: {
        refund: async () => {
          calls++;
          return { balance: 0, debt: 0 };
        },
      },
    }),
  );
  equal(response.status, 200);
  equal(await body(response), { ignored: true, reason: "pending_cancelled" });
  equal(calls, 0);
});

Deno.test("one-time purchased notification verifies, grants, and consumes", async () => {
  const calls: string[] = [];
  const event = btoa(JSON.stringify({
    packageName: "com.example.game",
    oneTimeProductNotification: {
      purchaseToken: "token-purchased",
      notificationType: 1,
      sku: "royal_jade_small",
    },
  }));
  const response = await notification(
    request(
      { message: { messageId: "event-purchased", data: event } },
      "pubsub",
    ),
    notificationDeps({
      google: {
        getProductPurchase: async () => {
          calls.push("google.get");
          return {
            purchaseState: "PURCHASED",
            lineItems: [{
              productId: "royal_jade_small",
              quantity: 1,
              consumptionState: "CONSUMPTION_STATE_YET_TO_BE_CONSUMED",
            }],
            obfuscatedExternalAccountId: "user-1",
            raw: {},
          };
        },
        consume: async () => {
          calls.push("google.consume");
        },
      },
      economy: {
        grantPurchase: async () => {
          calls.push("economy.grant");
          return { balance: 100, debt: 0, duplicate: false };
        },
      },
    }),
  );
  equal(response.status, 200);
  equal(await body(response), { accepted: true, duplicate: false });
  equal(calls, ["google.get", "economy.grant", "google.consume"]);
});

Deno.test("notification package mismatch is rejected", async () => {
  const event = btoa(JSON.stringify({
    packageName: "evil.pkg",
    voidedPurchaseNotification: {
      purchaseToken: "token-1",
      productType: 2,
      refundType: 1,
    },
  }));
  const response = await notification(
    request({ message: { messageId: "event-package", data: event } }, "pubsub"),
    notificationDeps(),
  );
  equal(response.status, 400);
  equal((await body(response)).code, "package_mismatch");
});

Deno.test("voided one-time purchase creates debt when funds were spent", async () => {
  let input: unknown;
  const event = btoa(
    JSON.stringify({
      packageName: "com.example.game",
      voidedPurchaseNotification: {
        purchaseToken: "token-1",
        productType: 2,
        refundType: 1,
      },
    }),
  );
  const response = await notification(
    request({ message: { messageId: "event-1", data: event } }, "pubsub"),
    notificationDeps({
      economy: {
        refund: async (value: unknown) => {
          input = value;
          return { balance: 0, debt: 75 };
        },
      },
    }),
  );
  equal(response.status, 200);
  equal((await body(response)).debt, 75);
  equal(input, {
    purchaseToken: "token-1",
    eventId: "event-1",
    refundType: 1,
  });
});

Deno.test("unknown voided token is retried until the purchase is known", async () => {
  let refundCalls = 0;
  const event = btoa(JSON.stringify({
    packageName: "com.example.game",
    voidedPurchaseNotification: {
      purchaseToken: "unknown-token",
      productType: 2,
      refundType: 1,
    },
  }));
  const deps = notificationDeps({
    economy: {
      refund: async () =>
        refundCalls++ === 0
          ? { ignored: true, reason: "unknown_token" }
          : { balance: 0, debt: 100 },
    },
  });
  const first = await notification(
    request({ message: { messageId: "event-unknown", data: event } }, "pubsub"),
    deps,
  );
  const retry = await notification(
    request({ message: { messageId: "event-unknown", data: event } }, "pubsub"),
    deps,
  );
  equal(first.status, 503);
  equal(await body(first), { code: "purchase_not_found_retry" });
  equal(retry.status, 200);
  equal(await body(retry), { balance: 0, debt: 100 });
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
