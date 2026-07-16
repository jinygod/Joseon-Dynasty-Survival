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

typedef ExpectedAugmentEffect = ({
  AugmentStat stat,
  double valuePerLevel,
  AugmentEffectApplication application,
  AugmentCondition condition,
  bool isPenalty,
});

typedef ExpectedAugment = ({
  AugmentId id,
  String name,
  AugmentCategory category,
  int maxLevel,
  bool startsUnlocked,
  List<ExpectedAugmentEffect> effects,
});

void main() {
  test('roster exposes eight weapons with five levels each', () {
    expect(
      weaponDefinitions.map((definition) => definition.id),
      orderedEquals([
        hwandoSlash,
        gakgungShot,
        talismanThrow,
        thunderCrashBomb,
        jangseungWard,
        singijeonVolley,
        frostFlask,
        windThunderFan,
      ]),
    );
    expect(
      weaponLevels.keys,
      containsAll(weaponDefinitions.map((item) => item.id)),
    );
    expect(weaponLevels.values.every((levels) => levels.length == 5), isTrue);
    expect(weaponLevels.values.expand((levels) => levels), hasLength(40));
  });

  test('field weapons expose duration and slow tuning', () {
    final ward = weaponLevelFor(jangseungWard, 5);
    final frost = weaponLevelFor(frostFlask, 5);

    expect(ward.range, 108);
    expect(ward.knockback, 42);
    expect(frost.durationSeconds, 4.5);
    expect(frost.slowFraction, 0.45);
  });

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

    expect(weaponLevels.keys, containsAll(expectedLevels.keys));
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

  test('augment roster has the designed size and category distribution', () {
    expect(augmentDefinitions, hasLength(16));
    expect(augmentDefinitions.map((item) => item.id).toSet(), hasLength(16));
    expect(
      {
        for (final category in AugmentCategory.values)
          category: augmentDefinitions
              .where((augment) => augment.category == category)
              .length,
      },
      {
        AugmentCategory.attack: 5,
        AugmentCategory.survival: 4,
        AugmentCategory.movementAcquisition: 4,
        AugmentCategory.riskReward: 3,
      },
    );
    expect(augmentDefinitions.every((item) => item.effects.isNotEmpty), isTrue);
    expect(
      augmentDefinitions
          .expand((item) => item.effects)
          .every(
            (effect) =>
                effect.valuePerLevel.isFinite && effect.valuePerLevel != 0,
          ),
      isTrue,
    );
  });

  test('augment roster exactly matches the approved definitions', () {
    const continuous = AugmentEffectApplication.continuous;
    const onAcquire = AugmentEffectApplication.onAcquire;
    const always = AugmentCondition.always;
    const lowHealth = AugmentCondition.healthAtOrBelow35;
    const expected = <ExpectedAugment>[
      (
        id: martialTraining,
        name: '무예 단련',
        category: AugmentCategory.attack,
        maxLevel: 5,
        startsUnlocked: true,
        effects: [
          (
            stat: AugmentStat.weaponDamage,
            valuePerLevel: 0.12,
            application: continuous,
            condition: always,
            isPenalty: false,
          ),
        ],
      ),
      (
        id: rapidReload,
        name: '빠른 장전',
        category: AugmentCategory.attack,
        maxLevel: 5,
        startsUnlocked: false,
        effects: [
          (
            stat: AugmentStat.attackSpeed,
            valuePerLevel: 0.10,
            application: continuous,
            condition: always,
            isPenalty: false,
          ),
        ],
      ),
      (
        id: hawkEye,
        name: '매의 눈',
        category: AugmentCategory.attack,
        maxLevel: 5,
        startsUnlocked: true,
        effects: [
          (
            stat: AugmentStat.criticalChance,
            valuePerLevel: 0.05,
            application: continuous,
            condition: always,
            isPenalty: false,
          ),
        ],
      ),
      (
        id: powderMastery,
        name: '화약 조제',
        category: AugmentCategory.attack,
        maxLevel: 5,
        startsUnlocked: false,
        effects: [
          (
            stat: AugmentStat.weaponSize,
            valuePerLevel: 0.10,
            application: continuous,
            condition: always,
            isPenalty: false,
          ),
        ],
      ),
      (
        id: goblinFire,
        name: '도깨비불',
        category: AugmentCategory.attack,
        maxLevel: 5,
        startsUnlocked: false,
        effects: [
          (
            stat: AugmentStat.fireDamage,
            valuePerLevel: 0.15,
            application: continuous,
            condition: always,
            isPenalty: false,
          ),
        ],
      ),
      (
        id: innerBreath,
        name: '내공 호흡',
        category: AugmentCategory.survival,
        maxLevel: 5,
        startsUnlocked: true,
        effects: [
          (
            stat: AugmentStat.maxHealth,
            valuePerLevel: 10,
            application: onAcquire,
            condition: always,
            isPenalty: false,
          ),
          (
            stat: AugmentStat.healing,
            valuePerLevel: 10,
            application: onAcquire,
            condition: always,
            isPenalty: false,
          ),
        ],
      ),
      (
        id: herbalTonic,
        name: '약초 주머니',
        category: AugmentCategory.survival,
        maxLevel: 5,
        startsUnlocked: true,
        effects: [
          (
            stat: AugmentStat.healing,
            valuePerLevel: 12,
            application: onAcquire,
            condition: always,
            isPenalty: false,
          ),
        ],
      ),
      (
        id: ironArmorTraining,
        name: '철갑 수련',
        category: AugmentCategory.survival,
        maxLevel: 5,
        startsUnlocked: true,
        effects: [
          (
            stat: AugmentStat.incomingContactDamage,
            valuePerLevel: -0.06,
            application: continuous,
            condition: always,
            isPenalty: false,
          ),
        ],
      ),
      (
        id: lastStand,
        name: '최후의 저항',
        category: AugmentCategory.survival,
        maxLevel: 3,
        startsUnlocked: false,
        effects: [
          (
            stat: AugmentStat.incomingContactDamage,
            valuePerLevel: -0.10,
            application: continuous,
            condition: lowHealth,
            isPenalty: false,
          ),
          (
            stat: AugmentStat.weaponDamage,
            valuePerLevel: 0.20,
            application: continuous,
            condition: lowHealth,
            isPenalty: false,
          ),
        ],
      ),
      (
        id: quickStep,
        name: '빠른 발놀림',
        category: AugmentCategory.movementAcquisition,
        maxLevel: 5,
        startsUnlocked: true,
        effects: [
          (
            stat: AugmentStat.moveSpeed,
            valuePerLevel: 0.08,
            application: continuous,
            condition: always,
            isPenalty: false,
          ),
        ],
      ),
      (
        id: jangseungBlessing,
        name: '장승의 가호',
        category: AugmentCategory.movementAcquisition,
        maxLevel: 5,
        startsUnlocked: true,
        effects: [
          (
            stat: AugmentStat.pickupRadius,
            valuePerLevel: 16,
            application: continuous,
            condition: always,
            isPenalty: false,
          ),
        ],
      ),
      (
        id: scholarInsight,
        name: '선비의 통찰',
        category: AugmentCategory.movementAcquisition,
        maxLevel: 5,
        startsUnlocked: true,
        effects: [
          (
            stat: AugmentStat.experienceGain,
            valuePerLevel: 0.10,
            application: continuous,
            condition: always,
            isPenalty: false,
          ),
        ],
      ),
      (
        id: ritualShortcut,
        name: '의식 단축',
        category: AugmentCategory.movementAcquisition,
        maxLevel: 1,
        startsUnlocked: false,
        effects: [
          (
            stat: AugmentStat.experienceRequirement,
            valuePerLevel: -0.15,
            application: continuous,
            condition: always,
            isPenalty: false,
          ),
        ],
      ),
      (
        id: heavyStrike,
        name: '강력한 일격',
        category: AugmentCategory.riskReward,
        maxLevel: 5,
        startsUnlocked: false,
        effects: [
          (
            stat: AugmentStat.weaponDamage,
            valuePerLevel: 0.18,
            application: continuous,
            condition: always,
            isPenalty: false,
          ),
          (
            stat: AugmentStat.attackSpeed,
            valuePerLevel: -0.08,
            application: continuous,
            condition: always,
            isPenalty: true,
          ),
        ],
      ),
      (
        id: bloodOath,
        name: '피의 맹세',
        category: AugmentCategory.riskReward,
        maxLevel: 3,
        startsUnlocked: true,
        effects: [
          (
            stat: AugmentStat.weaponDamage,
            valuePerLevel: 0.20,
            application: continuous,
            condition: always,
            isPenalty: false,
          ),
          (
            stat: AugmentStat.incomingContactDamage,
            valuePerLevel: 0.10,
            application: continuous,
            condition: always,
            isPenalty: true,
          ),
        ],
      ),
      (
        id: ghostStep,
        name: '귀신걸음',
        category: AugmentCategory.riskReward,
        maxLevel: 3,
        startsUnlocked: true,
        effects: [
          (
            stat: AugmentStat.moveSpeed,
            valuePerLevel: 0.15,
            application: continuous,
            condition: always,
            isPenalty: false,
          ),
          (
            stat: AugmentStat.pickupRadius,
            valuePerLevel: -12,
            application: continuous,
            condition: always,
            isPenalty: true,
          ),
        ],
      ),
    ];

    expect(
      augmentDefinitions.map((item) => item.id),
      orderedEquals(expected.map((item) => item.id)),
    );
    for (final expectedAugment in expected) {
      final actual = augmentDefinitionFor(expectedAugment.id);
      expect(actual, isNotNull, reason: expectedAugment.id);
      expect(actual!.name, expectedAugment.name, reason: expectedAugment.id);
      expect(
        actual.category,
        expectedAugment.category,
        reason: expectedAugment.id,
      );
      expect(
        actual.maxLevel,
        expectedAugment.maxLevel,
        reason: expectedAugment.id,
      );
      expect(
        actual.startsUnlocked,
        expectedAugment.startsUnlocked,
        reason: expectedAugment.id,
      );
      expect(
        actual.effects.map(
          (effect) => (
            stat: effect.stat,
            valuePerLevel: effect.valuePerLevel,
            application: effect.application,
            condition: effect.condition,
            isPenalty: effect.isPenalty,
          ),
        ),
        orderedEquals(expectedAugment.effects),
        reason: '${expectedAugment.id} effects',
      );
    }
  });

  test('first stage augment ids preserve the original ordered eight', () {
    expect(
      firstStageAugmentIds,
      orderedEquals([
        martialTraining,
        quickStep,
        rapidReload,
        innerBreath,
        hawkEye,
        herbalTonic,
        jangseungBlessing,
        powderMastery,
      ]),
    );
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
