import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/augment_definitions.dart';
import 'package:pixel_survivor/game/content/ids.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_level_definitions.dart';

typedef ExpectedWeaponLevel = ({
  double damage,
  double cooldownSeconds,
  double range,
  int projectileCount,
  int pierce,
  int chainCount,
  double knockback,
  String displayEffect,
});

typedef ExpectedAugment = ({
  AugmentId id,
  String name,
  String effectDescription,
  bool startsUnlocked,
});

void main() {
  test('first stage defines every field for all twenty weapon levels', () {
    const expectedLevels = <WeaponId, List<ExpectedWeaponLevel>>{
      hwandoSlash: [
        (
          damage: 8,
          cooldownSeconds: 0.72,
          range: 58,
          projectileCount: 1,
          pierce: 0,
          chainCount: 0,
          knockback: 45,
          displayEffect: '피해 8, 범위 58',
        ),
        (
          damage: 10,
          cooldownSeconds: 0.72,
          range: 68,
          projectileCount: 1,
          pierce: 0,
          chainCount: 0,
          knockback: 50,
          displayEffect: '피해 10, 범위 +10',
        ),
        (
          damage: 12,
          cooldownSeconds: 0.60,
          range: 68,
          projectileCount: 1,
          pierce: 0,
          chainCount: 0,
          knockback: 55,
          displayEffect: '재사용 시간 0.60초',
        ),
        (
          damage: 15,
          cooldownSeconds: 0.60,
          range: 82,
          projectileCount: 1,
          pierce: 0,
          chainCount: 0,
          knockback: 65,
          displayEffect: '피해 15, 범위 +14',
        ),
        (
          damage: 18,
          cooldownSeconds: 0.52,
          range: 88,
          projectileCount: 2,
          pierce: 0,
          chainCount: 0,
          knockback: 75,
          displayEffect: '좌우 연속 베기 2회',
        ),
      ],
      gakgungShot: [
        (
          damage: 7,
          cooldownSeconds: 1.05,
          range: 420,
          projectileCount: 1,
          pierce: 0,
          chainCount: 0,
          knockback: 10,
          displayEffect: '화살 1발, 피해 7',
        ),
        (
          damage: 9,
          cooldownSeconds: 0.95,
          range: 420,
          projectileCount: 1,
          pierce: 0,
          chainCount: 0,
          knockback: 10,
          displayEffect: '피해 9, 재사용 시간 0.95초',
        ),
        (
          damage: 10,
          cooldownSeconds: 0.95,
          range: 440,
          projectileCount: 1,
          pierce: 1,
          chainCount: 0,
          knockback: 12,
          displayEffect: '관통 +1',
        ),
        (
          damage: 12,
          cooldownSeconds: 0.82,
          range: 460,
          projectileCount: 2,
          pierce: 1,
          chainCount: 0,
          knockback: 12,
          displayEffect: '화살 +1',
        ),
        (
          damage: 15,
          cooldownSeconds: 0.72,
          range: 480,
          projectileCount: 2,
          pierce: 2,
          chainCount: 0,
          knockback: 15,
          displayEffect: '관통 +1, 첫 대상 추가 피해',
        ),
      ],
      talismanThrow: [
        (
          damage: 8,
          cooldownSeconds: 1.40,
          range: 220,
          projectileCount: 1,
          pierce: 0,
          chainCount: 1,
          knockback: 8,
          displayEffect: '연쇄 1회, 원혼 추가 피해',
        ),
        (
          damage: 10,
          cooldownSeconds: 1.30,
          range: 230,
          projectileCount: 1,
          pierce: 0,
          chainCount: 2,
          knockback: 8,
          displayEffect: '연쇄 +1',
        ),
        (
          damage: 12,
          cooldownSeconds: 1.20,
          range: 240,
          projectileCount: 1,
          pierce: 0,
          chainCount: 3,
          knockback: 10,
          displayEffect: '연쇄 +1, 피해 12',
        ),
        (
          damage: 14,
          cooldownSeconds: 1.10,
          range: 255,
          projectileCount: 1,
          pierce: 0,
          chainCount: 4,
          knockback: 10,
          displayEffect: '연쇄 +1, 탐색 범위 +15',
        ),
        (
          damage: 17,
          cooldownSeconds: 1.00,
          range: 270,
          projectileCount: 2,
          pierce: 0,
          chainCount: 5,
          knockback: 12,
          displayEffect: '부적 +1, 연쇄 +1',
        ),
      ],
      thunderCrashBomb: [
        (
          damage: 14,
          cooldownSeconds: 2.60,
          range: 70,
          projectileCount: 1,
          pierce: 0,
          chainCount: 0,
          knockback: 35,
          displayEffect: '폭발 범위 70, 피해 14',
        ),
        (
          damage: 18,
          cooldownSeconds: 2.40,
          range: 82,
          projectileCount: 1,
          pierce: 0,
          chainCount: 0,
          knockback: 45,
          displayEffect: '폭발 범위 +12',
        ),
        (
          damage: 22,
          cooldownSeconds: 2.20,
          range: 94,
          projectileCount: 1,
          pierce: 0,
          chainCount: 0,
          knockback: 55,
          displayEffect: '피해 22, 재사용 시간 2.20초',
        ),
        (
          damage: 26,
          cooldownSeconds: 2.00,
          range: 106,
          projectileCount: 2,
          pierce: 0,
          chainCount: 0,
          knockback: 65,
          displayEffect: '폭발 +1',
        ),
        (
          damage: 32,
          cooldownSeconds: 1.80,
          range: 120,
          projectileCount: 2,
          pierce: 0,
          chainCount: 0,
          knockback: 80,
          displayEffect: '피해 32, 폭발 범위 120',
        ),
      ],
    };

    expect(weaponLevels, hasLength(expectedLevels.length));
    for (final MapEntry(key: weaponId, value: levels)
        in expectedLevels.entries) {
      expect(weaponLevels[weaponId], hasLength(levels.length));
      for (var index = 0; index < levels.length; index += 1) {
        final level = index + 1;
        final actual = weaponLevelFor(weaponId, level);
        final expected = levels[index];
        final reason = '$weaponId level $level';

        expect(actual.damage, expected.damage, reason: '$reason damage');
        expect(
          actual.cooldownSeconds,
          expected.cooldownSeconds,
          reason: '$reason cooldownSeconds',
        );
        expect(actual.range, expected.range, reason: '$reason range');
        expect(
          actual.projectileCount,
          expected.projectileCount,
          reason: '$reason projectileCount',
        );
        expect(actual.pierce, expected.pierce, reason: '$reason pierce');
        expect(
          actual.chainCount,
          expected.chainCount,
          reason: '$reason chainCount',
        );
        expect(
          actual.knockback,
          expected.knockback,
          reason: '$reason knockback',
        );
        expect(
          actual.displayEffect,
          expected.displayEffect,
          reason: '$reason displayEffect',
        );
      }
    }
  });

  test('first stage weapons use the four Korean names', () {
    const expectedNames = <WeaponId, String>{
      hwandoSlash: '환도 베기',
      gakgungShot: '각궁 사격',
      talismanThrow: '부적 투척',
      thunderCrashBomb: '벽력진천뢰',
    };

    for (final MapEntry(key: weaponId, value: name) in expectedNames.entries) {
      final definition = weaponDefinitions.singleWhere(
        (item) => item.id == weaponId,
      );
      expect(definition.name, name, reason: weaponId);
    }
  });

  test('first stage exposes the exact ordered augment definitions', () {
    const expectedAugments = <ExpectedAugment>[
      (
        id: martialTraining,
        name: '무예 단련',
        effectDescription: '모든 무기 피해 +12%',
        startsUnlocked: true,
      ),
      (
        id: quickStep,
        name: '빠른 발놀림',
        effectDescription: '이동 속도 +8%',
        startsUnlocked: true,
      ),
      (
        id: rapidReload,
        name: '빠른 장전',
        effectDescription: '공격 재사용 시간 -10%',
        startsUnlocked: false,
      ),
      (
        id: innerBreath,
        name: '내공 호흡',
        effectDescription: '최대 체력 +10, 체력 10 회복',
        startsUnlocked: true,
      ),
      (
        id: hawkEye,
        name: '매의 눈',
        effectDescription: '치명타 확률 +5%',
        startsUnlocked: true,
      ),
      (
        id: herbalTonic,
        name: '약초 주머니',
        effectDescription: '체력 12 회복',
        startsUnlocked: true,
      ),
      (
        id: jangseungBlessing,
        name: '장승의 가호',
        effectDescription: '경험치 획득 반경 +16',
        startsUnlocked: true,
      ),
      (
        id: powderMastery,
        name: '화약 조제',
        effectDescription: '폭발 범위와 투사체 크기 +10%',
        startsUnlocked: false,
      ),
    ];

    expect(
      firstStageAugmentIds,
      orderedEquals(expectedAugments.map((item) => item.id)),
    );
    for (final expected in expectedAugments) {
      final definition = augmentDefinitions.singleWhere(
        (item) => item.id == expected.id,
      );
      expect(definition.name, expected.name, reason: expected.id);
      expect(definition.maxLevel, 5, reason: expected.id);
      expect(
        definition.effectDescriptionForLevel(1),
        expected.effectDescription,
        reason: expected.id,
      );
      expect(
        definition.startsUnlocked,
        expected.startsUnlocked,
        reason: expected.id,
      );
    }
  });

  test('weaponLevelFor rejects unknown weapon ids', () {
    expect(
      () => weaponLevelFor('unknown_weapon', 1),
      throwsA(
        isA<ArgumentError>()
            .having((error) => error.name, 'name', 'id')
            .having(
              (error) => error.invalidValue,
              'invalidValue',
              'unknown_weapon',
            ),
      ),
    );
  });

  test('weaponLevelFor rejects levels outside one through five', () {
    for (final invalidLevel in [0, 6]) {
      expect(
        () => weaponLevelFor(hwandoSlash, invalidLevel),
        throwsA(
          isA<RangeError>()
              .having((error) => error.name, 'name', 'level')
              .having(
                (error) => error.invalidValue,
                'invalidValue',
                invalidLevel,
              ),
        ),
      );
    }
  });
}
