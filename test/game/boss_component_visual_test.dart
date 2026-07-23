import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/boss_component.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/content/boss_definitions.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';

void main() {
  test('boss patterns and lethal damage select attack and death visuals', () {
    final definition = bossDefinitionForId(fallenGeneral)!;
    final boss = BossComponent.fromBossDefinition(
      definition: definition,
      targetPositionProvider: (_) => Vector2(100, 0),
    );

    expect(boss.size, Vector2.all(42));
    expect(boss.visualSize, 126);
    expect(boss.visualScale, 3);
    expect(boss.anchor, Anchor.center);

    boss.update(1);
    expect(boss.visualState, EnemyAnimationState.attacking);
    expect(boss.warningSnapshot, isNotNull);

    boss.takeDamage(definition.enemy.maxHealth);
    expect(boss.visualState, EnemyAnimationState.death);
  });

  test(
    'boss warning snapshot keeps pattern duration and phase token stable',
    () {
      final boss = BossComponent.fromBossDefinition(
        definition: maskedExecutionerBossDefinition,
        targetPositionProvider: (_) => Vector2(1000, 0),
      );
      boss.update(.5);
      final warning = boss.warningSnapshot!;
      expect(warning.durationSeconds, .65);
      expect(warning.phaseToken, greaterThan(0));
      boss.update(.05);
      expect(boss.warningSnapshot!.phaseToken, warning.phaseToken);
    },
  );
}
