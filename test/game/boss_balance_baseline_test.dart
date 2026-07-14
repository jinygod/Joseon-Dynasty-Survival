import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';
import 'package:pixel_survivor/game/systems/boss_controller.dart';

void main() {
  test('first boss has the tuned health budget', () {
    final boss = enemyDefinitions.singleWhere(
      (definition) => definition.id == fallenGeneral,
    );
    expect(boss.maxHealth, 900);
  });

  test('both major attacks expose readable warning windows', () {
    expect(BossController.chargeWarningSeconds, greaterThanOrEqualTo(0.75));
    expect(BossController.coneWarningSeconds, greaterThanOrEqualTo(0.6));
    expect(BossController.normalPatternCycleSeconds, greaterThanOrEqualTo(3));
  });

  test('enrage occurs inside the nominal thirty-second boss window', () {
    final controller = BossController();
    controller.tick(dt: BossController.enrageSeconds - 0.01, healthFraction: 1);
    expect(controller.isEnraged, isFalse);

    controller.tick(dt: 0.01, healthFraction: 1);
    expect(controller.isEnraged, isTrue);
    expect(BossController.enrageSeconds, 25);
    expect(controller.movementMultiplier, 1.25);
    expect(controller.patternTimeMultiplier, 1.25);
  });
}
