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
  late List<Component> bulkRemovalTargets;
  late ProjectileComponent expiringFriendly;
  late EnemyProjectileComponent expiringHostile;

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

  test('removal admission excludes an enemy until final unregistration', () {
    final index = GamePopulationIndex();
    final target = enemy('removal-admission');
    index.register(target);

    expect(index.markRemoving(target), isTrue);
    expect(index.enemyCount, 0);
    expect(index.enemies, isEmpty);
    expect(index.mountedEnemies, <EnemyComponent>[target]);

    expect(index.unregister(target), isTrue);
    expect(index.mountedEnemies, isEmpty);
  });

  test('game disposal clears every indexed population', () async {
    final game = PixelSurvivorGame(
      playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
      onRunEnded: null,
      loadVisualAssets: false,
    );
    game.addWorldComponent(enemy('dispose-target'));

    game.onDispose();

    expect(game.performanceSnapshot.counts[GamePopulationKind.enemy], 0);
    expect(game.performanceSnapshot.counts[GamePopulationKind.projectile], 0);
  });

  gameTester.testGameWidget(
    'nested world child lifecycle updates production counts exactly once',
    setUp: (game, _) async {
      lifecycleTarget = enemy('lifecycle-target');
      lifecycleFriendly = projectile()..position = Vector2(480, 270);
      lifecycleHostile = enemyProjectile()..position = Vector2(480, 270);
      await game.addWorldComponent(lifecycleTarget);
      await game.addWorldComponent(lifecycleFriendly);
      await game.addWorldComponent(lifecycleHostile);
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

  gameTester.testGameWidget(
    'removeAll excludes scheduled combat children before lifecycle processing',
    setUp: (game, _) async {
      bulkRemovalTargets = <Component>[
        enemy('bulk-target'),
        projectile()..position = Vector2(480, 270),
        enemyProjectile()..position = Vector2(480, 270),
      ];
      for (final component in bulkRemovalTargets) {
        await game.addWorldComponent(component);
      }
    },
    verify: (game, _) async {
      game.world.removeAll(bulkRemovalTargets);

      expect(game.debugPopulationIndexIsConsistent(), isTrue);
      expect(game.performanceSnapshot.counts[GamePopulationKind.enemy], 0);
      expect(game.performanceSnapshot.counts[GamePopulationKind.projectile], 0);
    },
  );

  gameTester.testGameWidget(
    'removeWhere excludes matching combat children before lifecycle processing',
    setUp: (game, _) async {
      await game.addWorldComponent(enemy('remove-where-survivor'));
      await game.addWorldComponent(projectile()..position = Vector2(480, 270));
      await game.addWorldComponent(
        enemyProjectile()..position = Vector2(480, 270),
      );
    },
    verify: (game, _) async {
      game.world.removeWhere(
        (component) =>
            component is ProjectileComponent ||
            component is EnemyProjectileComponent,
      );

      expect(game.debugPopulationIndexIsConsistent(), isTrue);
      expect(game.performanceSnapshot.counts[GamePopulationKind.enemy], 1);
      expect(game.performanceSnapshot.counts[GamePopulationKind.projectile], 0);
    },
  );

  gameTester.testGameWidget(
    'public live enemy count keeps an alive removing child until final removal',
    setUp: (game, _) async {
      lifecycleTarget = enemy('live-removing-target');
      await game.addWorldComponent(lifecycleTarget);
    },
    verify: (game, _) async {
      lifecycleTarget.removeFromParent();

      expect(game.performanceSnapshot.counts[GamePopulationKind.enemy], 0);
      expect(game.enemyCount, 1);

      game.processLifecycleEvents();
      expect(game.enemyCount, 0);
    },
  );

  gameTester.testGameWidget(
    'friendly and hostile expiry unregisters before lifecycle processing',
    setUp: (game, _) async {
      expiringFriendly = ProjectileComponent(
        weaponId: hwandoSlash,
        damage: 1,
        position: Vector2(480, 270),
        velocity: Vector2.zero(),
        lifetime: 0.01,
      );
      expiringHostile = EnemyProjectileComponent(
        sourceId: 'expiry-test',
        damage: 1,
        position: Vector2(480, 270),
        velocity: Vector2.zero(),
        lifetime: 0.01,
      );
      await game.addWorldComponent(expiringFriendly);
      await game.addWorldComponent(expiringHostile);
    },
    verify: (game, _) async {
      expiringFriendly.update(0.02);
      expiringHostile.update(0.02);

      expect(expiringFriendly.isRemoving, isTrue);
      expect(expiringHostile.isRemoving, isTrue);
      expect(game.performanceSnapshot.counts[GamePopulationKind.projectile], 0);
      expect(game.debugPopulationIndexIsConsistent(), isTrue);

      game.processLifecycleEvents();
      expect(game.debugPopulationIndexIsConsistent(), isTrue);
    },
  );
}
