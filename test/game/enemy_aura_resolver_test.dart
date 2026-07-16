import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/systems/enemy_aura_resolver.dart';

void main() {
  test('haste and slow use their strongest values without stacking', () {
    final result = const EnemyAuraResolver().resolve(
      hasteFractions: [.2, .2],
      slowFractions: [.15, .35],
    );

    expect(result.hasteFraction, .2);
    expect(result.slowFraction, .35);
  });

  test('aura values clamp to safe ranges', () {
    final result = const EnemyAuraResolver().resolve(
      hasteFractions: [.9],
      slowFractions: [.95],
    );

    expect(result.hasteFraction, .6);
    expect(result.slowFraction, .8);
  });
}
