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

    test('applies move speed multiplier to movement distance', () {
      final player = PlayerComponent(
        slotIndex: 0,
        maxHealth: 100,
        moveSpeed: 100,
      )..moveSpeedMultiplier = 1.5;

      player.applyInput(const VectorInput(1, 0), 1);

      expect(player.position.x, 150);
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

    test('takeDamage clamps health at zero and exposes alive state', () {
      final player = PlayerComponent(
        slotIndex: 0,
        maxHealth: 100,
        moveSpeed: 100,
      );

      player.takeDamage(125);

      expect(player.currentHealth, 0);
      expect(player.isAlive, isFalse);
      expect(player.healthFraction, 0);
    });

    test('increasing max health heals once and preserves missing health', () {
      final player = PlayerComponent(
        slotIndex: 0,
        maxHealth: 100,
        moveSpeed: 100,
      )..takeDamage(20);

      player.increaseMaxHealth(10, healAmount: 10);

      expect(player.maxHealth, 110);
      expect(player.currentHealth, 90);
    });

    test('healing clamps at max health', () {
      final player = PlayerComponent(
        slotIndex: 0,
        maxHealth: 100,
        moveSpeed: 100,
      )..takeDamage(5);

      player.heal(12);

      expect(player.currentHealth, 100);
    });

    test('movement, hit, and death select the matching animation state', () {
      final player = PlayerComponent(
        slotIndex: 0,
        maxHealth: 100,
        moveSpeed: 100,
      );

      expect(player.visualState, PlayerAnimationState.idle);

      player.applyInput(const VectorInput(1, 0), 0.1);
      expect(player.visualState, PlayerAnimationState.walking);

      player.takeDamage(10);
      expect(player.visualState, PlayerAnimationState.hit);

      player.update(PlayerSpriteSheet.hitDurationSeconds);
      expect(player.visualState, PlayerAnimationState.walking);

      player.takeDamage(100);
      expect(player.visualState, PlayerAnimationState.death);
    });

    test('sprite sheet contract maps 6 walk, 2 hit, and 8 death frames', () {
      expect(PlayerSpriteSheet.walkFrames, [0, 1, 2, 3, 4, 5]);
      expect(PlayerSpriteSheet.hitFrames, [6, 7]);
      expect(PlayerSpriteSheet.deathFrames, [8, 9, 10, 11, 12, 13, 14, 15]);
      expect(PlayerSpriteSheet.frameSize, Vector2.all(32));
    });
  });
}
