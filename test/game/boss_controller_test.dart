import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/systems/boss_controller.dart';

void main() {
  test('boss cycles charge and cone slash with telegraphs', () {
    final controller = BossController();
    final actions = <BossAction>[];

    for (var index = 0; index < 80; index += 1) {
      actions.addAll(controller.tick(dt: 0.1, healthFraction: 1));
    }

    final types = actions.map((action) => action.type).toList();
    expect(types, contains(BossActionType.chargeWarning));
    expect(types, contains(BossActionType.charge));
    expect(types, contains(BossActionType.coneWarning));
    expect(types, contains(BossActionType.coneDamage));
    expect(
      types.indexOf(BossActionType.chargeWarning),
      lessThan(types.indexOf(BossActionType.charge)),
    );
    expect(
      types.indexOf(BossActionType.coneWarning),
      lessThan(types.indexOf(BossActionType.coneDamage)),
    );
  });

  test(
    'boss summons once below forty percent and enrages after sixty seconds',
    () {
      final controller = BossController();

      expect(
        controller
            .tick(dt: 0.1, healthFraction: 0.39)
            .where((action) => action.type == BossActionType.summon),
        hasLength(1),
      );
      expect(
        controller
            .tick(dt: 0.1, healthFraction: 0.2)
            .where((action) => action.type == BossActionType.summon),
        isEmpty,
      );
      controller.tick(dt: 60, healthFraction: 0.39);

      expect(controller.isEnraged, isTrue);
      expect(controller.movementMultiplier, 1.35);
      expect(controller.patternTimeMultiplier, 1.35);
    },
  );

  test('defeated boss emits no further actions', () {
    final controller = BossController();

    final actions = controller.tick(dt: 1, healthFraction: 0);

    expect(actions, isEmpty);
    expect(controller.phase, BossPhase.defeated);
  });
}
