import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/player_component.dart';
import 'package:pixel_survivor/game/models/vector_input.dart';

void main() {
  group('PlayerComponent.applyInput', () {
    test('normalizes diagonal movement so it does not exceed move speed', () {
      final player = PlayerComponent(
        slotIndex: 0,
        maxHealth: 100,
        moveSpeed: 100,
      );

      player.applyInput(const VectorInput(1, 1), 1);

      expect(player.position.length, closeTo(100, 0.0001));
    });

    test('clamps movement so the full player stays inside bounds', () {
      final player = PlayerComponent(
        slotIndex: 0,
        maxHealth: 100,
        moveSpeed: 100,
        position: Vector2(95, 50),
        size: Vector2.all(24),
      );

      player.applyInput(const VectorInput(1, 0), 1, bounds: Vector2(100, 100));

      expect(player.position, Vector2(88, 50));
    });

    test('clamps movement at the minimum edge using player half size', () {
      final player = PlayerComponent(
        slotIndex: 0,
        maxHealth: 100,
        moveSpeed: 100,
        position: Vector2(5, 50),
        size: Vector2.all(24),
      );

      player.applyInput(const VectorInput(-1, 0), 1, bounds: Vector2(100, 100));

      expect(player.position, Vector2(12, 50));
    });
  });
}
