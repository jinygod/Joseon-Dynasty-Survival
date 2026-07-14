import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/augment_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/systems/level_up_system.dart';

void main() {
  group('LevelUpSystem', () {
    test('returns up to 3 deterministic choices for a fixed seed', () {
      final firstSystem = LevelUpSystem(random: Random(1));
      final secondSystem = LevelUpSystem(random: Random(1));

      final firstChoices = firstSystem.choices(
        unlockedWeaponIds: {hwandoSlash, gakgungShot},
        unlockedAugmentIds: {martialTraining, quickStep},
        currentWeaponLevels: const {},
        currentAugmentLevels: const {},
      );
      final secondChoices = secondSystem.choices(
        unlockedWeaponIds: {hwandoSlash, gakgungShot},
        unlockedAugmentIds: {martialTraining, quickStep},
        currentWeaponLevels: const {},
        currentAugmentLevels: const {},
      );

      expect(firstChoices, hasLength(3));
      expect(
        firstChoices.map((choice) => choice.id),
        secondChoices.map((choice) => choice.id),
      );
    });

    test('locked augment is not returned', () {
      final system = LevelUpSystem(random: Random(1));

      final choices = system.choices(
        unlockedWeaponIds: {hwandoSlash},
        unlockedAugmentIds: {martialTraining},
        currentWeaponLevels: const {},
        currentAugmentLevels: const {},
      );

      expect(choices.map((choice) => choice.id), isNot(contains(rapidReload)));
    });

    test('max-level weapon is not returned', () {
      final system = LevelUpSystem(random: Random(1));

      final choices = system.choices(
        unlockedWeaponIds: {hwandoSlash, gakgungShot},
        unlockedAugmentIds: const {},
        currentWeaponLevels: const {hwandoSlash: 5},
        currentAugmentLevels: const {},
      );

      expect(choices.map((choice) => choice.id), isNot(contains(hwandoSlash)));
      expect(choices.map((choice) => choice.id), contains(gakgungShot));
    });

    test('currentLevel and nextLevel are correct', () {
      final system = LevelUpSystem(random: Random(1));

      final choices = system.choices(
        unlockedWeaponIds: {hwandoSlash},
        unlockedAugmentIds: {martialTraining},
        currentWeaponLevels: const {hwandoSlash: 2},
        currentAugmentLevels: const {martialTraining: 4},
      );

      expect(
        choices,
        contains(
          const LevelUpChoice(
            id: hwandoSlash,
            displayName: '환도 베기',
            effectDescription: '재사용 시간 0.60초',
            type: LevelUpChoiceType.weapon,
            currentLevel: 2,
            nextLevel: 3,
          ),
        ),
      );
      expect(
        choices,
        contains(
          const LevelUpChoice(
            id: martialTraining,
            displayName: '무예 단련',
            effectDescription: '모든 무기 피해 +12%',
            type: LevelUpChoiceType.augment,
            currentLevel: 4,
            nextLevel: 5,
          ),
        ),
      );
    });

    test('choices mix weapon and augment when both are available', () {
      final choices = LevelUpSystem(random: Random(2)).choices(
        unlockedWeaponIds: {hwandoSlash, gakgungShot},
        unlockedAugmentIds: {martialTraining, quickStep},
        currentWeaponLevels: {hwandoSlash: 1},
        currentAugmentLevels: const {},
      );

      expect(choices, hasLength(3));
      expect(choices.map((choice) => choice.type).toSet(), hasLength(2));
      expect(
        choices.every((choice) => choice.effectDescription.isNotEmpty),
        isTrue,
      );
    });
  });
}
