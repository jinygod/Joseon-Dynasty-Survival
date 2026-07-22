import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/player_component.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/models/vector_input.dart';

void main() {
  group('PlayerComponent.applyInput', () {
    test('exorcist uses authored attack frames and keeps collision size', () {
      final player = PlayerComponent(
        slotIndex: 0,
        characterId: exorcistDosa,
        maxHealth: 100,
        moveSpeed: 120,
      );

      expect(player.size, Vector2.all(24));
      expect(player.displaySize, Vector2.all(56));

      player.playAttack(Vector2(1, 0));

      expect(player.visualState, PlayerAnimationState.attacking);
    });

    test('authored attack returns to the current movement state', () {
      final player = PlayerComponent(
        slotIndex: 0,
        characterId: exorcistDosa,
        maxHealth: 100,
        moveSpeed: 120,
      );

      player.applyInput(const VectorInput(1, 0), 0);
      player.playAttack(Vector2(1, 0));
      player.update(PlayerSpriteSheet.attackDurationSeconds);

      expect(player.visualState, PlayerAnimationState.walking);
      expect(player.isAttacking, isFalse);
    });

    test('authored atlas frame ranges follow the 4 by 4 contract', () {
      expect(
        PlayerSpriteSheet.authoredAssetKey,
        'player/exorcist_dosa_128.png',
      );
      expect(PlayerSpriteSheet.authoredFrameSize, Vector2.all(128));
      expect(PlayerSpriteSheet.moveFrames, [0, 1, 2, 3]);
      expect(PlayerSpriteSheet.attackFrames, [4, 5, 6, 7]);
      expect(PlayerSpriteSheet.hitFrames, [8, 9]);
      expect(PlayerSpriteSheet.deathFrames, [10, 11, 12, 13, 14, 15]);
    });

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

    test('environmental slow reduces movement and resets', () {
      final player = PlayerComponent(
        slotIndex: 0,
        maxHealth: 100,
        moveSpeed: 100,
      );

      player.setEnvironmentalSlow(.25);
      player.applyInput(const VectorInput(1, 0), 1);
      expect(player.position.x, 75);
      expect(player.environmentalSlowFraction, .25);

      player.setEnvironmentalSlow(0);
      player.applyInput(const VectorInput(1, 0), 1);
      expect(player.position.x, 175);
    });

    test('static player art uses one 64px frame for every visual state', () {
      expect(
        PlayerSpriteSheet.assetKey,
        'player/exorcist_swordswoman_static_64.png',
      );
      expect(PlayerSpriteSheet.frameSize, Vector2.all(64));
      expect(PlayerSpriteSheet.displaySize, Vector2.all(108));
      expect(PlayerSpriteSheet.frameCount, 1);

      final player = PlayerComponent(
        slotIndex: 0,
        maxHealth: 100,
        moveSpeed: 100,
      );
      expect(player.size, Vector2.all(24));
      expect(player.maxHealth, 100);
      expect(player.currentHealth, 100);
      expect(player.moveSpeed, 100);
      expect(player.anchor, Anchor.center);
      expect(player.paint.filterQuality, FilterQuality.none);
    });

    test('movement remembers aim while vertical input preserves facing', () {
      final player = PlayerComponent(
        slotIndex: 0,
        maxHealth: 100,
        moveSpeed: 100,
      );

      expect(player.preferredAttackDirection, Vector2(1, 0));

      player.applyInput(const VectorInput(-1, 0), 0);
      expect(player.lastMovementDirection, Vector2(-1, 0));
      expect(player.isFacingLeft, isTrue);

      player.applyInput(const VectorInput(0, -1), 0);
      expect(player.lastMovementDirection, Vector2(0, -1));
      expect(player.isFacingLeft, isTrue);
    });

    test('movement pose eases out instead of snapping to rest', () {
      final player = PlayerComponent(
        slotIndex: 0,
        maxHealth: 100,
        moveSpeed: 100,
      );

      player.applyInput(const VectorInput(1, 0), 0);
      player.update(0.05);
      final movingBlend = player.motionBlend;

      player.applyInput(VectorInput.zero, 0);
      player.update(0.01);

      expect(movingBlend, greaterThan(0));
      expect(player.motionBlend, greaterThan(0));
      expect(player.motionBlend, lessThan(movingBlend));
    });

    test('attack pose keeps movement and world geometry unchanged', () {
      final player = PlayerComponent(
        slotIndex: 0,
        maxHealth: 100,
        moveSpeed: 100,
      );

      player.applyInput(const VectorInput(1, 0), 0.1);
      expect(player.position.x, 10);

      player.playAttack(Vector2(0, -3));
      final positionBeforePoseUpdate = player.position.clone();
      final sizeBeforePoseUpdate = player.size.clone();
      player.update(0.05);

      expect(player.lastAttackDirection, Vector2(0, -1));
      expect(player.isAttacking, isTrue);
      expect(player.position, positionBeforePoseUpdate);
      expect(player.size, sizeBeforePoseUpdate);

      player.applyInput(const VectorInput(1, 0), 0.1);
      expect(player.position.x, 20);
      expect(player.isMoving, isTrue);
    });
  });
}
