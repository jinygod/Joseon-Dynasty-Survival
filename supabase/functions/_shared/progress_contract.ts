const currentSchemaVersion = 3;
const maxCounter = 1_000_000_000;
const maxRank = 100;
const maxClaimedRewardIds = 10_000;
const maxDynamicIdLength = 128;
const dynamicIdPattern = /^[A-Za-z0-9._:-]+$/;

const characterIds = new Set([
  "rookie_constable",
  "exorcist_dosa",
  "mountain_hunter",
]);
const weaponIds = new Set([
  "hwando_slash",
  "gakgung_shot",
  "talisman_throw",
  "thunder_crash_bomb",
  "jangseung_ward",
  "singijeon_volley",
  "frost_flask",
  "wind_thunder_fan",
]);
const augmentIds = new Set([
  "martial_training",
  "quick_step",
  "inner_breath",
  "jangseung_blessing",
  "hawk_eye",
  "herbal_tonic",
  "rapid_reload",
  "goblin_fire",
  "powder_mastery",
  "last_stand",
  "ritual_shortcut",
  "heavy_strike",
  "iron_armor_training",
  "scholar_insight",
  "blood_oath",
  "ghost_step",
]);
const stageIds = new Set([
  "moonlit_abandoned_office",
  "plague_market",
]);
const goalIds = new Set([
  "survive_3_minutes",
  "defeat_300_enemies",
  "reach_level_10",
  "defeat_fallen_general",
  "survive_5_minutes",
  "unlock_three_weapons",
  "defeat_500_enemies",
  "low_health_win",
  "defeat_two_bosses",
  "unlock_six_weapons",
  "reach_level_5",
  "defeat_50_elites",
  "reach_level_15",
  "defeat_three_bosses",
  "win_first_run",
]);
const commonTrainingNodeIds = new Set([
  "common.max_health",
  "common.base_damage",
  "common.pickup_range",
  "common.move_speed",
]);
const characterTrainingNodeIds = new Set([
  "max_health",
  "base_damage",
  "move_speed",
  "pickup_range",
  "cooldown",
  "survival",
]);
const coreTraitIdsByCharacter: Record<string, Set<string>> = {
  rookie_constable: new Set([
    "constable.stalwart",
    "constable.counter_stance",
  ]),
  exorcist_dosa: new Set(["dosa.talisman_mastery", "dosa.spirit_burn"]),
  mountain_hunter: new Set(["hunter.hawk_eye", "hunter.trapcraft"]),
};
const shopItemIds = new Set([
  "manual.rookie_constable",
  "manual.exorcist_dosa",
  "manual.mountain_hunter",
]);
const compendiumIds = new Set([
  ...[...characterIds].map((id) => `character:${id}`),
  ...[...weaponIds].map((id) => `weapon:${id}`),
  ...[...augmentIds].map((id) => `augment:${id}`),
]);

const progressKeys = new Set([
  "schemaVersion",
  "unlockedCharacterIds",
  "unlockedWeaponIds",
  "unlockedAugmentIds",
  "unlockedStageIds",
  "completedGoalIds",
  "claimedRewardIds",
  "wallet",
  "trainingProgress",
  "shopProgress",
  "selectedCharacterId",
  "selectedStageId",
  "totalKills",
  "bestSurvivalSeconds",
  "levelReachedInRun",
  "bossDefeats",
  "unlockedWeaponCount",
  "lowHealthWinCount",
  "totalEliteKills",
  "victoryCount",
  "characterVictoryCounts",
  "seenCompendiumEntryIds",
]);

function isObject(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function hasExactKeys(value: Record<string, unknown>, expected: Set<string>) {
  const keys = Object.keys(value);
  return keys.length === expected.size &&
    keys.every((key) => expected.has(key));
}

function isBoundedInt(value: unknown, maximum: number) {
  return Number.isSafeInteger(value) && (value as number) >= 0 &&
    (value as number) <= maximum;
}

function isKnownIdList(value: unknown, known: Set<string>) {
  if (!Array.isArray(value) || value.length > known.size) return false;
  const ids = new Set<string>();
  for (const id of value) {
    if (typeof id !== "string" || !known.has(id) || ids.has(id)) return false;
    ids.add(id);
  }
  return true;
}

function isRankMap(value: unknown, allowedIds: Set<string>) {
  return isObject(value) &&
    Object.entries(value).every(([id, rank]) =>
      allowedIds.has(id) && isBoundedInt(rank, maxRank)
    );
}

function isTrainingProgress(value: unknown) {
  if (
    !isObject(value) ||
    !hasExactKeys(
      value,
      new Set(["commonRanks", "characterRanks", "activeCoreTraitIds"]),
    ) ||
    !isRankMap(value.commonRanks, commonTrainingNodeIds) ||
    !isObject(value.characterRanks) ||
    !Object.entries(value.characterRanks).every(([characterId, ranks]) =>
      Object.hasOwn(coreTraitIdsByCharacter, characterId) &&
      isRankMap(ranks, characterTrainingNodeIds)
    ) ||
    !isObject(value.activeCoreTraitIds)
  ) return false;
  return Object.entries(value.activeCoreTraitIds).every(
    ([characterId, traitId]) =>
      typeof traitId === "string" &&
      Object.hasOwn(coreTraitIdsByCharacter, characterId) &&
      coreTraitIdsByCharacter[characterId]?.has(traitId) === true,
  );
}

function isClaimedRewardIds(value: unknown) {
  if (!Array.isArray(value) || value.length > maxClaimedRewardIds) return false;
  const ids = new Set<string>();
  for (const id of value) {
    if (
      typeof id !== "string" || id.length === 0 ||
      id.length > maxDynamicIdLength || !dynamicIdPattern.test(id) ||
      ids.has(id)
    ) return false;
    ids.add(id);
  }
  return true;
}

function isCharacterVictoryCounts(value: unknown) {
  return isObject(value) &&
    Object.entries(value).every(([id, count]) =>
      characterIds.has(id) && isBoundedInt(count, maxCounter)
    );
}

export function isValidProgress(
  schemaVersion: number,
  progress: Record<string, unknown>,
) {
  if (
    schemaVersion !== currentSchemaVersion ||
    progress.schemaVersion !== currentSchemaVersion ||
    !hasExactKeys(progress, progressKeys) ||
    !isKnownIdList(progress.unlockedCharacterIds, characterIds) ||
    !isKnownIdList(progress.unlockedWeaponIds, weaponIds) ||
    !isKnownIdList(progress.unlockedAugmentIds, augmentIds) ||
    !isKnownIdList(progress.unlockedStageIds, stageIds) ||
    !isKnownIdList(progress.completedGoalIds, goalIds) ||
    !isClaimedRewardIds(progress.claimedRewardIds) ||
    !isObject(progress.wallet) ||
    !hasExactKeys(progress.wallet, new Set(["coin", "spiritJade"])) ||
    !isBoundedInt(progress.wallet.coin, maxCounter) ||
    !isBoundedInt(progress.wallet.spiritJade, maxCounter) ||
    !isTrainingProgress(progress.trainingProgress) ||
    !isObject(progress.shopProgress) ||
    !hasExactKeys(progress.shopProgress, new Set(["purchasedItemIds"])) ||
    !isKnownIdList(progress.shopProgress.purchasedItemIds, shopItemIds) ||
    typeof progress.selectedCharacterId !== "string" ||
    !characterIds.has(progress.selectedCharacterId) ||
    typeof progress.selectedStageId !== "string" ||
    !stageIds.has(progress.selectedStageId) ||
    !isCharacterVictoryCounts(progress.characterVictoryCounts) ||
    !isKnownIdList(progress.seenCompendiumEntryIds, compendiumIds)
  ) return false;
  return [
    "totalKills",
    "bestSurvivalSeconds",
    "levelReachedInRun",
    "bossDefeats",
    "unlockedWeaponCount",
    "lowHealthWinCount",
    "totalEliteKills",
    "victoryCount",
  ].every((key) => isBoundedInt(progress[key], maxCounter));
}
