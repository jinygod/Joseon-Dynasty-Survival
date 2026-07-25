import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/combat/attack_geometry.dart';
import 'package:pixel_survivor/game/combat/attack_spec.dart';
import 'package:pixel_survivor/game/components/boss_component.dart';
import 'package:pixel_survivor/game/components/damage_number_component.dart';
import 'package:pixel_survivor/game/components/enemy_projectile_component.dart';
import 'package:pixel_survivor/game/components/projectile_component.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/models/damage_event.dart';
import 'package:pixel_survivor/game/models/player_slot.dart';
import 'package:pixel_survivor/game/pixel_survivor_game.dart';
import 'package:pixel_survivor/game/world/world_runtime_config.dart';

void main() {
  test(
    'starts player and bounded camera at the world center with configured zoom',
    () async {
      final game = PixelSurvivorGame(
        playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
        onRunEnded: null,
        loadVisualAssets: false,
      );
      game.onGameResize(Vector2(960, 540));
      await game.onLoad();

      expect(
        game.camera.viewfinder.zoom,
        closeTo(WorldRuntimeConfig.standard.cameraZoom, .000001),
      );
      expect(game.activePlayers.single.position, Vector2(1024, 2560));
      expect(game.camera.viewfinder.position, Vector2(1024, 2560));
    },
  );

  test('regular wave spawns around the world-centered player', () async {
    final game = await _loadGame();
    final playerPosition = game.activePlayers.single.position.clone();

    final enemy = game.debugSpawnWaveEnemy(plagueRatSwarm);

    expect(enemy.position.distanceTo(playerPosition), lessThan(700));
    expect(enemy.position.distanceTo(Vector2(480, 270)), greaterThan(1200));
  });

  test(
    'debug-requested boss preserves top-of-viewport intent near player',
    () async {
      final game = await _loadGame();
      final playerPosition = game.activePlayers.single.position.clone();

      game.debugAdvanceTo(270);
      final boss = game.worldChildrenOfType<BossComponent>().single;

      expect(boss.position.distanceTo(playerPosition), closeTo(306, .001));
      expect(boss.position.distanceTo(Vector2(480, -36)), greaterThan(1200));
    },
  );

  test(
    'real camera centers leave production combat outcomes invariant',
    () async {
      final game = await _loadGame();
      final player = game.activePlayers.single;
      player
        ..maxHealth = 1000
        ..currentHealth = 1000;
      final enemy = game.debugSpawnEnemy(
        plagueRatSwarm,
        position: player.position + Vector2(10, 0),
      );
      final projectile = ProjectileComponent(
        weaponId: gakgungShot,
        damage: 10,
        position: player.position + Vector2(8, 0),
        velocity: Vector2.zero(),
      );
      final attack = AttackInstance(
        spec: AttackSpec(
          id: 'camera_invariance',
          shape: AttackShape.circle,
          damage: 10,
          range: 0,
          angleRadians: 0,
          radius: 24,
          width: 0,
          windupSeconds: 0,
          activeSeconds: .1,
          lingerSeconds: 0,
          knockback: 0,
          slowFraction: 0,
          traits: const {},
          presentation: AttackPresentation.normal,
        ),
        origin: player.position,
        direction: Vector2(1, 0),
        sequenceIndex: 0,
      );
      final playerPosition = player.position.clone();
      final enemyPosition = enemy.position.clone();
      final projectilePosition = projectile.position.clone();
      final outcomes = <({bool attack, bool projectile, bool contact})>[];

      for (final (index, center) in [
        Vector2(600, 700),
        Vector2(1500, 4200),
      ].indexed) {
        game.camera.viewfinder.position = center;
        game.combatSystem.reset();
        player.currentHealth = player.maxHealth;
        outcomes.add((
          attack: AttackGeometry.contains(
            attack,
            enemy.position,
            enemy.size.x / 2,
          ),
          projectile: projectile.overlapsEnemy(enemy),
          contact: game.combatSystem.applyContactDamage(
            player: player,
            enemy: enemy,
            now: 1 + index.toDouble(),
          ),
        ));
      }

      expect(outcomes.first, outcomes.last);
      expect(player.position, playerPosition);
      expect(enemy.position, enemyPosition);
      expect(projectile.position, projectilePosition);
    },
  );

  test(
    'resizing keeps the actual camera visible rect inside world edges',
    () async {
      final game = await _loadGame();
      final player = game.activePlayers.single
        ..maxHealth = 1000000
        ..currentHealth = 1000000;

      player.position.setValues(2040, 5110);
      for (var frame = 0; frame < 80; frame += 1) {
        game.update(.05);
      }
      _expectInsideWorld(
        game.camera.visibleWorldRect,
        game.worldConfig.worldBounds,
      );
      final beforeResize = game.camera.viewfinder.position.clone();

      game.onGameResize(Vector2(600, 1000));
      for (var frame = 0; frame < 20; frame += 1) {
        game.update(.05);
      }
      _expectInsideWorld(
        game.camera.visibleWorldRect,
        game.worldConfig.worldBounds,
      );
      expect(game.camera.viewfinder.position, isNot(beforeResize));

      player.position.setValues(8, 8);
      for (var frame = 0; frame < 100; frame += 1) {
        game.update(.05);
      }
      _expectInsideWorld(
        game.camera.visibleWorldRect,
        game.worldConfig.worldBounds,
      );
    },
  );

  test(
    'projectiles near world-centered player survive viewport culling',
    () async {
      final game = await _loadGame();
      game.debugSpawnEnemy(plagueRatSwarm, position: Vector2(1800, 4000));
      final playerProjectile = ProjectileComponent(
        weaponId: gakgungShot,
        damage: 1,
        position: Vector2(1024, 2400),
        velocity: Vector2.zero(),
        lifetime: 10,
      );
      final enemyProjectile = EnemyProjectileComponent(
        sourceId: 'camera_bounds_test',
        damage: 1,
        position: Vector2(1300, 2560),
        velocity: Vector2.zero(),
        lifetime: 10,
      );
      await game.addWorldComponent(playerProjectile);
      await game.addWorldComponent(enemyProjectile);
      game.processLifecycleEvents();

      game.update(.01);
      await Future<void>.delayed(Duration.zero);

      expect(playerProjectile.parent, same(game.world));
      expect(enemyProjectile.parent, same(game.world));
      expect(
        game.worldChildrenOfType<ProjectileComponent>(),
        contains(playerProjectile),
      );
      expect(
        game.worldChildrenOfType<EnemyProjectileComponent>(),
        contains(enemyProjectile),
      );
      expect(playerProjectile.position, Vector2(1024, 2400));
      expect(enemyProjectile.position, Vector2(1300, 2560));
    },
  );

  test('disabled feedback suppresses numbers and shake', () async {
    final game = PixelSurvivorGame(
      playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
      onRunEnded: null,
      damageNumbersEnabled: false,
      screenShakeEnabled: false,
      loadVisualAssets: false,
    );
    game.onGameResize(Vector2(960, 540));
    await game.onLoad();
    final enemy = game.debugSpawnEnemy(
      plagueRatSwarm,
      position: Vector2(500, 270),
    );

    game.debugApplyDamageEvent(
      DamageEvent(
        target: enemy,
        damage: 5,
        knockback: 0,
        direction: Vector2.zero(),
      ),
    );
    game.debugStartScreenShake(4);
    game.update(0.02);
    await Future<void>.delayed(Duration.zero);

    expect(game.children.whereType<DamageNumberComponent>(), isEmpty);
    expect(game.screenShakeOffset, Vector2.zero());
  });

  test(
    'disabling active shake immediately restores the camera position',
    () async {
      final game = PixelSurvivorGame(
        playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
        onRunEnded: null,
        loadVisualAssets: false,
      );
      game.onGameResize(Vector2(960, 540));
      await game.onLoad();
      final restingPosition = game.camera.viewfinder.position.clone();
      game.debugStartScreenShake(4);
      game.update(0.02);
      expect(game.screenShakeOffset.length, greaterThan(0));

      game.applyAccessibilitySettings(
        screenShakeEnabled: false,
        damageNumbersEnabled: true,
      );

      expect(game.screenShakeOffset, Vector2.zero());
      expect(game.camera.viewfinder.position, restingPosition);
    },
  );
}

Future<PixelSurvivorGame> _loadGame() async {
  final game = PixelSurvivorGame(
    playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
    onRunEnded: null,
    loadVisualAssets: false,
  );
  game.onGameResize(Vector2(960, 540));
  await game.onLoad();
  return game;
}

void _expectInsideWorld(Rect visible, Rect world) {
  expect(visible.left, greaterThanOrEqualTo(world.left - .001));
  expect(visible.top, greaterThanOrEqualTo(world.top - .001));
  expect(visible.right, lessThanOrEqualTo(world.right + .001));
  expect(visible.bottom, lessThanOrEqualTo(world.bottom + .001));
}
