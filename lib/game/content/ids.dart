typedef CharacterId = String;
typedef WeaponId = String;
typedef AugmentId = String;
typedef EnemyId = String;
typedef UnlockGoalId = String;

enum ElementType { physical, magic, fire, ice, lightning }

enum EnemyBehaviorType { chase, swarm, dash, tank }

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
}

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
    this.behaviorType = EnemyBehaviorType.chase,
    this.isBoss = false,
  });

  final EnemyId id;
  final String name;
  final double maxHealth;
  final double moveSpeed;
  final double damage;
  final int experience;
  final EnemyBehaviorType behaviorType;
  final bool isBoss;
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
  });

  final UnlockGoalId id;
  final String description;
  final UnlockMetric metric;
  final int threshold;
  final CharacterId? unlocksCharacterId;
  final WeaponId? unlocksWeaponId;
  final AugmentId? unlocksAugmentId;
}
