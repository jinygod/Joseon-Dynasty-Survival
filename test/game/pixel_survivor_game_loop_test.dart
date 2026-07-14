import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/components/projectile_component.dart';
import 'package:pixel_survivor/game/content/augment_definitions.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/models/player_slot.dart';
import 'package:pixel_survivor/game/models/run_choice_record.dart';
import 'package:pixel_survivor/game/models/run_outcome.dart';
import 'package:pixel_survivor/game/models/run_result.dart';
import 'package:pixel_survivor/game/models/vector_input.dart';
import 'package:pixel_survivor/game/pixel_survivor_game.dart';
import 'package:pixel_survivor/game/systems/level_up_system.dart';

void main() {
  PixelSurvivorGame newGame() {
    return PixelSurvivorGame(
      playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
      onRunEnded: null,
    );
  }

  final gameTester = FlameTester<PixelSurvivorGame>(
    newGame,
    gameSize: Vector2(960, 540),
  );

  group('PixelSurvivorGame run loop progression', () {
    test('game accepts exactly one player slot', () {
      final game = PixelSurvivorGame(
        playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
        onRunEnded: null,
      );

      expect(game.playerSlot.index, 0);
      expect(game.activePlayers, isEmpty);
    });

    test('rejects an inactive player slot', () {
      const inactiveSlot = PlayerSlot(
        index: 0,
        characterId: rookieConstable,
        isActive: false,
      );

      expect(
        () => PixelSurvivorGame(playerSlot: inactiveSlot, onRunEnded: null),
        throwsA(
          isA<ArgumentError>()
              .having((error) => error.name, 'name', 'playerSlot')
              .having(
                (error) => error.invalidValue,
                'invalidValue',
                inactiveSlot,
              ),
        ),
      );
    });

    test('does not expose a mutable active players collection', () {
      final game = newGame();

      expect(() => game.activePlayers.clear(), throwsUnsupportedError);
    });

    test('starts each run with all globally unlocked weapons and augments', () {
      final game = newGame();

      expect(game.unlockedWeaponIds, containsAll([hwandoSlash, gakgungShot]));
      expect(
        game.unlockedAugmentIds,
        containsAll([martialTraining, quickStep]),
      );
    });

    test('gainExperience queues level-up choices after crossing threshold', () {
      final game = newGame()
        ..unlockedWeaponIds.add(hwandoSlash)
        ..unlockedAugmentIds.add(martialTraining);

      final leveledUp = game.gainExperience(5);

      expect(leveledUp, isTrue);
      expect(game.playerLevel, 2);
      expect(game.currentExperience, 0);
      expect(game.isLevelUpPending, isTrue);
      expect(game.pendingLevelUpChoices, isNotEmpty);
    });

    test('applyLevelUpChoice upgrades a weapon and clears pending state', () {
      final game = newGame()..unlockedWeaponIds.add(hwandoSlash);
      const choice = LevelUpChoice(
        id: hwandoSlash,
        displayName: '환도 베기',
        effectDescription: '피해 8, 범위 58',
        type: LevelUpChoiceType.weapon,
        currentLevel: 0,
        nextLevel: 1,
      );

      game.applyLevelUpChoice(choice);

      expect(game.weaponSystem.levelOf(hwandoSlash), 1);
      expect(game.isLevelUpPending, isFalse);
    });

    test('applyLevelUpChoice upgrades an augment level', () {
      final game = newGame()..unlockedAugmentIds.add(martialTraining);
      const choice = LevelUpChoice(
        id: martialTraining,
        displayName: '무예 단련',
        effectDescription: '모든 무기 피해 +12%',
        type: LevelUpChoiceType.augment,
        currentLevel: 0,
        nextLevel: 1,
      );

      game.applyLevelUpChoice(choice);

      expect(game.augmentLevels[martialTraining], 1);
    });

    test('applyLevelUpChoice records selection order and game time', () {
      final game = newGame()..debugAdvanceTo(42);
      const choice = LevelUpChoice(
        id: martialTraining,
        displayName: '무예 단련',
        effectDescription: '모든 무기 피해 +12%',
        type: LevelUpChoiceType.augment,
        currentLevel: 0,
        nextLevel: 1,
      );

      game.applyLevelUpChoice(choice);

      final recorded = game.currentRunResult().choices.single;
      expect(recorded.type, RunChoiceType.augment);
      expect(recorded.contentId, martialTraining);
      expect(recorded.selectedAtSeconds, 42);
      expect(recorded.selectedLevel, 1);
    });

    test('projectile overkill records only effective weapon damage', () async {
      final game = newGame();
      game.onGameResize(Vector2(960, 540));
      await game.onLoad();
      final enemy = EnemyComponent(
        enemyId: 'telemetry_target',
        maxHealth: 5,
        moveSpeed: 0,
        damage: 0,
        position: Vector2(40, 40),
      );
      await game.add(enemy);
      await game.add(
        ProjectileComponent(
          weaponId: talismanThrow,
          damage: 50,
          position: enemy.position.clone(),
          velocity: Vector2.zero(),
        ),
      );

      game.update(0);

      final result = game.currentRunResult();
      expect(result.weaponDamageTotals[talismanThrow], 5);
      expect(result.weaponKillCounts[talismanThrow], 1);
      expect(enemy.deathVisualComplete, isFalse);
    });

    gameTester.testGameWidget(
      'contact damage records actual health loss and source',
      setUp: (game, _) async {
        final player = game.activePlayers.single;
        await game.ensureAdd(
          EnemyComponent(
            enemyId: 'telemetry_enemy',
            maxHealth: 10000,
            moveSpeed: 0,
            damage: 15,
            position: player.position.clone(),
          ),
        );
      },
      verify: (game, _) async {
        game.update(0.016);

        final result = game.currentRunResult();
        expect(result.totalDamageTaken, 15);
        expect(result.lastDamageSource, 'telemetry_enemy');
        expect(result.deathAtSeconds, isNull);
      },
    );

    test('augment levels expose combat and collection multipliers', () {
      final game = newGame();
      game.augmentLevels
        ..[martialTraining] = 2
        ..[quickStep] = 1
        ..[rapidReload] = 2
        ..[hawkEye] = 1
        ..[powderMastery] = 3
        ..[jangseungBlessing] = 2;

      expect(game.weaponDamageMultiplier, closeTo(1.24, 0.0001));
      expect(game.moveSpeedMultiplier, closeTo(1.08, 0.0001));
      expect(game.attackSpeedMultiplier, closeTo(1.2, 0.0001));
      expect(game.criticalChance, closeTo(0.05, 0.0001));
      expect(game.weaponSizeMultiplier, closeTo(1.3, 0.0001));
      expect(game.experiencePickupRadiusBonus, 32);
    });

    test(
      'inner breath increases max health and heals only when selected',
      () async {
        final game = newGame();
        game.onGameResize(Vector2(960, 540));
        await game.onLoad();
        final player = game.activePlayers.single..takeDamage(20);
        const choice = LevelUpChoice(
          id: innerBreath,
          displayName: '내공 호흡',
          effectDescription: '최대 체력 +10, 체력 10 회복',
          type: LevelUpChoiceType.augment,
          currentLevel: 0,
          nextLevel: 1,
        );

        game.applyLevelUpChoice(choice);
        game.updateMovementInput(VectorInput.zero);

        expect(player.maxHealth, 115);
        expect(player.currentHealth, 95);
      },
    );

    test('boss spawns once and its defeat wins the run', () async {
      RunResult? ended;
      final game = PixelSurvivorGame(
        playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
        random: Random(1),
        onRunEnded: (result) => ended = result,
      );
      game.onGameResize(Vector2(960, 540));
      await game.onLoad();

      game.debugAdvanceTo(270);
      expect(game.bossSpawnCount, 1);
      expect(game.bossName, isNotEmpty);
      expect(game.bossHealthFraction, 1);
      game.debugDefeatBossAndPlayerSameFrame();

      expect(ended?.outcome, RunOutcome.victory);
      expect(ended?.bossDefeated, isTrue);
      expect(game.runOutcome, RunOutcome.victory);
    });

    test('run end callback fires once', () async {
      var calls = 0;
      final game = PixelSurvivorGame(
        playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
        random: Random(1),
        onRunEnded: (_) => calls += 1,
      );
      game.onGameResize(Vector2(960, 540));
      await game.onLoad();

      game.debugKillPlayer();
      game.update(0.016);
      game.update(0.016);

      expect(calls, 1);
      expect(game.runOutcome, RunOutcome.defeat);
    });
  });
}
