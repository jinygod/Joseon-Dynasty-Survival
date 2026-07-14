import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/boss_component.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';

void main() {
  test('boss patterns and lethal damage select attack and death visuals', () {
    final definition = enemyDefinitions.singleWhere(
      (item) => item.id == fallenGeneral,
    );
    final boss = BossComponent(
      definition: definition,
      targetPositionProvider: (_) => Vector2(100, 0),
    );

    boss.update(1);
    expect(boss.visualState, EnemyAnimationState.attacking);

    boss.takeDamage(definition.maxHealth);
    expect(boss.visualState, EnemyAnimationState.death);
  });
}
