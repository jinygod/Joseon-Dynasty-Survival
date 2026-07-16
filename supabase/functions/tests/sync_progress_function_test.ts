// deno-lint-ignore-file require-await
import { handler } from "../sync-progress/index.ts";

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

function request(
  payload: unknown,
  token = "permanent-token",
  method = "POST",
) {
  return new Request("http://local.test", {
    method,
    headers: {
      authorization: `Bearer ${token}`,
      "content-type": "application/json",
    },
    body: method === "POST" ? JSON.stringify(payload) : undefined,
  });
}

function deps(
  sync: (input: {
    userId: string;
    schemaVersion: number;
    progress: Record<string, unknown>;
    expectedRevision: number | null;
  }) => Promise<
    | {
      revision: number;
      progress: Record<string, unknown>;
      applied: boolean;
    }
    | null
  > = async (input) => ({
    revision: (input.expectedRevision ?? 0) + 1,
    progress: input.progress,
    applied: true,
  }),
) {
  return {
    auth: {
      verifyJwt: async (token: string) => ({
        id: "user-1",
        isAnonymous: token === "anonymous-token",
      }),
    },
    progress: { sync },
  };
}

const validProgress = {
  schemaVersion: 3,
  unlockedCharacterIds: ["rookie_constable"],
  unlockedWeaponIds: ["hwando_slash"],
  unlockedAugmentIds: ["martial_training"],
  unlockedStageIds: ["moonlit_abandoned_office"],
  completedGoalIds: [],
  claimedRewardIds: [],
  wallet: { coin: 0, spiritJade: 0 },
  trainingProgress: {
    commonRanks: {},
    characterRanks: {},
    activeCoreTraitIds: {},
  },
  shopProgress: { purchasedItemIds: [] },
  selectedCharacterId: "rookie_constable",
  selectedStageId: "moonlit_abandoned_office",
  totalKills: 7,
  bestSurvivalSeconds: 0,
  levelReachedInRun: 0,
  bossDefeats: 0,
  unlockedWeaponCount: 1,
  lowHealthWinCount: 0,
  totalEliteKills: 0,
  victoryCount: 0,
  characterVictoryCounts: {},
  seenCompendiumEntryIds: [],
};

const createBody = {
  schemaVersion: 3,
  progress: validProgress,
  expectedRevision: null,
};

Deno.test("sync progress requires POST and permanent authentication", async () => {
  const method = await handler(request(null, "permanent-token", "GET"), deps());
  equal(method.status, 405);
  equal(await body(method), { code: "method_not_allowed" });

  const missing = await handler(
    new Request("http://local.test", {
      method: "POST",
      body: JSON.stringify(createBody),
    }),
    deps(),
  );
  equal(missing.status, 401);
  equal(await body(missing), { code: "missing_authorization" });

  const anonymous = await handler(
    request(createBody, "anonymous-token"),
    deps(),
  );
  equal(anonymous.status, 403);
  equal(await body(anonymous), { code: "permanent_user_required" });
});

Deno.test("sync progress rejects malformed strict bodies", async () => {
  for (
    const payload of [
      null,
      {},
      { ...createBody, extra: true },
      { ...createBody, schemaVersion: 0 },
      { ...createBody, schemaVersion: 1.5 },
      { ...createBody, progress: [] },
      { ...createBody, expectedRevision: -1 },
      { ...createBody, expectedRevision: 1.5 },
    ]
  ) {
    const response = await handler(request(payload), deps());
    equal(
      response.status,
      400,
      `expected invalid payload: ${JSON.stringify(payload)}`,
    );
    equal(await body(response), { code: "invalid_body" });
  }
});

Deno.test("sync progress rejects paid fields at any depth", async () => {
  const response = await handler(
    request({
      ...createBody,
      progress: { wallet: { royal_jade: 100 } },
    }),
    deps(),
  );
  equal(response.status, 400);
  equal(await body(response), { code: "paid_progress_forbidden" });
});

Deno.test("sync progress rejects unsupported or mismatched save schemas", async () => {
  for (const [schemaVersion, progressVersion] of [[4, 4], [3, 2], [2, 3]]) {
    const response = await handler(
      request({
        ...createBody,
        schemaVersion,
        progress: { ...validProgress, schemaVersion: progressVersion },
      }),
      deps(),
    );
    equal(response.status, 400);
    equal(await body(response), { code: "invalid_progress" });
  }
});

Deno.test("sync progress rejects unknown fields and content IDs", async () => {
  for (
    const progress of [
      { ...validProgress, debugUnlockEverything: true },
      { ...validProgress, unlockedCharacterIds: ["unknown_character"] },
      { ...validProgress, completedGoalIds: ["unknown_goal"] },
      { ...validProgress, selectedStageId: "unknown_stage" },
      {
        ...validProgress,
        trainingProgress: {
          ...validProgress.trainingProgress,
          commonRanks: { "common.unknown": 1 },
        },
      },
      {
        ...validProgress,
        trainingProgress: {
          ...validProgress.trainingProgress,
          characterRanks: { toString: { max_health: 1 } },
        },
      },
      {
        ...validProgress,
        shopProgress: { purchasedItemIds: ["unknown_item"] },
      },
    ]
  ) {
    const response = await handler(
      request({ ...createBody, progress }),
      deps(),
    );
    equal(response.status, 400);
    equal(await body(response), { code: "invalid_progress" });
  }
});

Deno.test("sync progress rejects malformed unlock collections", async () => {
  for (
    const unlockedCharacterIds of [
      "rookie_constable",
      ["rookie_constable", "rookie_constable"],
      [7],
    ]
  ) {
    const response = await handler(
      request({
        ...createBody,
        progress: { ...validProgress, unlockedCharacterIds },
      }),
      deps(),
    );
    equal(response.status, 400);
    equal(await body(response), { code: "invalid_progress" });
  }
});

Deno.test("sync progress rejects negative and unbounded counters", async () => {
  for (
    const progress of [
      { ...validProgress, totalKills: -1 },
      { ...validProgress, totalKills: 1_000_000_001 },
      { ...validProgress, wallet: { coin: -1, spiritJade: 0 } },
      {
        ...validProgress,
        trainingProgress: {
          ...validProgress.trainingProgress,
          commonRanks: { "common.max_health": 101 },
        },
      },
      {
        ...validProgress,
        characterVictoryCounts: { rookie_constable: -1 },
      },
    ]
  ) {
    const response = await handler(
      request({ ...createBody, progress }),
      deps(),
    );
    equal(response.status, 400);
    equal(await body(response), { code: "invalid_progress" });
  }
});

Deno.test("sync progress accepts the complete current SaveState shape", async () => {
  const progress = {
    ...validProgress,
    unlockedCharacterIds: ["rookie_constable", "exorcist_dosa"],
    claimedRewardIds: ["daily:2026-07-17"],
    wallet: { coin: 1_000_000_000, spiritJade: 1 },
    trainingProgress: {
      commonRanks: { "common.max_health": 100 },
      characterRanks: { rookie_constable: { max_health: 100 } },
      activeCoreTraitIds: { rookie_constable: "constable.stalwart" },
    },
    shopProgress: { purchasedItemIds: ["manual.rookie_constable"] },
    characterVictoryCounts: { rookie_constable: 1 },
    seenCompendiumEntryIds: [
      "character:rookie_constable",
      "weapon:hwando_slash",
      "augment:martial_training",
    ],
  };
  const response = await handler(
    request({ ...createBody, progress }),
    deps(async () => ({ revision: 1, progress, applied: true })),
  );
  equal(response.status, 200);
  equal(await body(response), { revision: 1, progress, conflict: false });
});

Deno.test("sync progress rejects progress larger than 64 KiB", async () => {
  const response = await handler(
    request({
      ...createBody,
      progress: { payload: "x".repeat(65_536) },
    }),
    deps(),
  );
  equal(response.status, 413);
  equal(await body(response), { code: "progress_too_large" });
});

Deno.test("create forwards null revision and returns exact success shape", async () => {
  let received: unknown;
  const response = await handler(
    request(createBody),
    deps(async (input) => {
      received = input;
      return { revision: 1, progress: input.progress, applied: true };
    }),
  );
  equal(received, {
    userId: "user-1",
    schemaVersion: 3,
    progress: createBody.progress,
    expectedRevision: null,
  });
  equal(response.status, 200);
  equal(await body(response), {
    revision: 1,
    progress: createBody.progress,
    conflict: false,
  });
});

Deno.test("update success returns the incremented revision", async () => {
  const progress = { ...validProgress, totalKills: 9 };
  const response = await handler(
    request({ schemaVersion: 3, progress, expectedRevision: 4 }),
    deps(async () => ({ revision: 5, progress, applied: true })),
  );
  equal(response.status, 200);
  equal(await body(response), { revision: 5, progress, conflict: false });
});

Deno.test("revision conflict returns the current server snapshot", async () => {
  const current = { ...validProgress, totalKills: 99 };
  const response = await handler(
    request({ ...createBody, expectedRevision: 4 }),
    deps(async () => ({ revision: 8, progress: current, applied: false })),
  );
  equal(response.status, 200);
  equal(await body(response), {
    revision: 8,
    progress: current,
    conflict: true,
  });
});

Deno.test("missing initial row with nonzero revision is deterministic", async () => {
  const response = await handler(
    request({ ...createBody, expectedRevision: 3 }),
    deps(async () => null),
  );
  equal(response.status, 409);
  equal(await body(response), { code: "progress_revision_mismatch" });
});
