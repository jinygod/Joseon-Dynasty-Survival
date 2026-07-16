import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/area_attack_component.dart';
import 'package:pixel_survivor/game/components/boss_component.dart';
import 'package:pixel_survivor/game/content/boss_definitions.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';
import 'package:pixel_survivor/game/systems/boss_controller.dart';

void main() {
  test('large delta leaves a warning visible before execution', () {
    final boss = BossComponent.fromBossDefinition(
      definition: maskedExecutionerBossDefinition,
      targetPositionProvider: (_) => Vector2(1000, 0),
    );
    final initialPosition = boss.position.clone();

    boss.update(double.maxFinite);

    expect(boss.isChargeWarningActive, isTrue);
    expect(boss.controller.phase, BossPhase.warning);
    expect(boss.position.distanceTo(initialPosition), lessThan(10));
  });

  test(
    'legacy constructor and no-argument summon callback remain supported',
    () {
      var summons = 0;
      final boss = BossComponent(
        definition: enemyDefinitions.singleWhere(
          (definition) => definition.id == fallenGeneral,
        ),
        targetPositionProvider: (_) => Vector2(100, 0),
        onSummonRequested: () => summons += 1,
      );
      boss.takeDamage(boss.maxHealth * 0.6);

      for (var index = 0; index < 300; index += 1) {
        boss.update(0.05);
      }

      expect(summons, 1);
    },
  );

  test('component rejects a controller for another boss definition', () {
    expect(
      () => BossComponent.fromBossDefinition(
        definition: plagueMagistrateBossDefinition,
        controller: BossController(definition: maskedExecutionerBossDefinition),
        targetPositionProvider: (_) => Vector2.zero(),
      ),
      throwsArgumentError,
    );
  });

  test('plague magistrate emits a delayed radial area attack', () {
    final attacks = <AreaAttackComponent>[];
    final boss = BossComponent.fromBossDefinition(
      definition: plagueMagistrateBossDefinition,
      targetPositionProvider: (_) => Vector2(100, 0),
      onAreaAttack: attacks.add,
    );

    boss.update(0.50);

    expect(attacks, hasLength(1));
    expect(attacks.single.radius, 145);
    expect(attacks.single.delaySeconds, 0.80);
    expect(attacks.single.angleRadians, greaterThan(6));
    expect(attacks.single.isReady, isFalse);
  });

  test('masked executioner exposes its charge warning before moving', () {
    final boss = BossComponent.fromBossDefinition(
      definition: maskedExecutionerBossDefinition,
      targetPositionProvider: (_) => Vector2(1000, 0),
    );

    boss.update(0.50);

    expect(boss.isChargeWarningActive, isTrue);
    expect(boss.warningPatternId, 'headsmans_rush');
    final beforeCharge = boss.position.x;

    boss.update(0.65);
    boss.update(0.05);

    expect(boss.isChargeWarningActive, isFalse);
    expect(boss.position.x, greaterThan(beforeCharge));
  });

  test(
    'fallen general summon pattern requests its configured minions once',
    () {
      final summons = <List<String>>[];
      final boss = BossComponent.fromBossDefinition(
        definition: fallenGeneralBossDefinition,
        targetPositionProvider: (_) => Vector2(100, 0),
        onSummonEnemiesRequested: (ids) => summons.add(ids),
      );
      boss.takeDamage(boss.maxHealth * 0.6);

      for (var index = 0; index < 300; index += 1) {
        boss.update(0.05);
      }

      expect(summons, hasLength(1));
      expect(summons.single, everyElement(vengefulSpirit));
    },
  );
}
