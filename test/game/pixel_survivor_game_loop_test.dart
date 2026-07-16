import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/components/enemy_hazard_component.dart';
import 'package:pixel_survivor/game/components/experience_gem_component.dart';
import 'package:pixel_survivor/game/components/frost_field_component.dart';
import 'package:pixel_survivor/game/components/projectile_component.dart';
import 'package:pixel_survivor/game/components/spirit_jade_component.dart';
import 'package:pixel_survivor/game/components/ward_aura_component.dart';
import 'package:pixel_survivor/game/audio/audio_cue.dart';
import 'package:pixel_survivor/game/content/augment_definitions.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/ids.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';
import 'package:pixel_survivor/game/content/wave_definitions.dart';
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
  var audioCues = <AudioCue>[];
  final audioGameTester = FlameTester<PixelSurvivorGame>(() {
    audioCues = <AudioCue>[];
    return PixelSurvivorGame(
      playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
      onRunEnded: null,
      onAudioCue: audioCues.add,
    );
  }, gameSize: Vector2(960, 540));

  group('PixelSurvivorGame run loop progression', () {
    test('selected stage configures the game wave director', () {
      final game = PixelSurvivorGame(
        playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
        stageId: plagueMarket,
        onRunEnded: null,
        random: Random(7),
      );

      final opening = game.waveDirector.tick(
        elapsedSeconds: 0,
        dt: 8,
        activeEnemyCount: 0,
      );

      expect(game.stageId, plagueMarket);
      expect(opening.spawnRequests, isNotEmpty);
      expect(
        opening.spawnRequests.map((request) => request.enemyId),
        everyElement(isIn(plagueMarketWaves.first.enemyWeights.keys)),
      );
    });

    test('boss jade grants a three second collection phase', () async {
      RunResult? result;
      var persistenceCalls = 0;
      final game = PixelSurvivorGame(
        playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
        onRunEnded: (value) => result = value,
        firstBossRewardAvailable: true,
        rewardRoll: () => .99,
        persistSpiritJade: (_) async {
          persistenceCalls += 1;
          return true;
        },
      );
      game.onGameResize(Vector2(960, 540));
      await game.onLoad();
      game.debugAdvanceTo(270);

      game.debugDefeatBoss();

      expect(game.rewardCollectionSecondsRemaining, 3);
      expect(game.runOutcome, RunOutcome.inProgress);
      for (var frame = 0; frame < 62; frame += 1) {
        game.update(.05);
        await Future<void>.delayed(Duration.zero);
      }
      game.update(.05);

      expect(persistenceCalls, 1);
      expect(result?.outcome, RunOutcome.victory);
      expect(result?.spiritJadeCollected, 1);
    });

    test('selected character contributes its passive modifiers', () {
      final constable = PixelSurvivorGame(
        playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
        onRunEnded: null,
      );
      final dosa = PixelSurvivorGame(
        playerSlot: const PlayerSlot(index: 0, characterId: exorcistDosa),
        onRunEnded: null,
      );
      final hunter = PixelSurvivorGame(
        playerSlot: const PlayerSlot(index: 0, characterId: mountainHunter),
        onRunEnded: null,
      );

      expect(constable.incomingContactDamageMultiplier, 0.88);
      expect(dosa.elementDamageMultipliers, {ElementType.magic: 1.15});
      expect(hunter.criticalChance, 0.10);
    });

    test('level-up emits its audio cue once', () {
      final cues = <AudioCue>[];
      final game = PixelSurvivorGame(
        playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
        onRunEnded: null,
        onAudioCue: cues.add,
      );

      game.gainExperience(11);

      expect(cues, [AudioCue.levelUp]);
    });

    test(
      'boss arrival switches music and victory emits result music',
      () async {
        final cues = <AudioCue>[];
        final game = PixelSurvivorGame(
          playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
          onRunEnded: null,
          onAudioCue: cues.add,
        );
        game.onGameResize(Vector2(960, 540));
        await game.onLoad();

        game.debugAdvanceTo(270);
        game.debugDefeatBossAndPlayerSameFrame();

        expect(cues, [
          AudioCue.bossWarning,
          AudioCue.bossMusic,
          AudioCue.victoryMusic,
        ]);
      },
    );

    audioGameTester.testGameWidget(
      'contact damage and player defeat emit combat and result cues',
      setUp: (game, _) async {
        final player = game.activePlayers.single;
        await game.ensureAdd(
          EnemyComponent(
            enemyId: 'audio_enemy',
            maxHealth: 100,
            moveSpeed: 0,
            damage: player.currentHealth / game.incomingContactDamageMultiplier,
            position: player.position.clone(),
          ),
        );
      },
      verify: (game, _) async {
        game.update(0.016);
        expect(
          audioCues,
          containsAllInOrder([AudioCue.playerHit, AudioCue.defeatMusic]),
        );
      },
    );

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

      final leveledUp = game.gainExperience(11);

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

    gameTester.testGameWidget(
      'new field weapons join the live game loop with capped frost fields',
      setUp: (game, _) async {
        game.unlockedWeaponIds.addAll({jangseungWard, frostFlask});
        game.weaponSystem
          ..upgrade(jangseungWard, game.unlockedWeaponIds)
          ..upgrade(frostFlask, game.unlockedWeaponIds);
        await game.ensureAdd(
          EnemyComponent(
            enemyId: 'field_target',
            maxHealth: 1000,
            moveSpeed: 100,
            damage: 0,
            position: game.activePlayers.single.position + Vector2(30, 0),
          ),
        );
      },
      verify: (game, _) async {
        game.update(.05);
        game.update(.05);

        expect(game.children.whereType<WardAuraComponent>(), hasLength(1));
        expect(game.children.whereType<FrostFieldComponent>(), hasLength(1));

        for (var cycle = 0; cycle < 4; cycle += 1) {
          for (var frame = 0; frame < 60; frame += 1) {
            game.update(.05);
          }
        }
        expect(
          game.children.whereType<FrostFieldComponent>().length,
          lessThanOrEqualTo(3),
        );
      },
    );

    gameTester.testGameWidget(
      'herbalist death creates one poison zone',
      setUp: (game, _) async {
        final herbalist = game.debugSpawnEnemy(
          rottenHerbalist,
          position: game.activePlayers.single.position.clone(),
        );
        herbalist.takeDamage(herbalist.maxHealth);
      },
      verify: (game, _) async {
        game.update(EnemySpriteSheet.deathDurationSeconds);
        expect(
          game.children.whereType<EnemyHazardComponent>().where(
            (hazard) => hazard.kind == EnemyHazardKind.poison,
          ),
          hasLength(1),
        );
        game.update(.05);
        expect(
          game.children.whereType<EnemyHazardComponent>().where(
            (hazard) => hazard.kind == EnemyHazardKind.poison,
          ),
          hasLength(1),
        );
      },
    );

    gameTester.testGameWidget(
      'grave ember haste and maiden slow use one strongest aura',
      setUp: (game, _) async {
        final origin = game.activePlayers.single.position.clone();
        game.debugSpawnEnemy(bandit, position: origin + Vector2(20, 0));
        game.debugSpawnEnemy(graveEmber, position: origin + Vector2(25, 0));
        game.debugSpawnEnemy(graveEmber, position: origin + Vector2(30, 0));
        game.debugSpawnEnemy(sorrowfulMaidenGhost, position: origin);
      },
      verify: (game, _) async {
        game.update(.05);
        final target = game.children.whereType<EnemyComponent>().singleWhere(
          (enemy) => enemy.enemyId == bandit,
        );
        expect(target.environmentalHasteFraction, .2);
        expect(game.activePlayers.single.environmentalSlowFraction, .25);
      },
    );

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

    test('unknown augment choice fails closed without recording state', () {
      final game = newGame();
      const choice = LevelUpChoice(
        id: 'unknown_augment',
        displayName: 'unknown',
        effectDescription: 'unknown',
        type: LevelUpChoiceType.augment,
        currentLevel: 0,
        nextLevel: 1,
      );

      game.applyLevelUpChoice(choice);

      expect(game.currentRunResult().choices, isEmpty);
      expect(game.unlockedAugmentIds, isNot(contains(choice.id)));
      expect(game.augmentLevels, isNot(contains(choice.id)));
      expect(game.augmentLevels[martialTraining], isNull);
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
        expect(result.totalDamageTaken, closeTo(13.2, 0.0001));
        expect(result.lastDamageSource, 'telemetry_enemy');
        expect(result.deathAtSeconds, isNull);
      },
    );

    test('augment levels expose every resolved runtime modifier', () {
      final game = newGame();
      game.augmentLevels
        ..[martialTraining] = 1
        ..[heavyStrike] = 1
        ..[bloodOath] = 1
        ..[quickStep] = 1
        ..[ghostStep] = 1
        ..[rapidReload] = 1
        ..[ironArmorTraining] = 1
        ..[hawkEye] = 1
        ..[powderMastery] = 1
        ..[goblinFire] = 2
        ..[scholarInsight] = 2
        ..[ritualShortcut] = 1
        ..[jangseungBlessing] = 2;

      expect(game.weaponDamageMultiplier, closeTo(1.50, 0.0001));
      expect(game.moveSpeedMultiplier, closeTo(1.23, 0.0001));
      expect(game.attackSpeedMultiplier, closeTo(1.02, 0.0001));
      expect(game.criticalChance, closeTo(0.05, 0.0001));
      expect(game.weaponSizeMultiplier, closeTo(1.10, 0.0001));
      expect(game.incomingContactDamageMultiplier, closeTo(0.9152, 0.0001));
      expect(
        game.elementDamageMultipliers[ElementType.fire],
        closeTo(1.30, 0.0001),
      );
      expect(game.experienceGainMultiplier, closeTo(1.20, 0.0001));
      expect(game.experienceRequirementMultiplier, closeTo(0.85, 0.0001));
      expect(game.experienceToNextLevel, 10);
      expect(game.experiencePickupRadiusBonus, 20);
    });

    test('pickup radius keeps at least seven units of effective range', () {
      final game = newGame()..augmentLevels[ghostStep] = 3;

      expect(game.experiencePickupRadiusBonus, -21);
    });

    gameTester.testGameWidget(
      'ghost step minimum radius collects only real experience gems inside seven units',
      setUp: (game, _) async {
        game.augmentLevels[ghostStep] = 3;
        final playerPosition = game.activePlayers.single.position;
        await game.ensureAdd(
          ExperienceGemComponent(
            experienceValue: 2,
            position: playerPosition + Vector2(6.9, 0),
          ),
        );
        await game.ensureAdd(
          ExperienceGemComponent(
            experienceValue: 4,
            position: playerPosition + Vector2(7.1, 0),
          ),
        );
      },
      verify: (game, _) async {
        game.update(0);

        expect(game.currentExperience, 2);
      },
    );

    final persistedPickupIds = <String>[];
    gameTester.testGameWidget(
      'ghost step minimum radius persists only real spirit jade inside seven units',
      setUp: (game, _) async {
        persistedPickupIds.clear();
        game.augmentLevels[ghostStep] = 3;
        final playerPosition = game.activePlayers.single.position;
        final insideJade = SpiritJadeComponent(
          pickup: const SpiritJadePickup(
            pickupId: 'inside-seven',
            claimsFirstBossReward: false,
          ),
          persistPickup: (pickup) async {
            persistedPickupIds.add(pickup.pickupId);
            return true;
          },
          onCollected: () {},
          isBossDrop: false,
          position: playerPosition + Vector2(6.9, 0),
        );
        await game.ensureAdd(insideJade);
        final outsideJade = SpiritJadeComponent(
          pickup: const SpiritJadePickup(
            pickupId: 'outside-seven',
            claimsFirstBossReward: false,
          ),
          persistPickup: (pickup) async {
            persistedPickupIds.add(pickup.pickupId);
            return true;
          },
          onCollected: () {},
          isBossDrop: false,
          position: playerPosition + Vector2(7.1, 0),
        );
        await game.ensureAdd(outsideJade);
      },
      verify: (game, tester) async {
        game.update(0);
        await tester.pump();

        expect(persistedPickupIds, ['inside-seven']);
      },
    );

    gameTester.testGameWidget(
      'last stand activates at exactly thirty-five percent health',
      setUp: (game, _) async {
        game.augmentLevels[lastStand] = 2;
        final player = game.activePlayers.single;
        player.takeDamage(player.maxHealth - (player.maxHealth * 0.35));
      },
      verify: (game, _) async {
        expect(game.activePlayers.single.healthFraction, closeTo(0.35, 0.0001));
        expect(game.weaponDamageMultiplier, closeTo(1.40, 0.0001));
        expect(game.incomingContactDamageMultiplier, closeTo(0.704, 0.0001));
      },
    );

    gameTester.testGameWidget(
      'last stand modifiers revert after healing above thirty-five percent',
      setUp: (game, _) async {
        game.augmentLevels[lastStand] = 2;
        final player = game.activePlayers.single;
        player.takeDamage(player.maxHealth - (player.maxHealth * 0.35));
        expect(game.weaponDamageMultiplier, closeTo(1.40, 0.0001));
        expect(game.incomingContactDamageMultiplier, closeTo(0.704, 0.0001));
        player.heal(1);
      },
      verify: (game, _) async {
        expect(game.activePlayers.single.healthFraction, greaterThan(0.35));
        expect(game.weaponDamageMultiplier, 1);
        expect(game.incomingContactDamageMultiplier, 0.88);
      },
    );

    test(
      'immediate augments apply once when selected, not from stored levels',
      () async {
        final game = newGame();
        game.augmentLevels
          ..[innerBreath] = 1
          ..[herbalTonic] = 1;
        game.onGameResize(Vector2(960, 540));
        await game.onLoad();
        final player = game.activePlayers.single;

        expect(player.maxHealth, 105);
        expect(player.currentHealth, 105);

        player.takeDamage(20);
        final initialMaxHealth = player.maxHealth;
        final initialHealth = player.currentHealth;

        game.augmentLevels.clear();
        const innerBreathChoice = LevelUpChoice(
          id: innerBreath,
          displayName: '내공 호흡',
          effectDescription: '최대 체력 +10, 체력 10 회복',
          type: LevelUpChoiceType.augment,
          currentLevel: 0,
          nextLevel: 1,
        );
        const herbalTonicChoice = LevelUpChoice(
          id: herbalTonic,
          displayName: 'herbal tonic',
          effectDescription: 'heal 12',
          type: LevelUpChoiceType.augment,
          currentLevel: 0,
          nextLevel: 1,
        );

        game.applyLevelUpChoice(innerBreathChoice);
        game.applyLevelUpChoice(herbalTonicChoice);
        game.updateMovementInput(VectorInput.zero);

        expect(player.maxHealth, initialMaxHealth + 10);
        expect(player.currentHealth, initialHealth + 22);
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
