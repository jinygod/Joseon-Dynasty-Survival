import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/components/enemy_projectile_component.dart';
import 'package:pixel_survivor/game/components/projectile_component.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/game_performance_budget.dart';
import 'package:pixel_survivor/game/models/player_slot.dart';
import 'package:pixel_survivor/game/performance/game_population_index.dart';
import 'package:pixel_survivor/game/pixel_survivor_game.dart';

void main() {
  EnemyComponent enemy(String id) => EnemyComponent(
    enemyId: id,
    maxHealth: 1,
    moveSpeed: 0,
    damage: 0,
    position: Vector2.zero(),
  );

  ProjectileComponent projectile() => ProjectileComponent(
    weaponId: hwandoSlash,
    damage: 1,
    position: Vector2.zero(),
    velocity: Vector2.zero(),
  );

  EnemyProjectileComponent enemyProjectile() => EnemyProjectileComponent(
    sourceId: 'test',
    damage: 1,
    position: Vector2.zero(),
    velocity: Vector2.zero(),
  );

  final gameTester = FlameTester<PixelSurvivorGame>(
    () => PixelSurvivorGame(
      playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
      onRunEnded: null,
      loadVisualAssets: false,
    ),
    gameSize: Vector2(960, 540),
  );
  late EnemyComponent lifecycleTarget;
  late ProjectileComponent lifecycleFriendly;
  late EnemyProjectileComponent lifecycleHostile;

  test('tracks combat components by identity with idempotent removal', () {
    final index = GamePopulationIndex();
    final first = enemy('same-id');
    final second = enemy('same-id');
    final shot = projectile();
    final hostileShot = enemyProjectile();

    expect(index.register(first), isTrue);
    expect(index.register(first), isFalse);
    expect(index.register(second), isTrue);
    expect(index.register(shot), isTrue);
    expect(index.register(hostileShot), isTrue);
    expect(index.enemyCount, 2);
    expect(index.projectileCount, 2);
    expect(index.enemies, containsAll(<EnemyComponent>[first, second]));

    expect(index.unregister(first), isTrue);
    expect(index.unregister(first), isFalse);
    expect(index.unregister(enemy('not-registered')), isFalse);
    expect(index.enemyCount, 1);
  });

  test('exposes unmodifiable typed live views', () {
    final index = GamePopulationIndex();
    final first = enemy('first');
    final second = enemy('second');

    index.register(first);
    final enemies = index.enemies;
    expect(() => enemies.add(second), throwsUnsupportedError);
    expect(enemies, <EnemyComponent>[first]);

    index.register(second);
    expect(enemies, containsAll(<EnemyComponent>[first, second]));
  });

  test('clear removes every indexed population', () {
    final index = GamePopulationIndex()
      ..register(enemy('enemy'))
      ..register(projectile())
      ..register(enemyProjectile());

    index.clear();

    expect(index.enemyCount, 0);
    expect(index.projectileCount, 0);
    expect(index.enemies, isEmpty);
    expect(index.playerProjectiles, isEmpty);
    expect(index.enemyProjectiles, isEmpty);
  });

  gameTester.testGameWidget(
    'game snapshot follows mounted combat lifecycle and dispose',
    setUp: (game, _) async {
      lifecycleTarget = enemy('lifecycle-target');
      lifecycleFriendly = projectile()..position = Vector2(480, 270);
      lifecycleHostile = enemyProjectile()..position = Vector2(480, 270);
      await game.ensureAdd(lifecycleTarget);
      await game.ensureAdd(lifecycleFriendly);
      await game.ensureAdd(lifecycleHostile);
    },
    verify: (game, _) async {
      expect(game.performanceSnapshot.counts[GamePopulationKind.enemy], 1);
      expect(game.performanceSnapshot.counts[GamePopulationKind.projectile], 2);
      expect(game.debugPopulationIndexIsConsistent(), isTrue);

      lifecycleTarget.takeDamage(lifecycleTarget.currentHealth);
      expect(
        game.performanceSnapshot.counts[GamePopulationKind.enemy],
        1,
        reason: 'dying enemies retain the historical component-count admission',
      );

      lifecycleTarget.removeFromParent();
      lifecycleFriendly.removeFromParent();
      lifecycleHostile.removeFromParent();
      expect(game.debugPopulationIndexIsConsistent(), isTrue);
      expect(game.performanceSnapshot.counts[GamePopulationKind.enemy], 0);
      expect(game.performanceSnapshot.counts[GamePopulationKind.projectile], 0);

      game.processLifecycleEvents();
      expect(game.debugPopulationIndexIsConsistent(), isTrue);
      expect(game.performanceSnapshot.counts[GamePopulationKind.enemy], 0);
      expect(game.performanceSnapshot.counts[GamePopulationKind.projectile], 0);
    },
  );
}
