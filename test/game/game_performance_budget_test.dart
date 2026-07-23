import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/components/combat_effect_component.dart';
import 'package:pixel_survivor/game/components/projectile_component.dart';
import 'package:pixel_survivor/game/components/hwando_vfx_component.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/game_performance_budget.dart';
import 'package:pixel_survivor/game/models/damage_event.dart';
import 'package:pixel_survivor/game/models/player_slot.dart';
import 'package:pixel_survivor/game/pixel_survivor_game.dart';

void main() {
  const constrainedBudget = GamePerformanceBudget(
    maxEnemies: 2,
    maxProjectiles: 1,
    maxDamageNumbers: 1,
    maxCombatEffects: 1,
  );
  var runtimeDiagnostics = <GamePerformanceDiagnostic>[];
  final constrainedGameTester = FlameTester<PixelSurvivorGame>(
    () => PixelSurvivorGame(
      playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
      onRunEnded: null,
      performanceBudget: constrainedBudget,
      onPerformanceDiagnostic: runtimeDiagnostics.add,
      loadVisualAssets: false,
    ),
    gameSize: Vector2(960, 540),
  );
  final stagePriorityGameTester = FlameTester<PixelSurvivorGame>(() {
    final game = PixelSurvivorGame(
      playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
      onRunEnded: null,
      performanceBudget: constrainedBudget,
      loadVisualAssets: false,
    );
    for (var level = 0; level < 6; level += 1) {
      game.weaponSystem.upgrade(hwandoSlash, game.unlockedWeaponIds);
    }
    game.add(
      EnemyComponent(
        enemyId: 'stage-priority-target',
        maxHealth: 10000,
        moveSpeed: 0,
        damage: 0,
        position: Vector2(448, 300),
      ),
    );
    return game;
  }, gameSize: Vector2(960, 540));

  test('standard budget is one positive contract for every population', () {
    expect(GamePerformanceBudget.standard.maxEnemies, 96);
    expect(GamePerformanceBudget.standard.maxProjectiles, 128);
    expect(GamePerformanceBudget.standard.maxDamageNumbers, 24);
    expect(GamePerformanceBudget.standard.maxCombatEffects, 32);

    for (final kind in GamePopulationKind.values) {
      final limit = GamePerformanceBudget.standard.limitFor(kind);
      expect(limit, greaterThan(0), reason: kind.name);
      expect(
        GamePerformanceBudget.standard.canAdd(kind, current: limit - 1),
        isTrue,
      );
      expect(
        GamePerformanceBudget.standard.canAdd(kind, current: limit),
        isFalse,
      );
    }
  });

  test('snapshot reports overages without exposing mutable counts', () {
    const budget = GamePerformanceBudget(
      maxEnemies: 2,
      maxProjectiles: 3,
      maxDamageNumbers: 4,
      maxCombatEffects: 5,
    );
    final snapshot = GamePerformanceSnapshot(
      budget: budget,
      counts: const {
        GamePopulationKind.enemy: 2,
        GamePopulationKind.projectile: 4,
        GamePopulationKind.damageNumber: 1,
        GamePopulationKind.combatEffect: 5,
      },
      rejected: const {GamePopulationKind.projectile: 7},
    );

    expect(snapshot.isWithinBudget, isFalse);
    expect(snapshot.overages, {GamePopulationKind.projectile: 1});
    expect(snapshot.rejected[GamePopulationKind.projectile], 7);
    expect(
      () => snapshot.counts[GamePopulationKind.enemy] = 99,
      throwsUnsupportedError,
    );
  });

  stagePriorityGameTester.testGameWidget(
    'shared stage visual wins the single combat effect slot',
    verify: (game, _) async {
      game.update(.05);
      game.update(0);

      expect(game.children.whereType<HwandoVfxComponent>(), hasLength(1));
      expect(game.children.whereType<CombatEffectComponent>(), isEmpty);
      expect(
        game.performanceSnapshot.counts[GamePopulationKind.combatEffect],
        1,
      );
      expect(
        game.performanceSnapshot.rejected[GamePopulationKind.combatEffect],
        greaterThanOrEqualTo(1),
      );
    },
  );

  constrainedGameTester.testGameWidget(
    'runtime rejects additions at injected limits and reports diagnostics',
    setUp: (game, _) async {
      runtimeDiagnostics.clear();
      final origin = game.activePlayers.single.position;
      for (var index = 0; index < constrainedBudget.maxEnemies; index += 1) {
        await game.ensureAdd(
          EnemyComponent(
            enemyId: 'budget-target-$index',
            maxHealth: 10000,
            moveSpeed: 0,
            damage: 0,
            position: origin + Vector2(120 + (index * 20), 0),
          ),
        );
      }
      for (var frame = 0; frame < 80; frame += 1) {
        game.update(.05);
      }

      game.unlockedWeaponIds.addAll({gakgungShot, singijeonVolley});
      game.weaponSystem
        ..upgrade(gakgungShot, game.unlockedWeaponIds)
        ..upgrade(singijeonVolley, game.unlockedWeaponIds);
      await game.ensureAdd(
        ProjectileComponent(
          weaponId: gakgungShot,
          damage: 1,
          position: Vector2(10, 10),
          velocity: Vector2.zero(),
          lifetime: 100,
        ),
      );
      for (var frame = 0; frame < 40; frame += 1) {
        game.update(.05);
      }

      final target = game.children.whereType<EnemyComponent>().firstWhere(
        (enemy) => !enemy.isDead,
      );
      for (var hit = 0; hit < 3; hit += 1) {
        game.debugApplyDamageEvent(
          DamageEvent(
            target: target,
            damage: 1,
            knockback: 0,
            direction: Vector2.zero(),
            weaponId: hwandoSlash,
          ),
        );
      }
      game.update(0);
    },
    verify: (game, _) async {
      expect(
        game.children.whereType<EnemyComponent>().where(
          (enemy) => !enemy.isDead,
        ),
        hasLength(constrainedBudget.maxEnemies),
      );
      expect(
        game.children.whereType<ProjectileComponent>().where(
          (projectile) => !projectile.isRemoving,
        ),
        hasLength(constrainedBudget.maxProjectiles),
      );
      final snapshot = game.performanceSnapshot;
      expect(snapshot.isWithinBudget, isTrue);
      expect(snapshot.counts[GamePopulationKind.damageNumber], 1);
      expect(snapshot.counts[GamePopulationKind.combatEffect], 1);
      expect(snapshot.rejected[GamePopulationKind.enemy], greaterThan(0));
      expect(snapshot.rejected[GamePopulationKind.projectile], greaterThan(0));
      expect(snapshot.rejected[GamePopulationKind.damageNumber], 2);
      expect(
        snapshot.rejected[GamePopulationKind.combatEffect],
        greaterThanOrEqualTo(2),
      );
      expect(
        runtimeDiagnostics.map((diagnostic) => diagnostic.kind).toSet(),
        GamePopulationKind.values.toSet(),
      );

      final dyingEnemy = game.children.whereType<EnemyComponent>().first;
      dyingEnemy.takeDamage(dyingEnemy.currentHealth);
      expect(
        game.performanceSnapshot.counts[GamePopulationKind.enemy],
        constrainedBudget.maxEnemies,
        reason: 'death animations remain inside the component budget',
      );
    },
  );

  test(
    'boss request survives a full enemy component budget at 270 seconds',
    () async {
      const budget = GamePerformanceBudget(
        maxEnemies: 2,
        maxProjectiles: 1,
        maxDamageNumbers: 1,
        maxCombatEffects: 1,
      );
      final game = PixelSurvivorGame(
        playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
        onRunEnded: null,
        performanceBudget: budget,
      );
      game.onGameResize(Vector2(960, 540));
      await game.onLoad();
      for (var index = 0; index < budget.maxEnemies; index += 1) {
        await game.ensureAdd(
          EnemyComponent(
            enemyId: 'boss-budget-blocker-$index',
            maxHealth: 10000,
            moveSpeed: 0,
            damage: 0,
            position: Vector2(200.0 + index, 200),
          ),
        );
      }

      game.debugAdvanceTo(270);
      for (var frame = 0; frame < 3; frame += 1) {
        game.update(0);
      }

      expect(game.bossRequestCount, 1);
      expect(game.bossSpawnCount, 1);
      expect(game.bossId, isNotNull);
      expect(game.performanceSnapshot.isWithinBudget, isTrue);
      expect(game.debugPopulationIndexIsConsistent(), isTrue);
    },
  );

  test('diagnostic reporter failures cannot escape the game loop', () async {
    const budget = GamePerformanceBudget(
      maxEnemies: 1,
      maxProjectiles: 1,
      maxDamageNumbers: 1,
      maxCombatEffects: 1,
    );
    final game = PixelSurvivorGame(
      playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
      onRunEnded: null,
      performanceBudget: budget,
      onPerformanceDiagnostic: (_) => throw StateError('diagnostic failed'),
    );
    game.onGameResize(Vector2(960, 540));
    await game.onLoad();

    expect(() {
      for (var frame = 0; frame < 80; frame += 1) {
        game.update(.05);
      }
    }, returnsNormally);
    expect(game.performanceSnapshot.isWithinBudget, isTrue);
  });

  constrainedGameTester.testGameWidget(
    'retained owner accounting is complete, summed, and immutable',
    verify: (game, _) async {
      final breakdown = game.performanceRetainedOwnerBreakdown;

      expect(breakdown.keys, {
        'activePlayers',
        'lastWeaponHits',
        'recordedEnemyDefeats',
        'pendingSpiritJadeDrops',
        'talismanAttachments',
        'trackedRegistryAttackVisuals',
      });
      expect(breakdown['activePlayers'], 1);
      expect(breakdown['talismanAttachments'], 0);
      expect(
        breakdown.values.reduce((total, count) => total + count),
        game.performanceRetainedOwnerCount,
      );
      expect(() => breakdown['activePlayers'] = 99, throwsUnsupportedError);
    },
  );
}
