typedef CharacterId = String;
typedef WeaponId = String;
typedef AugmentId = String;
typedef EnemyId = String;
typedef EnemyBehaviorProfileId = String;
typedef UnlockGoalId = String;

enum ElementType { physical, magic, fire, ice, lightning }

enum EnemyBehaviorType { chase, swarm, dash, tank }

enum EnemyFaction { plague, bandit, spirit, anomaly }

enum EnemyRank { normal, elite, boss }

enum EnemyBehaviorKind {
  chase,
  swarm,
  dash,
  tank,
  dive,
  thrust,
  deathZone,
  hasteAura,
  doubleDash,
  shockwave,
  scream,
}

enum EnemyBehaviorPhase { tracking, warning, active, recovery, cooldown }

enum CharacterPassive { none, patrolGrit, exorcismScript, hawkEye }

enum AugmentCategory { attack, survival, movementAcquisition, riskReward }

enum AugmentStat {
  weaponDamage,
  fireDamage,
  attackSpeed,
  criticalChance,
  weaponSize,
  moveSpeed,
  incomingContactDamage,
  experienceGain,
  pickupRadius,
  experienceRequirement,
  maxHealth,
  healing,
}

enum AugmentEffectApplication { continuous, onAcquire }

enum AugmentCondition { always, healthAtOrBelow35 }

enum UnlockMetric {
  bestSurvivalSeconds,
  totalKills,
  levelReachedInRun,
  bossDefeats,
  unlockedWeaponCount,
  lowHealthWinCount,
  totalEliteKills,
  victoryCount,
}

enum UnlockRewardType { character, weapon, augment, stage }

class CharacterDefinition {
  const CharacterDefinition({
    required this.id,
    required this.name,
    required this.maxHealth,
    required this.moveSpeed,
    required this.damageMultiplier,
    required this.startingWeaponId,
    this.passive = CharacterPassive.none,
    this.passiveName = '',
    this.passiveDescription = '',
  });

  final CharacterId id;
  final String name;
  final double maxHealth;
  final double moveSpeed;
  final double damageMultiplier;
  final WeaponId startingWeaponId;
  final CharacterPassive passive;
  final String passiveName;
  final String passiveDescription;
}

class WeaponDefinition {
  const WeaponDefinition({
    required this.id,
    required this.name,
    required this.element,
    required this.maxLevel,
    required this.startsUnlocked,
  });

  final WeaponId id;
  final String name;
  final ElementType element;
  final int maxLevel;
  final bool startsUnlocked;
}

class AugmentEffect {
  const AugmentEffect({
    required this.stat,
    required this.valuePerLevel,
    this.application = AugmentEffectApplication.continuous,
    this.condition = AugmentCondition.always,
    this.isPenalty = false,
  });

  final AugmentStat stat;
  final double valuePerLevel;
  final AugmentEffectApplication application;
  final AugmentCondition condition;
  final bool isPenalty;
}

class AugmentDefinition {
  const AugmentDefinition({
    required this.id,
    required this.name,
    required this.maxLevel,
    required this.startsUnlocked,
    required this.category,
    required this.effects,
  });

  final AugmentId id;
  final String name;
  final int maxLevel;
  final bool startsUnlocked;
  final AugmentCategory category;
  final List<AugmentEffect> effects;
}

class EnemyDefinition {
  const EnemyDefinition({
    required this.id,
    required this.name,
    required this.maxHealth,
    required this.moveSpeed,
    required this.damage,
    required this.experience,
    required this.faction,
    required this.rank,
    required this.behaviorProfileId,
    this.behaviorType = EnemyBehaviorType.chase,
  });

  final EnemyId id;
  final String name;
  final double maxHealth;
  final double moveSpeed;
  final double damage;
  final int experience;
  final EnemyFaction faction;
  final EnemyRank rank;
  final EnemyBehaviorProfileId behaviorProfileId;
  final EnemyBehaviorType behaviorType;
  bool get isBoss => rank == EnemyRank.boss;
  bool get isElite => rank == EnemyRank.elite;
}

class UnlockGoalDefinition {
  const UnlockGoalDefinition({
    required this.id,
    required this.description,
    required this.metric,
    required this.threshold,
    this.unlocksCharacterId,
    this.unlocksWeaponId,
    this.unlocksAugmentId,
    this.unlocksStageId,
  }) : assert(
         (unlocksCharacterId != null ? 1 : 0) +
                 (unlocksWeaponId != null ? 1 : 0) +
                 (unlocksAugmentId != null ? 1 : 0) +
                 (unlocksStageId != null ? 1 : 0) ==
             1,
         'Unlock goals require exactly one reward.',
       );

  final UnlockGoalId id;
  final String description;
  final UnlockMetric metric;
  final int threshold;
  final CharacterId? unlocksCharacterId;
  final WeaponId? unlocksWeaponId;
  final AugmentId? unlocksAugmentId;
  final String? unlocksStageId;

  UnlockRewardType get rewardType {
    if (unlocksCharacterId != null) return UnlockRewardType.character;
    if (unlocksWeaponId != null) return UnlockRewardType.weapon;
    if (unlocksAugmentId != null) return UnlockRewardType.augment;
    return UnlockRewardType.stage;
  }

  String get rewardId =>
      unlocksCharacterId ??
      unlocksWeaponId ??
      unlocksAugmentId ??
      unlocksStageId!;
}
