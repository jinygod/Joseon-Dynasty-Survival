import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/components/player_component.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';
import 'package:pixel_survivor/game/content/ids.dart';
import 'package:pixel_survivor/game/systems/enemy_behavior_controller.dart';

void main() {
  group('EnemyComponent', () {
    test('normal enemy keeps its hitbox while doubling its visual size', () {
      final enemy = EnemyComponent.fromDefinition(enemyDefinitionFor(bandit)!);

      expect(enemy.size, Vector2.all(18));
      expect(enemy.visualSize, 54);
      expect(enemy.visualScale, 3);
      expect(enemy.maxHealth, 18);
      expect(enemy.moveSpeed, 60);
      expect(enemy.damage, 8);
      expect(enemy.experienceValue, 1);
      expect(enemy.anchor, Anchor.center);
      expect(enemy.paint.filterQuality, FilterQuality.none);
    });

    test('environmental slow changes movement and can be reset', () {
      final enemy = EnemyComponent(
        enemyId: 'test_enemy',
        maxHealth: 10,
        moveSpeed: 100,
        damage: 1,
        position: Vector2.zero(),
      );

      enemy.setEnvironmentalSlow(0.45);
      enemy.moveToward(Vector2(1000, 0), 1);
      expect(enemy.position.x, closeTo(55, 0.001));
      expect(enemy.effectiveMoveSpeed, closeTo(55, 0.001));

      enemy.setEnvironmentalSlow(0);
      expect(enemy.effectiveMoveSpeed, 100);
    });

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

    test('unique elite uses authored stats without generic scaling', () {
      final definition = enemyDefinitions.singleWhere(
        (item) => item.id == blackHatAssassin,
      );

      final enemy = EnemyComponent.fromDefinition(definition);

      expect(enemy.isElite, isTrue);
      expect(enemy.rank, EnemyRank.elite);
      expect(enemy.maxHealth, 160);
      expect(enemy.damage, 16);
      expect(enemy.experienceValue, 12);
      expect(enemy.size.x, 40);
      expect(enemy.visualSize, 81);
      expect(enemy.visualScale, closeTo(2.025, 0.00001));
      expect(enemy.anchor, Anchor.center);
    });

    test('herbalist exposes exactly one death zone after lethal damage', () {
      final enemy = EnemyComponent.fromDefinition(
        enemyDefinitionFor(rottenHerbalist)!,
      );

      enemy.takeDamage(enemy.maxHealth);

      expect(enemy.consumeDeathZone(), isTrue);
      expect(enemy.consumeDeathZone(), isFalse);
    });

    test('spear warning locks direction before its thrust request', () {
      var target = Vector2(100, 0);
      final enemy = EnemyComponent.fromDefinition(
        enemyDefinitionFor(spearBandit)!,
        position: Vector2.zero(),
        targetPositionProvider: (_) => target,
      );
      for (var i = 0; i < 45; i++) {
        enemy.update(.05);
      }
      target = Vector2(0, 100);
      for (var i = 0; i < 12; i++) {
        enemy.update(.05);
      }

      final request = enemy.drainAttackRequests().singleWhere(
        (item) => item.kind == EnemyAttackKind.thrust,
      );
      expect(request.direction.x, greaterThan(.99));
      expect(request.direction.y.abs(), lessThan(.01));
    });

    test('vengeful spirit tracks before entering a short dash', () {
      final enemy = EnemyComponent(
        enemyId: vengefulSpirit,
        maxHealth: 22,
        moveSpeed: 10,
        damage: 10,
        behaviorType: EnemyBehaviorType.dash,
        position: Vector2.zero(),
        targetPositionProvider: (_) => Vector2(1000, 0),
      );

      enemy.update(2.4);
      final trackedDistance = enemy.position.x;
      enemy.update(.05);
      expect(enemy.attackPhase, EnemyBehaviorPhase.warning);
      enemy.update(0.25);

      expect(trackedDistance, closeTo(24, 0.001));
      expect(enemy.position.x - trackedDistance, greaterThan(1));
      expect(enemy.isDashing, isTrue);
      enemy.update(0.35);
      expect(enemy.isDashing, isFalse);
    });

    test('dokkaebi reduces received knockback by seventy percent', () {
      final enemy = EnemyComponent(
        enemyId: dokkaebi,
        maxHealth: 38,
        moveSpeed: 36,
        damage: 13,
        behaviorType: EnemyBehaviorType.tank,
      );

      enemy.applyKnockback(Vector2(100, 0));

      expect(enemy.knockbackVelocity.x, closeTo(30, 0.001));
    });

    test('plague rats separate from nearby rats while pursuing', () {
      late EnemyComponent enemy;
      final neighbor = EnemyComponent(
        enemyId: plagueRatSwarm,
        maxHealth: 10,
        moveSpeed: 0,
        damage: 6,
        position: Vector2(0, 2),
      );
      enemy = EnemyComponent(
        enemyId: plagueRatSwarm,
        maxHealth: 10,
        moveSpeed: 10,
        damage: 6,
        behaviorType: EnemyBehaviorType.swarm,
        position: Vector2.zero(),
        targetPositionProvider: (_) => Vector2(100, 0),
        nearbyEnemiesProvider: () => [enemy, neighbor],
      );

      enemy.update(1);

      expect(enemy.position.y, lessThan(0));
      expect(enemy.position.x, greaterThan(0));
    });

    test('enemy hit flash expires and knockback decays', () {
      final enemy = EnemyComponent(
        enemyId: bandit,
        maxHealth: 18,
        moveSpeed: 60,
        damage: 8,
        position: Vector2.zero(),
      );

      enemy.registerHit(knockback: Vector2(80, 0));
      expect(enemy.isHitFlashing, isTrue);
      enemy.update(0.3);

      expect(enemy.isHitFlashing, isFalse);
      expect(enemy.knockbackVelocity.length, lessThan(80));
    });

    test('move attack hit and death select matching visual states', () {
      final enemy = EnemyComponent(
        enemyId: bandit,
        maxHealth: 18,
        moveSpeed: 60,
        damage: 8,
        position: Vector2.zero(),
      );

      enemy.moveToward(Vector2(10, 0), 0.1);
      expect(enemy.visualState, EnemyAnimationState.moving);

      enemy.playAttack();
      expect(enemy.visualState, EnemyAnimationState.attacking);

      enemy.takeDamage(1);
      expect(enemy.visualState, EnemyAnimationState.hit);

      enemy.takeDamage(100);
      expect(enemy.visualState, EnemyAnimationState.death);
    });

    test('enemy sheets share the 4-4-2-6 frame contract', () {
      expect(EnemySpriteSheet.moveFrames, [0, 1, 2, 3]);
      expect(EnemySpriteSheet.attackFrames, [4, 5, 6, 7]);
      expect(EnemySpriteSheet.hitFrames, [8, 9]);
      expect(EnemySpriteSheet.deathFrames, [10, 11, 12, 13, 14, 15]);
      expect(EnemySpriteSheet.specs.keys.toSet(), {
        plagueRatSwarm,
        bandit,
        dokkaebi,
        vengefulSpirit,
        fallenGeneral,
      });
      expect(EnemySpriteSheet.specs[plagueRatSwarm]!.frameSize, 24);
      expect(EnemySpriteSheet.specs[fallenGeneral]!.frameSize, 64);
    });

    test('lethal damage keeps death visuals alive for their full sequence', () {
      final enemy = EnemyComponent(
        enemyId: bandit,
        maxHealth: 18,
        moveSpeed: 60,
        damage: 8,
      );

      enemy.takeDamage(18);
      expect(enemy.deathVisualComplete, isFalse);
      enemy.update(EnemySpriteSheet.deathDurationSeconds - 0.01);
      expect(enemy.deathVisualComplete, isFalse);
      enemy.update(0.01);
      expect(enemy.deathVisualComplete, isTrue);
    });
  });
}
