typedef CharacterId = String;
typedef WeaponId = String;
typedef AugmentId = String;
typedef EnemyId = String;
typedef UnlockGoalId = String;

enum ElementType { physical, magic, fire, ice, lightning }

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
  });

  final CharacterId id;
  final String name;
  final double maxHealth;
  final double moveSpeed;
  final double damageMultiplier;
  final WeaponId startingWeaponId;
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

class AugmentDefinition {
  const AugmentDefinition({
    required this.id,
    required this.name,
    required this.maxLevel,
    required this.startsUnlocked,
  });

  final AugmentId id;
  final String name;
  final int maxLevel;
  final bool startsUnlocked;
}

class EnemyDefinition {
  const EnemyDefinition({
    required this.id,
    required this.name,
    required this.maxHealth,
    required this.moveSpeed,
    required this.damage,
    required this.experience,
    this.isBoss = false,
  });

  final EnemyId id;
  final String name;
  final double maxHealth;
  final double moveSpeed;
  final double damage;
  final int experience;
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
