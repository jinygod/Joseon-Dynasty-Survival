import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';
import 'package:pixel_survivor/game/content/ids.dart';

void main() {
  test('ranged warning movement preserves the locked aim facing', () {
    var target = Vector2(180, 0);
    final enemy = EnemyComponent.fromDefinition(
      enemyDefinitionFor(sakkatSpecter)!,
      position: Vector2.zero(),
      targetPositionProvider: (_) => target,
    );
    enemy.update(.05);
    expect(enemy.attackPhase, EnemyBehaviorPhase.warning);
    final before = enemy.position.clone();

    target = Vector2(0, 220);
    enemy.update(.05);

    expect(enemy.position.distanceTo(before), greaterThan(0));
    expect(enemy.facingDirection.x, greaterThan(.99));
    expect(enemy.facingDirection.y.abs(), lessThan(.01));
  });
}
