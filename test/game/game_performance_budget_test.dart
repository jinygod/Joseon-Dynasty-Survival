import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/components/hwando_vfx_component.dart';
import 'package:pixel_survivor/game/combat/attack_spec.dart';
import 'package:pixel_survivor/game/components/combat_effect_component.dart';
import 'package:pixel_survivor/game/components/damage_number_component.dart';
import 'package:pixel_survivor/game/components/projectile_component.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/ids.dart';
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
        position: game.worldConfig.worldSize / 2 + Vector2(-32, 0),
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

  test(
    'master damage requests an emphasized number while normal damage stays compact',
    () async {
      final game = PixelSurvivorGame(
        playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
        onRunEnded: null,
      );
      game.onGameResize(Vector2(960, 540));
      await game.onLoad();
      final target = EnemyComponent(
        enemyId: 'damage-style-target',
        maxHealth: 100,
        moveSpeed: 0,
        damage: 0,
        position: Vector2(480, 270),
      );
      await game.ensureAdd(target);

      game.debugApplyDamageEvent(
        DamageEvent(
          target: target,
          damage: 1,
          knockback: 0,
          direction: Vector2(1, 0),
        ),
      );
      game.update(0);
      expect(
        game.worldChildrenOfType<DamageNumberComponent>().single.isEmphasized,
        isFalse,
      );

      game.update(.13);
      game.debugApplyDamageEvent(
        DamageEvent(
          target: target,
          damage: 1,
          knockback: 0,
          direction: Vector2(1, 0),
          traits: const {AttackTrait.master},
        ),
      );
      game.update(0);
      expect(
        game.worldChildrenOfType<DamageNumberComponent>().where(
          (number) => number.isEmphasized,
        ),
        hasLength(1),
      );
      game.onDispose();
    },
  );

  test(
    'damage aggregation honors the 0.12 second boundary and target identity',
    () async {
      final game = await _loadDamageGame();
      final first = await _addDamageTarget(game, 'first', 160);
      final second = await _addDamageTarget(game, 'second', 260);

      _applyNormalDamage(game, first);
      _advanceDamageTime(game, .119);
      _applyNormalDamage(game, first);
      expect(_numbersFor(game, first), hasLength(1));
      expect(_numbersFor(game, first).single.damage, 2);

      _advanceDamageTime(game, .001);
      _applyNormalDamage(game, first);
      expect(_numbersFor(game, first), hasLength(1));
      expect(_numbersFor(game, first).single.damage, 3);

      _advanceDamageTime(game, .001);
      _applyNormalDamage(game, first);
      _applyNormalDamage(game, second);
      expect(game.elapsedSeconds, closeTo(.121, 1e-9));
      game.update(0);
      expect(_numbersFor(game, first), hasLength(2));
      expect(_numbersFor(game, second), hasLength(1));

      for (final number
          in game.worldChildrenOfType<DamageNumberComponent>().toList()) {
        number.update(.56);
      }
      game.processLifecycleEvents();
      expect(
        game.performanceSnapshot.counts[GamePopulationKind.damageNumber],
        0,
      );
      expect(game.activeDamageNumberAggregateCount, 0);
      _applyNormalDamage(game, first);
      expect(_numbersFor(game, first), hasLength(1));
      expect(game.activeDamageNumberAggregateCount, 1);
      game.onDispose();
    },
  );

  test(
    'only critical, frontal guard break, and master damage are emphasized',
    () async {
      final game = await _loadDamageGame();
      final normal = await _addDamageTarget(game, 'normal', 120);
      final backExplosion = await _addDamageTarget(
        game,
        'back-explosion',
        220,
        tank: true,
      );
      final frontSynergy = await _addDamageTarget(
        game,
        'front-synergy',
        320,
        tank: true,
      );
      final backSynergy = await _addDamageTarget(
        game,
        'back-synergy',
        420,
        tank: true,
      );
      final master = await _addDamageTarget(game, 'master', 520);

      _applyNormalDamage(game, normal, critical: true);
      _applyNormalDamage(
        game,
        backExplosion,
        direction: Vector2(1, 0),
        traits: const {AttackTrait.explosion},
      );
      _applyNormalDamage(
        game,
        frontSynergy,
        direction: Vector2(-1, 0),
        traits: const {AttackTrait.synergy},
      );
      _applyNormalDamage(
        game,
        backSynergy,
        direction: Vector2(1, 0),
        traits: const {AttackTrait.synergy},
      );
      _applyNormalDamage(game, master, traits: const {AttackTrait.master});

      expect(_numbersFor(game, normal).single.isEmphasized, isTrue);
      expect(_numbersFor(game, backExplosion).single.isEmphasized, isFalse);
      expect(_numbersFor(game, frontSynergy).single.isEmphasized, isTrue);
      expect(_numbersFor(game, backSynergy).single.isEmphasized, isFalse);
      expect(_numbersFor(game, master).single.isEmphasized, isTrue);
      game.onDispose();
    },
  );

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

      expect(game.worldChildrenOfType<HwandoVfxComponent>(), hasLength(1));
      expect(game.worldChildrenOfType<CombatEffectComponent>(), isEmpty);
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
          position: origin + Vector2(10, 10),
          velocity: Vector2.zero(),
          lifetime: 100,
        ),
      );
      for (var frame = 0; frame < 40; frame += 1) {
        game.update(.05);
      }

      final target = game.worldChildrenOfType<EnemyComponent>().firstWhere(
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
        game.worldChildrenOfType<EnemyComponent>().where(
          (enemy) => !enemy.isDead,
        ),
        hasLength(constrainedBudget.maxEnemies),
      );
      expect(
        game.worldChildrenOfType<ProjectileComponent>().where(
          (projectile) => !projectile.isRemoving,
        ),
        hasLength(constrainedBudget.maxProjectiles),
      );
      final snapshot = game.performanceSnapshot;
      expect(snapshot.isWithinBudget, isTrue);
      expect(snapshot.counts[GamePopulationKind.damageNumber], 1);
      expect(
        game.worldChildrenOfType<DamageNumberComponent>().single.damage,
        3,
        reason: 'same-target hits inside the 0.12 second window combine',
      );
      expect(snapshot.counts[GamePopulationKind.combatEffect], 1);
      expect(snapshot.rejected[GamePopulationKind.enemy], greaterThan(0));
      expect(snapshot.rejected[GamePopulationKind.projectile], greaterThan(0));
      expect(snapshot.rejected[GamePopulationKind.damageNumber] ?? 0, 0);
      expect(
        snapshot.rejected[GamePopulationKind.combatEffect],
        greaterThanOrEqualTo(2),
      );
      expect(
        runtimeDiagnostics.map((diagnostic) => diagnostic.kind).toSet(),
        containsAll({
          GamePopulationKind.enemy,
          GamePopulationKind.projectile,
          GamePopulationKind.combatEffect,
        }),
      );

      final dyingEnemy = game.worldChildrenOfType<EnemyComponent>().first;
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
}

Future<PixelSurvivorGame> _loadDamageGame() async {
  final game = PixelSurvivorGame(
    playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
    onRunEnded: null,
  );
  game.onGameResize(Vector2(960, 540));
  await game.onLoad();
  return game;
}

Future<EnemyComponent> _addDamageTarget(
  PixelSurvivorGame game,
  String id,
  double x, {
  bool tank = false,
}) async {
  final target = EnemyComponent(
    enemyId: id,
    maxHealth: 100,
    moveSpeed: 0,
    damage: 0,
    behaviorType: tank ? EnemyBehaviorType.tank : EnemyBehaviorType.chase,
    position: Vector2(x, 270),
  );
  target.debugFace(Vector2(1, 0));
  await game.ensureAdd(target);
  return target;
}

void _applyNormalDamage(
  PixelSurvivorGame game,
  EnemyComponent target, {
  bool critical = false,
  Vector2? direction,
  Set<AttackTrait> traits = const {},
}) {
  game.debugApplyDamageEvent(
    DamageEvent(
      target: target,
      damage: 1,
      knockback: 0,
      direction: direction ?? Vector2(1, 0),
      isCritical: critical,
      traits: traits,
    ),
  );
}

void _advanceDamageTime(PixelSurvivorGame game, double seconds) {
  game.debugAdvanceTo(game.elapsedSeconds + seconds);
}

Iterable<DamageNumberComponent> _numbersFor(
  PixelSurvivorGame game,
  EnemyComponent target,
) => game.worldChildrenOfType<DamageNumberComponent>().where(
  (number) => number.position.x == target.position.x,
);
