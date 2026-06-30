import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/augment_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/systems/level_up_system.dart';

void main() {
  group('LevelUpSystem', () {
    test('returns up to 3 deterministic choices', () {
      const system = LevelUpSystem();

      final choices = system.choices(
        unlockedWeaponIds: {hwandoSlash, gakgungShot},
        unlockedAugmentIds: {martialTraining, quickStep},
        currentWeaponLevels: const {},
        currentAugmentLevels: const {},
      );

      expect(choices, hasLength(3));
      expect(choices.map((choice) => choice.id), [
        hwandoSlash,
        gakgungShot,
        martialTraining,
      ]);
    });

    test('locked augment is not returned', () {
      const system = LevelUpSystem();

      final choices = system.choices(
        unlockedWeaponIds: {hwandoSlash},
        unlockedAugmentIds: {martialTraining},
        currentWeaponLevels: const {},
        currentAugmentLevels: const {},
      );

      expect(choices.map((choice) => choice.id), isNot(contains(rapidReload)));
    });

    test('max-level weapon is not returned', () {
      const system = LevelUpSystem();

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
      const system = LevelUpSystem();

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
            displayName: 'Hwando Slash',
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
            displayName: 'Martial Training',
            type: LevelUpChoiceType.augment,
            currentLevel: 4,
            nextLevel: 5,
          ),
        ),
      );
    });
  });
}
