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
}
