import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/boss_definitions.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';
import 'package:pixel_survivor/game/systems/boss_controller.dart';

void main() {
  for (final bossId in [fallenGeneral, plagueMagistrate, maskedExecutioner]) {
    test('$bossId warns before executing all three patterns', () {
      final definition = bossDefinitionForId(bossId)!;
      final controller = BossController(definition: definition);
      final actions = <BossAction>[];

      for (var index = 0; index < 500; index += 1) {
        actions.addAll(controller.tick(dt: 0.05, healthFraction: 0.35));
      }

      for (final pattern in definition.patterns) {
        final warningIndex = actions.indexWhere(
          (action) =>
              action.type == BossActionType.warning &&
              action.pattern.id == pattern.id,
        );
        final executeIndex = actions.indexWhere(
          (action) =>
              action.type == BossActionType.execute &&
              action.pattern.id == pattern.id,
        );
        expect(warningIndex, greaterThanOrEqualTo(0), reason: pattern.id);
        expect(executeIndex, greaterThan(warningIndex), reason: pattern.id);
      }
    });
  }

  test('fallen general summon is health gated and executes once', () {
    final controller = BossController(
      definition: bossDefinitionForId(fallenGeneral)!,
    );
    final healthyActions = <BossAction>[];
    final woundedActions = <BossAction>[];

    for (var index = 0; index < 300; index += 1) {
      healthyActions.addAll(controller.tick(dt: 0.05, healthFraction: 1));
    }
    for (var index = 0; index < 300; index += 1) {
      woundedActions.addAll(controller.tick(dt: 0.05, healthFraction: 0.4));
    }

    expect(
      healthyActions.where(
        (action) => action.pattern.kind == BossPatternKind.summon,
      ),
      isEmpty,
    );
    expect(
      woundedActions.where(
        (action) =>
            action.type == BossActionType.execute &&
            action.pattern.kind == BossPatternKind.summon,
      ),
      hasLength(1),
    );
  });

  test('each boss enrages at its configured encounter time', () {
    for (final definition in bossDefinitions) {
      final controller = BossController(definition: definition);

      controller.tick(
        dt: definition.enrage.afterSeconds - 0.01,
        healthFraction: 1,
      );
      expect(controller.isEnraged, isFalse, reason: definition.id);

      controller.tick(dt: 0.01, healthFraction: 1);
      expect(controller.isEnraged, isTrue, reason: definition.id);
      expect(
        controller.movementMultiplier,
        definition.enrage.movementMultiplier,
      );
      expect(
        controller.patternTimeMultiplier,
        definition.enrage.patternTimeMultiplier,
      );
    }
  });

  test('defeated boss emits no further actions', () {
    final controller = BossController();

    final actions = controller.tick(dt: 1, healthFraction: 0);

    expect(actions, isEmpty);
    expect(controller.phase, BossPhase.defeated);
    expect(controller.tick(dt: 10, healthFraction: 1), isEmpty);
  });

  test('invalid delta time cannot advance the state machine', () {
    final controller = BossController();

    expect(controller.tick(dt: -1, healthFraction: 1), isEmpty);
    expect(controller.tick(dt: double.nan, healthFraction: 1), isEmpty);
    expect(controller.phase, BossPhase.approach);
  });
}
