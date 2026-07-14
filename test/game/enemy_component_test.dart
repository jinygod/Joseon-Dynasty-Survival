import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/components/player_component.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';
import 'package:pixel_survivor/game/content/ids.dart';

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

    test('elite enemy scales health damage size and experience', () {
      final definition = enemyDefinitions.singleWhere(
        (item) => item.id == bandit,
      );

      final enemy = EnemyComponent.fromDefinition(definition, isElite: true);

      expect(enemy.isElite, isTrue);
      expect(enemy.maxHealth, definition.maxHealth * 2.5);
      expect(enemy.damage, definition.damage * 1.4);
      expect(enemy.experienceValue, definition.experience * 3);
      expect(enemy.size.x, greaterThan(18));
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
      enemy.update(0.1);

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
  });
}
