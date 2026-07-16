import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/augment_definitions.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/content_integrity.dart';
import 'package:pixel_survivor/game/content/ids.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_level_definitions.dart';
import 'package:pixel_survivor/game/systems/level_up_system.dart';
import 'package:pixel_survivor/game/systems/progression_system.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';
import 'package:pixel_survivor/game/systems/weapon_system.dart';

void main() {
  test('three minimum builds are reachable through production rules', () {
    final progression = const ProgressionSystem().evaluate(
      SaveState.defaults().copyWith(
        bestSurvivalSeconds: 300,
        totalKills: 500,
        levelReachedInRun: 15,
        bossDefeats: 3,
        lowHealthWinCount: 1,
        totalEliteKills: 50,
        victoryCount: 1,
      ),
    );

    expect(minimumViableBuilds, hasLength(3));
    expect(
      minimumViableBuilds.map((build) => build.role).toSet(),
      hasLength(3),
    );
    for (var index = 0; index < minimumViableBuilds.length; index += 1) {
      final build = minimumViableBuilds[index];
      expect(progression.unlockedCharacterIds, contains(build.characterId));
      expect(progression.unlockedStageIds, contains(build.stageId));
      expect(
        progression.unlockedWeaponIds,
        containsAll(build.weaponLevels.keys),
      );
      expect(
        progression.unlockedAugmentIds,
        containsAll(build.augmentLevels.keys),
      );

      final result = _constructBuild(build, progression, seed: 100 + index);
      expect(
        _containsTargetLevels(result.weaponLevels, build.weaponLevels),
        isTrue,
        reason: build.id,
      );
      expect(
        _containsTargetLevels(result.augmentLevels, build.augmentLevels),
        isTrue,
        reason: build.id,
      );
      final character = characterDefinitions.singleWhere(
        (item) => item.id == build.characterId,
      );
      expect(result.startingWeaponId, character.startingWeaponId);
      expect(build.weaponLevels, contains(character.startingWeaponId));
      expect(result.offeredRoundCount, result.appliedChoiceCount);
    }
  });

  test('minimum builds derive three different combat role signatures', () {
    final signatures = {
      for (final build in minimumViableBuilds) build.role: _signature(build),
    };

    expect(signatures, hasLength(3));
    expect(signatures.values.toSet(), hasLength(3));
    expect(
      signatures[CombatBuildRole.frontlineControl]!.control,
      greaterThan(signatures[CombatBuildRole.rangedFocus]!.control),
    );
    expect(
      signatures[CombatBuildRole.rangedFocus]!.reach,
      greaterThan(signatures[CombatBuildRole.areaAttrition]!.reach),
    );
    expect(
      signatures[CombatBuildRole.areaAttrition]!.persistentSeconds,
      greaterThan(0),
    );
    expect(
      signatures[CombatBuildRole.areaAttrition]!.chainCount,
      greaterThan(0),
    );
    expect(
      signatures[CombatBuildRole.frontlineControl]!.survivability,
      greaterThan(signatures[CombatBuildRole.rangedFocus]!.survivability),
    );
    expect(
      signatures[CombatBuildRole.rangedFocus]!.attackSpeed,
      greaterThan(0),
    );
    expect(
      signatures[CombatBuildRole.rangedFocus]!.criticalChance,
      greaterThan(0),
    );
    expect(
      signatures[CombatBuildRole.areaAttrition]!.weaponSize,
      greaterThan(0),
    );
    expect(
      signatures[CombatBuildRole.areaAttrition]!.experienceGain,
      greaterThan(0),
    );
  });
}

_ConstructedBuild _constructBuild(
  MinimumViableBuild build,
  SaveState progression, {
  required int seed,
}) {
  final levelUps = LevelUpSystem(random: Random(seed));
  final weapons = WeaponSystem(random: Random(seed));
  final weaponLevels = <WeaponId, int>{};
  final augmentLevels = <AugmentId, int>{};
  var appliedChoices = 0;
  var offeredRounds = 0;
  final character = characterDefinitions.singleWhere(
    (item) => item.id == build.characterId,
  );
  final startingWeaponId = character.startingWeaponId;
  weapons.upgrade(startingWeaponId, progression.unlockedWeaponIds);
  weaponLevels[startingWeaponId] = weapons.levelOf(startingWeaponId);

  for (var round = 0; round < 500; round += 1) {
    if (_containsTargetLevels(weaponLevels, build.weaponLevels) &&
        _containsTargetLevels(augmentLevels, build.augmentLevels)) {
      return _ConstructedBuild(
        weaponLevels: weaponLevels,
        augmentLevels: augmentLevels,
        appliedChoiceCount: appliedChoices,
        offeredRoundCount: offeredRounds,
        startingWeaponId: startingWeaponId,
      );
    }
    final choices = levelUps.choices(
      unlockedWeaponIds: progression.unlockedWeaponIds,
      unlockedAugmentIds: progression.unlockedAugmentIds,
      currentWeaponLevels: weaponLevels,
      currentAugmentLevels: augmentLevels,
    );
    expect(choices, hasLength(3), reason: '${build.id} round $round');
    offeredRounds += 1;
    final selected =
        choices.where((choice) {
          final target = choice.type == LevelUpChoiceType.weapon
              ? build.weaponLevels[choice.id]
              : build.augmentLevels[choice.id];
          return target != null && choice.nextLevel <= target;
        }).firstOrNull ??
        choices.first;

    if (selected.type == LevelUpChoiceType.weapon) {
      weapons.upgrade(selected.id, progression.unlockedWeaponIds);
      weaponLevels[selected.id] = weapons.levelOf(selected.id);
    } else {
      augmentLevels[selected.id] = selected.nextLevel;
    }
    appliedChoices += 1;
  }
  fail(
    'Could not construct ${build.id}: weapons=$weaponLevels augments=$augmentLevels',
  );
}

bool _containsTargetLevels(Map<String, int> actual, Map<String, int> target) =>
    target.entries.every((entry) => (actual[entry.key] ?? 0) >= entry.value);

_CombatSignature _signature(MinimumViableBuild build) {
  var reach = 0.0;
  var control = 0.0;
  var projectileCount = 0;
  var chainCount = 0;
  var persistentSeconds = 0.0;
  var survivability = 0.0;
  var attackSpeed = 0.0;
  var criticalChance = 0.0;
  var weaponSize = 0.0;
  var experienceGain = 0.0;
  final elements = <ElementType>{};
  for (final entry in build.weaponLevels.entries) {
    final level = weaponLevelFor(entry.key, entry.value);
    final definition = weaponDefinitions.singleWhere(
      (item) => item.id == entry.key,
    );
    reach = max(reach, level.range);
    control += level.knockback;
    projectileCount += level.projectileCount;
    chainCount += level.chainCount;
    persistentSeconds += level.durationSeconds;
    elements.add(definition.element);
  }
  for (final entry in build.augmentLevels.entries) {
    final definition = augmentDefinitionFor(entry.key)!;
    for (final effect in definition.effects) {
      final total = effect.valuePerLevel * entry.value;
      switch (effect.stat) {
        case AugmentStat.maxHealth:
        case AugmentStat.healing:
          survivability += total;
        case AugmentStat.incomingContactDamage:
          survivability -= total;
        case AugmentStat.attackSpeed:
          attackSpeed += total;
        case AugmentStat.criticalChance:
          criticalChance += total;
        case AugmentStat.weaponSize:
          weaponSize += total;
        case AugmentStat.experienceGain:
          experienceGain += total;
        default:
          break;
      }
    }
  }
  return _CombatSignature(
    reach: reach,
    control: control,
    projectileCount: projectileCount,
    chainCount: chainCount,
    persistentSeconds: persistentSeconds,
    survivability: survivability,
    attackSpeed: attackSpeed,
    criticalChance: criticalChance,
    weaponSize: weaponSize,
    experienceGain: experienceGain,
    elements: Set.unmodifiable(elements),
  );
}

class _ConstructedBuild {
  const _ConstructedBuild({
    required this.weaponLevels,
    required this.augmentLevels,
    required this.appliedChoiceCount,
    required this.offeredRoundCount,
    required this.startingWeaponId,
  });

  final Map<WeaponId, int> weaponLevels;
  final Map<AugmentId, int> augmentLevels;
  final int appliedChoiceCount;
  final int offeredRoundCount;
  final WeaponId startingWeaponId;
}

class _CombatSignature {
  const _CombatSignature({
    required this.reach,
    required this.control,
    required this.projectileCount,
    required this.chainCount,
    required this.persistentSeconds,
    required this.survivability,
    required this.attackSpeed,
    required this.criticalChance,
    required this.weaponSize,
    required this.experienceGain,
    required this.elements,
  });

  final double reach;
  final double control;
  final int projectileCount;
  final int chainCount;
  final double persistentSeconds;
  final double survivability;
  final double attackSpeed;
  final double criticalChance;
  final double weaponSize;
  final double experienceGain;
  final Set<ElementType> elements;

  @override
  bool operator ==(Object other) =>
      other is _CombatSignature &&
      reach == other.reach &&
      control == other.control &&
      projectileCount == other.projectileCount &&
      chainCount == other.chainCount &&
      persistentSeconds == other.persistentSeconds &&
      survivability == other.survivability &&
      attackSpeed == other.attackSpeed &&
      criticalChance == other.criticalChance &&
      weaponSize == other.weaponSize &&
      experienceGain == other.experienceGain &&
      _sameSet(elements, other.elements);

  @override
  int get hashCode => Object.hash(
    reach,
    control,
    projectileCount,
    chainCount,
    persistentSeconds,
    survivability,
    attackSpeed,
    criticalChance,
    weaponSize,
    experienceGain,
    Object.hashAllUnordered(elements),
  );
}

bool _sameSet<T>(Set<T> left, Set<T> right) =>
    left.length == right.length && left.containsAll(right);
