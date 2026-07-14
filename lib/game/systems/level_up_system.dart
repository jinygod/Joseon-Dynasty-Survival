import 'dart:math';

import '../content/augment_definitions.dart' as augment_content;
import '../content/ids.dart';
import '../content/weapon_definitions.dart' as weapon_content;
import '../content/weapon_level_definitions.dart';

enum LevelUpChoiceType { weapon, augment }

class LevelUpChoice {
  const LevelUpChoice({
    required this.id,
    required this.displayName,
    required this.effectDescription,
    required this.type,
    required this.currentLevel,
    required this.nextLevel,
  });

  final String id;
  final String displayName;
  final String effectDescription;
  final LevelUpChoiceType type;
  final int currentLevel;
  final int nextLevel;

  @override
  bool operator ==(Object other) {
    return other is LevelUpChoice &&
        other.id == id &&
        other.displayName == displayName &&
        other.effectDescription == effectDescription &&
        other.type == type &&
        other.currentLevel == currentLevel &&
        other.nextLevel == nextLevel;
  }

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    effectDescription,
    type,
    currentLevel,
    nextLevel,
  );
}

class LevelUpSystem {
  LevelUpSystem({
    Random? random,
    this.weaponDefinitions = weapon_content.weaponDefinitions,
    this.augmentDefinitions = augment_content.augmentDefinitions,
  }) : _random = random ?? Random();

  final List<WeaponDefinition> weaponDefinitions;
  final List<AugmentDefinition> augmentDefinitions;
  final Random _random;

  List<LevelUpChoice> choices({
    required Set<WeaponId> unlockedWeaponIds,
    required Set<AugmentId> unlockedAugmentIds,
    required Map<WeaponId, int> currentWeaponLevels,
    required Map<AugmentId, int> currentAugmentLevels,
    int maxChoices = 3,
  }) {
    if (maxChoices <= 0) {
      return const [];
    }

    final weaponChoices = <LevelUpChoice?>[
      for (final definition in weaponDefinitions)
        if (unlockedWeaponIds.contains(definition.id))
          _weaponChoice(definition, currentWeaponLevels),
    ].whereType<LevelUpChoice>().toList();
    final augmentChoices = <LevelUpChoice?>[
      for (final definition in augmentDefinitions)
        if (unlockedAugmentIds.contains(definition.id))
          _augmentChoice(definition, currentAugmentLevels),
    ].whereType<LevelUpChoice>().toList();

    weaponChoices.shuffle(_random);
    augmentChoices.shuffle(_random);
    final selected = <LevelUpChoice>[];

    if (weaponChoices.isNotEmpty &&
        augmentChoices.isNotEmpty &&
        maxChoices >= 2) {
      selected
        ..add(weaponChoices.removeLast())
        ..add(augmentChoices.removeLast());
    }

    final remaining = [...weaponChoices, ...augmentChoices]..shuffle(_random);
    if (selected.isEmpty) {
      selected.addAll(remaining.take(maxChoices));
    } else {
      selected.addAll(remaining.take(maxChoices - selected.length));
      selected.shuffle(_random);
    }

    return List.unmodifiable(selected);
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
      effectDescription: weaponLevelFor(
        definition.id,
        currentLevel + 1,
      ).displayEffect,
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
      effectDescription: definition.effectDescriptionForLevel(currentLevel + 1),
      type: LevelUpChoiceType.augment,
      currentLevel: currentLevel,
      nextLevel: currentLevel + 1,
    );
  }
}
