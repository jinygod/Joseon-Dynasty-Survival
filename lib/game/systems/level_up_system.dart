import 'dart:math';

import '../content/augment_definitions.dart' as augment_content;
import '../content/ids.dart';
import '../content/weapon_definitions.dart' as weapon_content;
import '../content/weapon_level_definitions.dart';
import 'augment_effect_formatter.dart';

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
    if (!weaponLevels.containsKey(definition.id)) {
      return null;
    }
    final currentLevel = currentLevels[definition.id] ?? 0;
    if (currentLevel >= definition.maxLevel) {
      return null;
    }

    return LevelUpChoice(
      id: definition.id,
      displayName: definition.name,
      effectDescription: _weaponDeltaDescription(definition.id, currentLevel),
      type: LevelUpChoiceType.weapon,
      currentLevel: currentLevel,
      nextLevel: currentLevel + 1,
    );
  }

  LevelUpChoice? _augmentChoice(
    AugmentDefinition definition,
    Map<AugmentId, int> currentLevels,
  ) {
    if (definition.effects.isEmpty) {
      return null;
    }
    final currentLevel = currentLevels[definition.id] ?? 0;
    if (currentLevel >= definition.maxLevel) {
      return null;
    }

    return LevelUpChoice(
      id: definition.id,
      displayName: definition.name,
      effectDescription: const AugmentEffectFormatter().describeLevelChange(
        definition,
        currentLevel,
      ),
      type: LevelUpChoiceType.augment,
      currentLevel: currentLevel,
      nextLevel: currentLevel + 1,
    );
  }
}

String _weaponDeltaDescription(WeaponId id, int currentLevel) {
  final next = weaponLevelFor(id, currentLevel + 1);
  if (currentLevel == 0) {
    return '신규 · ${next.displayEffect}';
  }
  final current = weaponLevelFor(id, currentLevel);
  final changes = <String>[];
  if (current.damage != next.damage) {
    changes.add('피해 ${_number(current.damage)} → ${_number(next.damage)}');
  }
  if (current.cooldownSeconds != next.cooldownSeconds) {
    changes.add(
      '재사용 ${current.cooldownSeconds.toStringAsFixed(2)}초 → '
      '${next.cooldownSeconds.toStringAsFixed(2)}초',
    );
  }
  if (current.range != next.range) {
    changes.add('범위 ${_number(current.range)} → ${_number(next.range)}');
  }
  if (current.projectileCount != next.projectileCount) {
    changes.add('공격 수 ${current.projectileCount} → ${next.projectileCount}');
  }
  if (current.pierce != next.pierce) {
    changes.add('관통 ${current.pierce} → ${next.pierce}');
  }
  if (current.chainCount != next.chainCount) {
    changes.add('연쇄 ${current.chainCount} → ${next.chainCount}');
  }
  if (current.knockback != next.knockback) {
    changes.add(
      '넉백 ${_number(current.knockback)} → ${_number(next.knockback)}',
    );
  }
  return changes.join(' · ');
}

String _number(double value) => value == value.roundToDouble()
    ? value.round().toString()
    : value.toStringAsFixed(2);
