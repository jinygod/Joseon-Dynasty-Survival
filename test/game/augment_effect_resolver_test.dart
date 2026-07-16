import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/augment_definitions.dart';
import 'package:pixel_survivor/game/content/ids.dart';
import 'package:pixel_survivor/game/systems/augment_effect_resolver.dart';

void main() {
  test('resolver aggregates benefits and penalties from definitions', () {
    final result = const AugmentEffectResolver().resolve(
      levels: const {
        martialTraining: 2,
        heavyStrike: 1,
        bloodOath: 1,
        ghostStep: 2,
        goblinFire: 2,
      },
    );
    expect(result.weaponDamageMultiplier, closeTo(1.62, 0.0001));
    expect(result.attackSpeedMultiplier, closeTo(0.92, 0.0001));
    expect(result.incomingContactDamageMultiplier, closeTo(1.10, 0.0001));
    expect(result.moveSpeedMultiplier, closeTo(1.30, 0.0001));
    expect(result.pickupRadiusBonus, -24);
    expect(
      result.elementDamageMultipliers[ElementType.fire],
      closeTo(1.30, 0.0001),
    );
  });

  test('last stand activates exactly at thirty-five percent health', () {
    const resolver = AugmentEffectResolver();
    const levels = {lastStand: 2};
    expect(
      resolver
          .resolve(levels: levels, healthFraction: 0.351)
          .weaponDamageMultiplier,
      1,
    );
    expect(
      resolver
          .resolve(levels: levels, healthFraction: 0.35)
          .weaponDamageMultiplier,
      1.4,
    );
    expect(
      resolver
          .resolve(levels: levels, healthFraction: 0.35)
          .incomingContactDamageMultiplier,
      0.8,
    );
  });

  test('extreme real augment levels respect modifier bounds', () {
    final result = const AugmentEffectResolver().resolve(
      levels: const {
        heavyStrike: 100,
        ghostStep: 100,
        ironArmorTraining: 100,
        hawkEye: 100,
        ritualShortcut: 100,
      },
    );

    expect(result.attackSpeedMultiplier, 0.1);
    expect(result.moveSpeedMultiplier, 16);
    expect(result.incomingContactDamageMultiplier, 0);
    expect(result.criticalChanceBonus, 1);
    expect(result.experienceRequirementMultiplier, 0.2);
  });

  test('on-acquire inner breath effects are not continuous modifiers', () {
    final result = const AugmentEffectResolver().resolve(
      levels: const {innerBreath: 100},
    );

    expect(result.weaponDamageMultiplier, 1);
    expect(result.moveSpeedMultiplier, 1);
    expect(result.incomingContactDamageMultiplier, 1);
  });

  test('last stand does not activate at zero health', () {
    final result = const AugmentEffectResolver().resolve(
      levels: const {lastStand: 3},
      healthFraction: 0,
    );

    expect(result.weaponDamageMultiplier, 1);
    expect(result.incomingContactDamageMultiplier, 1);
  });
}
