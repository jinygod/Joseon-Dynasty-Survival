import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/components/player_component.dart';

void main() {
  group('EnemyComponent', () {
    test('detects player overlap using component sizes', () {
      final enemy = EnemyComponent(
        enemyId: 'test_enemy',
        maxHealth: 10,
        moveSpeed: 0,
        damage: 1,
        position: Vector2.zero(),
        size: Vector2.all(18),
      );
      final nearPlayer = PlayerComponent(
        slotIndex: 0,
        maxHealth: 100,
        moveSpeed: 100,
        position: Vector2(20, 0),
        size: Vector2.all(24),
      );
      final farPlayer = PlayerComponent(
        slotIndex: 0,
        maxHealth: 100,
        moveSpeed: 100,
        position: Vector2(22, 0),
        size: Vector2.all(24),
      );

      expect(enemy.overlapsPlayer(nearPlayer), isTrue);
      expect(enemy.overlapsPlayer(farPlayer), isFalse);
    });
  });
}
