import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
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
      expect(result.weaponLevels, build.weaponLevels, reason: build.id);
      expect(result.augmentLevels, build.augmentLevels, reason: build.id);
      expect(result.appliedChoiceCount, greaterThan(0), reason: build.id);
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

  for (var round = 0; round < 500; round += 1) {
    if (_containsTargetLevels(weaponLevels, build.weaponLevels) &&
        _containsTargetLevels(augmentLevels, build.augmentLevels)) {
      return _ConstructedBuild(
        weaponLevels: weaponLevels,
        augmentLevels: augmentLevels,
        appliedChoiceCount: appliedChoices,
      );
    }
    final choices = levelUps.choices(
      unlockedWeaponIds: progression.unlockedWeaponIds,
      unlockedAugmentIds: progression.unlockedAugmentIds,
      currentWeaponLevels: weaponLevels,
      currentAugmentLevels: augmentLevels,
    );
    final selected = choices.where((choice) {
      final target = choice.type == LevelUpChoiceType.weapon
          ? build.weaponLevels[choice.id]
          : build.augmentLevels[choice.id];
      return target != null && choice.nextLevel <= target;
    }).firstOrNull;
    if (selected == null) continue;

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
    target.entries.every((entry) => actual[entry.key] == entry.value);

_CombatSignature _signature(MinimumViableBuild build) {
  var reach = 0.0;
  var control = 0.0;
  var projectileCount = 0;
  var chainCount = 0;
  var persistentSeconds = 0.0;
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
  return _CombatSignature(
    reach: reach,
    control: control,
    projectileCount: projectileCount,
    chainCount: chainCount,
    persistentSeconds: persistentSeconds,
    elements: Set.unmodifiable(elements),
  );
}

class _ConstructedBuild {
  const _ConstructedBuild({
    required this.weaponLevels,
    required this.augmentLevels,
    required this.appliedChoiceCount,
  });

  final Map<WeaponId, int> weaponLevels;
  final Map<AugmentId, int> augmentLevels;
  final int appliedChoiceCount;
}

class _CombatSignature {
  const _CombatSignature({
    required this.reach,
    required this.control,
    required this.projectileCount,
    required this.chainCount,
    required this.persistentSeconds,
    required this.elements,
  });

  final double reach;
  final double control;
  final int projectileCount;
  final int chainCount;
  final double persistentSeconds;
  final Set<ElementType> elements;

  @override
  bool operator ==(Object other) =>
      other is _CombatSignature &&
      reach == other.reach &&
      control == other.control &&
      projectileCount == other.projectileCount &&
      chainCount == other.chainCount &&
      persistentSeconds == other.persistentSeconds &&
      _sameSet(elements, other.elements);

  @override
  int get hashCode => Object.hash(
    reach,
    control,
    projectileCount,
    chainCount,
    persistentSeconds,
    Object.hashAllUnordered(elements),
  );
}

bool _sameSet<T>(Set<T> left, Set<T> right) =>
    left.length == right.length && left.containsAll(right);
