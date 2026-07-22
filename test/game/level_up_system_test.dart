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
        currentWeaponLevels: const {hwandoSlash: 6},
        currentAugmentLevels: const {},
      );

      expect(choices.map((choice) => choice.id), isNot(contains(hwandoSlash)));
      expect(choices.map((choice) => choice.id), contains(gakgungShot));
    });

    test('level six mastery uses the explicit behavior description', () {
      final choices = LevelUpSystem(random: Random(1)).choices(
        unlockedWeaponIds: {hwandoSlash, talismanThrow},
        unlockedAugmentIds: const {},
        currentWeaponLevels: const {hwandoSlash: 5, talismanThrow: 5},
        currentAugmentLevels: const {},
        maxChoices: 2,
      );

      expect(choices, hasLength(2));
      expect(
        choices.every(
          (choice) => choice.effectDescription.startsWith('마스터 · '),
        ),
        isTrue,
      );
      expect(
        choices
            .singleWhere((choice) => choice.id == hwandoSlash)
            .effectDescription,
        contains('검무 폭풍'),
      );
      expect(
        choices
            .singleWhere((choice) => choice.id == talismanThrow)
            .effectDescription,
        contains('오방 결계'),
      );
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
            effectDescription: '피해 10 → 12 · 재사용 0.72초 → 0.60초 · 넉백 50 → 55',
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
            effectDescription: '무기 피해 +48% → +60%',
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

    test('offers every unlocked runtime weapon and typed augment', () {
      final choices = LevelUpSystem(random: Random(3)).choices(
        unlockedWeaponIds: {
          hwandoSlash,
          jangseungWard,
          singijeonVolley,
          frostFlask,
          windThunderFan,
        },
        unlockedAugmentIds: {martialTraining, goblinFire, lastStand},
        currentWeaponLevels: const {},
        currentAugmentLevels: const {},
        maxChoices: 10,
      );

      expect(choices.map((choice) => choice.id).toSet(), {
        hwandoSlash,
        jangseungWard,
        singijeonVolley,
        frostFlask,
        windThunderFan,
        martialTraining,
        goblinFire,
        lastStand,
      });
      expect(
        choices.every(
          (choice) =>
              choice.effectDescription.contains('→') ||
              choice.effectDescription.startsWith('신규'),
        ),
        isTrue,
      );
    });

    test('six owned weapons suppress every unowned weapon offer', () {
      const owned = {
        hwandoSlash: 1,
        gakgungShot: 1,
        talismanThrow: 1,
        thunderCrashBomb: 1,
        jangseungWard: 1,
        singijeonVolley: 1,
      };
      final choices = LevelUpSystem(random: Random(3)).choices(
        unlockedWeaponIds: weaponDefinitions.map((item) => item.id).toSet(),
        unlockedAugmentIds: const {},
        currentWeaponLevels: owned,
        currentAugmentLevels: const {},
        maxChoices: 12,
      );

      expect(choices, hasLength(6));
      expect(choices.map((choice) => choice.id).toSet(), owned.keys.toSet());
    });

    test('an upgrade for an owned weapon is always offered when available', () {
      const owned = {
        hwandoSlash: 1,
        gakgungShot: 1,
        talismanThrow: 1,
        thunderCrashBomb: 1,
        jangseungWard: 1,
      };

      for (var seed = 0; seed < 20; seed += 1) {
        final choices = LevelUpSystem(random: Random(seed)).choices(
          unlockedWeaponIds: weaponDefinitions.map((item) => item.id).toSet(),
          unlockedAugmentIds: {martialTraining, quickStep, rapidReload},
          currentWeaponLevels: owned,
          currentAugmentLevels: const {},
        );
        expect(
          choices.any(
            (choice) =>
                choice.type == LevelUpChoiceType.weapon &&
                owned.containsKey(choice.id),
          ),
          isTrue,
          reason: 'seed $seed',
        );
      }
    });

    test('augment cards show cumulative production values', () {
      final choices = LevelUpSystem(random: Random(1)).choices(
        unlockedWeaponIds: const {},
        unlockedAugmentIds: {quickStep, rapidReload, jangseungBlessing},
        currentWeaponLevels: const {},
        currentAugmentLevels: const {
          quickStep: 2,
          rapidReload: 3,
          jangseungBlessing: 1,
        },
        maxChoices: 3,
      );

      expect(
        choices.map((choice) => choice.effectDescription),
        containsAll({
          '이동 속도 +16% → +24%',
          '공격 속도 +30% → +40%',
          '획득 반경 +16 → +32',
        }),
      );
    });

    test('augment cards derive compound copy from effect data', () {
      final choices = LevelUpSystem(random: Random(1)).choices(
        unlockedWeaponIds: const {},
        unlockedAugmentIds: {heavyStrike, lastStand, herbalTonic},
        currentWeaponLevels: const {},
        currentAugmentLevels: const {heavyStrike: 1, lastStand: 1},
        maxChoices: 3,
      );
      final copy = {
        for (final choice in choices) choice.id: choice.effectDescription,
      };

      expect(copy[heavyStrike], '무기 피해 +18% → +36% · 공격 속도 -8% → -16%');
      expect(
        copy[lastStand],
        '체력 35% 이하: 받는 접촉 피해 -10% → -20% · 무기 피해 +20% → +40%',
      );
      expect(copy[herbalTonic], '체력 12 회복');
    });
  });
}
