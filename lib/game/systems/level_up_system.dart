import '../content/augment_definitions.dart' as augment_content;
import '../content/ids.dart';
import '../content/weapon_definitions.dart' as weapon_content;

enum LevelUpChoiceType { weapon, augment }

class LevelUpChoice {
  const LevelUpChoice({
    required this.id,
    required this.displayName,
    required this.type,
    required this.currentLevel,
    required this.nextLevel,
  });

  final String id;
  final String displayName;
  final LevelUpChoiceType type;
  final int currentLevel;
  final int nextLevel;

  @override
  bool operator ==(Object other) {
    return other is LevelUpChoice &&
        other.id == id &&
        other.displayName == displayName &&
        other.type == type &&
        other.currentLevel == currentLevel &&
        other.nextLevel == nextLevel;
  }

  @override
  int get hashCode =>
      Object.hash(id, displayName, type, currentLevel, nextLevel);
}

class LevelUpSystem {
  const LevelUpSystem({
    this.weaponDefinitions = weapon_content.weaponDefinitions,
    this.augmentDefinitions = augment_content.augmentDefinitions,
  });

  final List<WeaponDefinition> weaponDefinitions;
  final List<AugmentDefinition> augmentDefinitions;

  List<LevelUpChoice> choices({
    required Set<WeaponId> unlockedWeaponIds,
    required Set<AugmentId> unlockedAugmentIds,
    required Map<WeaponId, int> currentWeaponLevels,
    required Map<AugmentId, int> currentAugmentLevels,
    int maxChoices = 3,
  }) {
    final allChoices = <LevelUpChoice?>[
      for (final definition in weaponDefinitions)
        if (unlockedWeaponIds.contains(definition.id))
          _weaponChoice(definition, currentWeaponLevels),
      for (final definition in augmentDefinitions)
        if (unlockedAugmentIds.contains(definition.id))
          _augmentChoice(definition, currentAugmentLevels),
    ].whereType<LevelUpChoice>().toList(growable: false);

    return allChoices.take(maxChoices).toList(growable: false);
  }

  LevelUpChoice? _weaponChoice(
    WeaponDefinition definition,
    Map<WeaponId, int> currentLevels,
  ) {
    final currentLevel = currentLevels[definition.id] ?? 0;
    if (currentLevel >= definition.maxLevel) {
      return null;
    }

    return LevelUpChoice(
      id: definition.id,
      displayName: definition.name,
      type: LevelUpChoiceType.weapon,
      currentLevel: currentLevel,
      nextLevel: currentLevel + 1,
    );
  }

  LevelUpChoice? _augmentChoice(
    AugmentDefinition definition,
    Map<AugmentId, int> currentLevels,
  ) {
    final currentLevel = currentLevels[definition.id] ?? 0;
    if (currentLevel >= definition.maxLevel) {
      return null;
    }

    return LevelUpChoice(
      id: definition.id,
      displayName: definition.name,
      type: LevelUpChoiceType.augment,
      currentLevel: currentLevel,
      nextLevel: currentLevel + 1,
    );
  }
}
