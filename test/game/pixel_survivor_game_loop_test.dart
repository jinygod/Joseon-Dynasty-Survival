import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/area_attack_component.dart';
import 'package:pixel_survivor/game/components/actor_shadow_component.dart';
import 'package:pixel_survivor/game/components/damage_number_component.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/components/enemy_combat_overlay_component.dart';
import 'package:pixel_survivor/game/components/attack_effect_component.dart';
import 'package:pixel_survivor/game/components/combat_effect_component.dart';
import 'package:pixel_survivor/game/components/enemy_hazard_component.dart';
import 'package:pixel_survivor/game/components/enemy_projectile_component.dart';
import 'package:pixel_survivor/game/components/experience_gem_component.dart';
import 'package:pixel_survivor/game/components/frost_field_component.dart';
import 'package:pixel_survivor/game/components/five_color_ward_component.dart';
import 'package:pixel_survivor/game/components/projectile_component.dart';
import 'package:pixel_survivor/game/components/player_component.dart';
import 'package:pixel_survivor/game/components/spirit_jade_component.dart';
import 'package:pixel_survivor/game/components/stage_backdrop_component.dart';
import 'package:pixel_survivor/game/components/talisman_presentation_component.dart';
import 'package:pixel_survivor/game/components/ward_aura_component.dart';
import 'package:pixel_survivor/game/audio/audio_cue.dart';
import 'package:pixel_survivor/game/combat/attack_geometry.dart';
import 'package:pixel_survivor/game/combat/attack_spec.dart';
import 'package:pixel_survivor/game/content/augment_definitions.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/combat_effect_atlas.dart';
import 'package:pixel_survivor/game/content/ids.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';
import 'package:pixel_survivor/game/content/playtest_content_policy.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';
import 'package:pixel_survivor/game/content/wave_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/models/player_slot.dart';
import 'package:pixel_survivor/game/models/damage_event.dart';
import 'package:pixel_survivor/game/models/run_choice_record.dart';
import 'package:pixel_survivor/game/models/run_outcome.dart';
import 'package:pixel_survivor/game/models/run_result.dart';
import 'package:pixel_survivor/game/models/vector_input.dart';
import 'package:pixel_survivor/game/pixel_survivor_game.dart';
import 'package:pixel_survivor/game/game_performance_budget.dart';
import 'package:pixel_survivor/game/systems/level_up_system.dart';
import 'package:pixel_survivor/game/systems/talisman_executor.dart';
import 'package:pixel_survivor/game/systems/weapon_synergy_resolver.dart';

void main() {
  PixelSurvivorGame newGame() {
    return PixelSurvivorGame(
      playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
      onRunEnded: null,
    );
  }

  AttackInstance wardAttack({
    required Vector2 position,
    double damage = 4,
    double radius = 40,
    double duration = .5,
    double slow = .3,
    AttackPresentation presentation = AttackPresentation.strong,
  }) => AttackInstance(
    spec: AttackSpec(
      id: presentation == AttackPresentation.master
          ? 'talisman_master_ward'
          : 'talisman_small_ward',
      shape: AttackShape.circle,
      damage: damage,
      range: 0,
      angleRadians: 0,
      radius: radius,
      width: 0,
      windupSeconds: 0,
      activeSeconds: .1,
      lingerSeconds: duration,
      knockback: 0,
      slowFraction: slow,
      traits: const {AttackTrait.explosion},
      presentation: presentation,
    ),
    origin: position,
    direction: Vector2(1, 0),
    sequenceIndex: 0,
  );

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
  final masterGameTester = FlameTester<PixelSurvivorGame>(() {
    audioCues = <AudioCue>[];
    final game = PixelSurvivorGame(
      playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
      onRunEnded: null,
      onAudioCue: audioCues.add,
    );
    for (var level = 0; level < 6; level += 1) {
      game.weaponSystem.upgrade(hwandoSlash, game.unlockedWeaponIds);
    }
    for (final position in [
      Vector2(448, 300),
      Vector2(400, 348),
      Vector2(352, 300),
      Vector2(520, 420),
    ]) {
      game.add(
        EnemyComponent(
          enemyId: bandit,
          maxHealth: 10000,
          moveSpeed: 0,
          damage: 0,
          position: position,
        ),
      );
    }
    return game;
  }, gameSize: Vector2(960, 540));
  final criticalMasterGameTester = FlameTester<PixelSurvivorGame>(() {
    final game = PixelSurvivorGame(
      playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
      onRunEnded: null,
    )..augmentLevels[hawkEye] = 20;
    for (var level = 0; level < 6; level += 1) {
      game.weaponSystem.upgrade(hwandoSlash, game.unlockedWeaponIds);
    }
    game.add(
      EnemyComponent(
        enemyId: bandit,
        maxHealth: 10000,
        moveSpeed: 0,
        damage: 0,
        position: Vector2(448, 300),
      ),
    );
    return game;
  }, gameSize: Vector2(960, 540));
  final cappedProjectileGameTester = FlameTester<PixelSurvivorGame>(
    () => PixelSurvivorGame(
      playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
      onRunEnded: null,
      performanceBudget: const GamePerformanceBudget(
        maxEnemies: 96,
        maxProjectiles: 1,
        maxDamageNumbers: 24,
        maxCombatEffects: 32,
      ),
    ),
    gameSize: Vector2(960, 540),
  );
  final mixedProjectileGameTester = FlameTester<PixelSurvivorGame>(
    () => PixelSurvivorGame(
      playerSlot: const PlayerSlot(index: 0, characterId: mountainHunter),
      onRunEnded: null,
      performanceBudget: const GamePerformanceBudget(
        maxEnemies: 96,
        maxProjectiles: 1,
        maxDamageNumbers: 24,
        maxCombatEffects: 32,
      ),
    ),
    gameSize: Vector2(960, 540),
  );
  final cappedTalismanEffectGameTester = FlameTester<PixelSurvivorGame>(
    () => PixelSurvivorGame(
      playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
      onRunEnded: null,
      performanceBudget: const GamePerformanceBudget(
        maxEnemies: 96,
        maxProjectiles: 128,
        maxDamageNumbers: 24,
        maxCombatEffects: 1,
      ),
    ),
    gameSize: Vector2(960, 540),
  );

  group('PixelSurvivorGame run loop progression', () {
    gameTester.testGameWidget(
      'bright stage and actor shadows mount before representative combat',
      setUp: (game, _) async {
        final origin = game.activePlayers.single.position;
        for (final enemyId in [
          plagueRatSwarm,
          vengefulSpirit,
          sakkatSpecter,
          dokkaebi,
        ]) {
          game.debugSpawnEnemy(enemyId, position: origin + Vector2(80, 0));
        }
      },
      verify: (game, _) async {
        game.update(0);

        expect(game.children.whereType<StageBackdropComponent>(), hasLength(1));
        final shadows = game.children.whereType<ActorShadowComponent>().toList();
        expect(shadows, hasLength(5));
        expect(
          shadows.every((shadow) => shadow.priority < 0),
          isTrue,
        );
      },
    );
    test(
      'selected character keeps authored versus legacy player art',
      () async {
        final exorcistGame = PixelSurvivorGame(
          playerSlot: const PlayerSlot(index: 0, characterId: exorcistDosa),
          onRunEnded: null,
          loadVisualAssets: false,
        );
        exorcistGame.onGameResize(Vector2(960, 540));
        await exorcistGame.onLoad();

        expect(exorcistGame.activePlayers.single.characterId, exorcistDosa);
        expect(exorcistGame.activePlayers.single.usesAuthoredAtlas, isTrue);

        final legacyGame = PixelSurvivorGame(
          playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
          onRunEnded: null,
          loadVisualAssets: false,
        );
        legacyGame.onGameResize(Vector2(960, 540));
        await legacyGame.onLoad();

        expect(legacyGame.activePlayers.single.characterId, rookieConstable);
        expect(legacyGame.activePlayers.single.usesAuthoredAtlas, isFalse);
      },
    );

    test(
      'dead player never re-enters attack state from weapon updates',
      () async {
        final game = PixelSurvivorGame(
          playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
          onRunEnded: null,
          loadVisualAssets: false,
        );
        game.onGameResize(Vector2(960, 540));
        await game.onLoad();
        final player = game.activePlayers.single;

        player.takeDamage(player.currentHealth);
        game.update(0.05);

        expect(player.visualState, PlayerAnimationState.death);
        expect(player.isAttacking, isFalse);
      },
    );

    test('synergy presentation uses a golden slash and five O-bang colors', () {
      expect(AttackEffectComponent.synergySlashColor, const Color(0xffffd166));
      expect(AttackEffectComponent.synergyFragmentColors, hasLength(5));
      expect(AttackEffectComponent.synergyFragmentColors.toSet(), hasLength(5));
    });

    audioGameTester.testGameWidget(
      'sealing slash requires both weapons and exposes bounded presentation',
      setUp: (game, _) async {
        game.unlockedWeaponIds.add(talismanThrow);
        game.weaponSystem.upgrade(talismanThrow, game.unlockedWeaponIds);
        await game.ensureAdd(
          EnemyComponent(
            enemyId: bandit,
            maxHealth: 10000,
            moveSpeed: 0,
            damage: 0,
            position: game.activePlayers.single.position + Vector2(20, 0),
          ),
        );
      },
      verify: (game, _) async {
        for (var frame = 0; frame < 34; frame += 1) {
          game.update(.05);
        }

        expect(audioCues, contains(AudioCue.sealingSlash));
        expect(game.combatNotice, '봉마참');
        expect(game.combatNoticeSecondsRemaining, inInclusiveRange(0, 1.2));
        expect(
          game.children.whereType<AttackEffectComponent>().any(
            (effect) =>
                effect.instance.spec.id == sealingSlash &&
                effect.instance.spec.presentation == AttackPresentation.synergy,
          ),
          isTrue,
        );

        final result = game.runStats.toRunResult(
          outcome: RunOutcome.defeat,
          survivalSeconds: 1,
          level: 1,
          wonWithLowHealth: false,
          weaponLevels: game.weaponSystem.levels,
        );
        expect(result.weaponDamageTotals[sealingSlash], greaterThan(0));
        expect(
          result.weaponDamageTotals[hwandoSlash],
          isNot(result.weaponDamageTotals[sealingSlash]),
        );

        game.update(2);
        expect(game.combatNotice, isNull);

        for (var frame = 0; frame < 25; frame += 1) {
          game.update(.05);
        }
        expect(game.combatNotice, isNull);
        expect(game.combatNoticeSecondsRemaining, 0);
      },
    );

    gameTester.testGameWidget(
      'kill streak expires after one low-FPS wall frame',
      setUp: (game, _) async {
        final first = game.debugSpawnEnemy(bandit, position: Vector2(40, 40));
        final second = game.debugSpawnEnemy(bandit, position: Vector2(60, 40));
        game.update(0);
        for (final enemy in [first, second]) {
          game.debugApplyDamageEvent(
            DamageEvent(
              target: enemy,
              damage: enemy.currentHealth,
              knockback: 0,
              direction: Vector2.zero(),
              weaponId: hwandoSlash,
            ),
          );
        }
        game.update(0);
      },
      verify: (game, _) async {
        expect(game.killStreak, 2);
        game.update(2);
        expect(game.killStreak, 0);
      },
    );

    gameTester.testGameWidget(
      'hwando alone never activates sealing slash',
      setUp: (game, _) async {
        await game.ensureAdd(
          EnemyComponent(
            enemyId: bandit,
            maxHealth: 10000,
            moveSpeed: 0,
            damage: 0,
            position: game.activePlayers.single.position + Vector2(20, 0),
          ),
        );
      },
      verify: (game, _) async {
        for (var frame = 0; frame < 34; frame += 1) {
          game.update(.05);
        }

        expect(game.combatNotice, isNull);
        final result = game.runStats.toRunResult(
          outcome: RunOutcome.defeat,
          survivalSeconds: 2,
          level: 1,
          wonWithLowHealth: false,
          weaponLevels: game.weaponSystem.levels,
        );
        expect(result.weaponDamageTotals, isNot(contains(sealingSlash)));
      },
    );

    test('playtest construction opens every implemented base weapon', () {
      final game = PixelSurvivorGame(
        playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
        onRunEnded: null,
        contentPolicy: const PlaytestContentPolicy(unlockAllBaseWeapons: true),
      );

      expect(
        game.unlockedWeaponIds,
        weaponDefinitions.map((definition) => definition.id).toSet(),
      );
    });

    test('default construction keeps normal weapon availability', () {
      final game = PixelSurvivorGame(
        playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
        onRunEnded: null,
      );

      expect(
        game.unlockedWeaponIds,
        weaponDefinitions
            .where((definition) => definition.startsUnlocked)
            .map((definition) => definition.id)
            .toSet(),
      );
    });

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
      for (final choice in game.pendingLevelUpChoices.where(
        (choice) => choice.type == LevelUpChoiceType.weapon,
      )) {
        expect(
          game.currentRunResult().combatMetrics.weaponOfferCounts[choice.id],
          1,
        );
      }
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
      expect(game.currentRunResult().combatMetrics.weaponSelectionCounts, {
        hwandoSlash: 1,
      });
      expect(game.currentRunResult().combatMetrics.weaponLevelTimes, {
        hwandoSlash: {1: 0},
      });
    });

    test('rejected weapon choices do not record selections or level times', () {
      const firstLevel = LevelUpChoice(
        id: hwandoSlash,
        displayName: 'hwando',
        effectDescription: 'level one',
        type: LevelUpChoiceType.weapon,
        currentLevel: 0,
        nextLevel: 1,
      );
      final staleGame = newGame()..unlockedWeaponIds.add(hwandoSlash);
      staleGame
        ..applyLevelUpChoice(firstLevel)
        ..applyLevelUpChoice(firstLevel);
      expect(staleGame.weaponSystem.levelOf(hwandoSlash), 1);
      expect(staleGame.currentRunResult().combatMetrics.weaponSelectionCounts, {
        hwandoSlash: 1,
      });

      final maxedGame = newGame()..unlockedWeaponIds.add(hwandoSlash);
      for (var level = 0; level < 6; level += 1) {
        maxedGame.weaponSystem.upgrade(
          hwandoSlash,
          maxedGame.unlockedWeaponIds,
        );
      }
      maxedGame.applyLevelUpChoice(
        const LevelUpChoice(
          id: hwandoSlash,
          displayName: 'hwando',
          effectDescription: 'master',
          type: LevelUpChoiceType.weapon,
          currentLevel: 5,
          nextLevel: 6,
        ),
      );
      expect(
        maxedGame.currentRunResult().combatMetrics.weaponSelectionCounts,
        isEmpty,
      );

      final unknownGame = newGame();
      unknownGame.applyLevelUpChoice(
        const LevelUpChoice(
          id: 'unknown_weapon',
          displayName: 'unknown',
          effectDescription: 'unknown',
          type: LevelUpChoiceType.weapon,
          currentLevel: 0,
          nextLevel: 1,
        ),
      );
      expect(unknownGame.currentRunResult().choices, isEmpty);
      expect(
        unknownGame.currentRunResult().combatMetrics.weaponLevelTimes,
        isEmpty,
      );
      expect(unknownGame.unlockedWeaponIds, isNot(contains('unknown_weapon')));
    });

    test('combat metrics use raw frame dt before simulation clamping', () {
      final game = newGame()..debugAdvanceTo(180);

      game.update(.2);

      expect(game.currentRunResult().combatMetrics.lateMinFps, 5);
    });

    test('pending and finished updates do not record frame metrics', () {
      final pendingGame = newGame()..debugAdvanceTo(240);
      pendingGame.gainExperience(11);
      final beforePending = pendingGame.currentRunResult().combatMetrics;
      pendingGame.update(.2);
      expect(pendingGame.currentRunResult().combatMetrics, beforePending);

      final finishedGame = newGame()..debugAdvanceTo(240);
      finishedGame.debugKillPlayer();
      finishedGame.update(.016);
      final afterFinish = finishedGame.currentRunResult().combatMetrics;
      finishedGame.update(.2);
      expect(finishedGame.currentRunResult().combatMetrics, afterFinish);
    });

    audioGameTester.testGameWidget(
      'talisman master ward activation gets one mastery start feedback',
      setUp: (game, _) async {
        game.unlockedWeaponIds.add(talismanThrow);
        for (var level = 0; level < 6; level += 1) {
          game.weaponSystem.upgrade(talismanThrow, game.unlockedWeaponIds);
        }
        await game.ensureAdd(
          EnemyComponent.fromDefinition(
            enemyDefinitionFor(dokkaebi)!,
            position: game.activePlayers.single.position + Vector2(20, 0),
          ),
        );
      },
      verify: (game, _) async {
        expect(
          game.currentRunResult().combatMetrics.firstMasterAtSeconds,
          contains(talismanThrow),
        );
        expect(game.combatHitStopRemaining, .035);
        expect(
          audioCues.where((cue) => cue == AudioCue.talismanMasterAttack),
          hasLength(1),
        );
      },
    );

    gameTester.testGameWidget(
      'ordinary talisman explosion requests twenty milliseconds of hit stop',
      setUp: (game, _) async {
        game.unlockedWeaponIds.add(talismanThrow);
        game.weaponSystem.upgrade(talismanThrow, game.unlockedWeaponIds);
        await game.ensureAdd(
          EnemyComponent(
            enemyId: 'strong_feedback_target',
            maxHealth: 1000,
            moveSpeed: 0,
            damage: 0,
            position: game.activePlayers.single.position + Vector2(20, 0),
          ),
        );
      },
      verify: (game, _) async {
        expect(game.combatHitStopRemaining, .020);
      },
    );

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
      'ward collects its final tick at the exact expiration boundary',
      setUp: (game, _) async {
        final position = Vector2(100, 100);
        await game.ensureAdd(
          EnemyComponent(
            enemyId: bandit,
            maxHealth: 100,
            moveSpeed: 0,
            damage: 0,
            position: position,
          ),
        );
        await game.ensureAdd(
          FiveColorWardComponent(
            attack: wardAttack(position: position, duration: 1.5),
            tickSeconds: .5,
          ),
        );
      },
      verify: (game, _) async {
        final target = game.children.whereType<EnemyComponent>().singleWhere(
          (enemy) => enemy.enemyId == bandit,
        );
        for (var frame = 0; frame < 30; frame += 1) {
          game.update(.05);
        }

        expect(target.currentHealth, 88);
      },
    );

    gameTester.testGameWidget(
      'ward and frost apply only their strongest slow',
      setUp: (game, _) async {
        final position = Vector2(100, 100);
        await game.ensureAdd(
          EnemyComponent(
            enemyId: bandit,
            maxHealth: 100,
            moveSpeed: 100,
            damage: 0,
            position: position,
          ),
        );
        await game.ensureAdd(
          FrostFieldComponent(
            weaponId: frostFlask,
            damage: 0,
            radius: 40,
            durationSeconds: 2,
            slowFraction: .2,
            knockback: 0,
            position: position,
          ),
        );
        await game.ensureAdd(
          FiveColorWardComponent(
            attack: wardAttack(position: position, duration: 2, slow: .35),
          ),
        );
      },
      verify: (game, _) async {
        game.update(.05);
        final target = game.children.whereType<EnemyComponent>().singleWhere(
          (enemy) => enemy.enemyId == bandit,
        );

        expect(target.environmentalSlowFraction, .35);
      },
    );

    gameTester.testGameWidget(
      'removed talisman targets are cleaned up in the live loop',
      setUp: (game, _) async {
        game.unlockedWeaponIds.add(talismanThrow);
        for (var level = 0; level < 3; level += 1) {
          game.weaponSystem.upgrade(talismanThrow, game.unlockedWeaponIds);
        }
        await game.ensureAdd(
          EnemyComponent(
            enemyId: bandit,
            maxHealth: 100,
            moveSpeed: 0,
            damage: 0,
            position: game.activePlayers.single.position + Vector2(20, 0),
          ),
        );
      },
      verify: (game, _) async {
        game.update(.05);
        final target = game.weaponSystem.attachedTalismans.single.target;
        final mark = game.children
            .whereType<TalismanAttachmentComponent>()
            .single;
        expect(mark.seal.target, same(target));
        target.removeFromParent();
        game.update(.05);
        game.processLifecycleEvents();

        expect(game.weaponSystem.attachedTalismans, isEmpty);
        expect(game.children.whereType<TalismanAttachmentComponent>(), isEmpty);
      },
    );

    gameTester.testGameWidget(
      'live transfer skips a living target that already has a seal',
      setUp: (game, _) async {
        game.unlockedWeaponIds.add(talismanThrow);
        for (var level = 0; level < 4; level += 1) {
          game.weaponSystem.upgrade(talismanThrow, game.unlockedWeaponIds);
        }
        final origin = game.activePlayers.single.position;
        for (final entry in [(bandit, 20.0), (dokkaebi, 24.0)]) {
          await game.ensureAdd(
            EnemyComponent(
              enemyId: entry.$1,
              maxHealth: 1000,
              moveSpeed: 0,
              damage: 0,
              position: origin + Vector2(entry.$2, 0),
            ),
          );
        }
      },
      verify: (game, _) async {
        game.update(.05);
        final origin = game.activePlayers.single.position;
        final candidate = EnemyComponent(
          enemyId: vengefulSpirit,
          maxHealth: 1000,
          moveSpeed: 0,
          damage: 0,
          position: origin + Vector2(28, 0),
        );
        game.add(candidate);
        game.processLifecycleEvents();
        for (var frame = 0; frame < 12; frame += 1) {
          game.update(.05);
        }

        expect(
          game.weaponSystem.attachedTalismans.any(
            (seal) =>
                identical(seal.target, candidate) && seal.transferDepth == 1,
          ),
          isTrue,
        );
        expect(
          game.children.whereType<TalismanTransferCueComponent>(),
          isNotEmpty,
        );
        expect(
          game.children.whereType<TalismanAttachmentComponent>().length,
          lessThanOrEqualTo(TalismanExecutor.maxAttachedSeals),
        );
      },
    );

    cappedTalismanEffectGameTester.testGameWidget(
      'simultaneous talisman transfers share the combat effect cap',
      setUp: (game, _) async {
        game.unlockedWeaponIds.add(talismanThrow);
        for (var level = 0; level < 4; level += 1) {
          game.weaponSystem.upgrade(talismanThrow, game.unlockedWeaponIds);
        }
        final origin = game.activePlayers.single.position;
        for (var index = 0; index < 8; index += 1) {
          await game.ensureAdd(
            EnemyComponent(
              enemyId: 'transfer_cap_$index',
              maxHealth: 10000,
              moveSpeed: 0,
              damage: 0,
              position: origin + Vector2(20 + index * 5.0, 0),
            ),
          );
        }
      },
      verify: (game, _) async {
        for (var frame = 0; frame < 13; frame += 1) {
          game.update(.05);
          game.processLifecycleEvents();
        }

        expect(
          game.children.whereType<TalismanTransferCueComponent>().length,
          lessThanOrEqualTo(1),
        );
        expect(
          game.performanceSnapshot.counts[GamePopulationKind.combatEffect],
          lessThanOrEqualTo(1),
        );
        expect(
          game.performanceSnapshot.rejected[GamePopulationKind.combatEffect],
          39,
        );
      },
    );

    gameTester.testGameWidget(
      'talisman explosion applies spirit bonus per damaged target',
      setUp: (game, _) async {
        game.unlockedWeaponIds.add(talismanThrow);
        game.weaponSystem.upgrade(talismanThrow, game.unlockedWeaponIds);
        final origin = game.activePlayers.single.position;
        await game.ensureAdd(
          EnemyComponent(
            enemyId: bandit,
            maxHealth: 100,
            moveSpeed: 0,
            damage: 0,
            position: origin + Vector2(20, 0),
          ),
        );
        await game.ensureAdd(
          EnemyComponent(
            enemyId: vengefulSpirit,
            maxHealth: 100,
            moveSpeed: 0,
            damage: 0,
            position: origin + Vector2(22, 0),
          ),
        );
      },
      verify: (game, _) async {
        game.update(.05);
        final targets = game.children.whereType<EnemyComponent>();
        final ordinary = targets.singleWhere(
          (enemy) => enemy.enemyId == bandit,
        );
        final spirit = targets.singleWhere(
          (enemy) => enemy.enemyId == vengefulSpirit,
        );

        expect(ordinary.currentHealth, 92);
        expect(spirit.currentHealth, 90);
      },
    );

    audioGameTester.testGameWidget(
      'simultaneous level six seal explosions do not repeat master audio',
      setUp: (game, _) async {
        game.unlockedWeaponIds.add(talismanThrow);
        for (var level = 0; level < 6; level += 1) {
          game.weaponSystem.upgrade(talismanThrow, game.unlockedWeaponIds);
        }
        final origin = game.activePlayers.single.position;
        for (var index = 0; index < 6; index += 1) {
          await game.ensureAdd(
            EnemyComponent(
              enemyId: 'master_target_$index',
              maxHealth: 10000,
              moveSpeed: 0,
              damage: 0,
              position: origin + Vector2(20 + index * 4.0, 0),
            ),
          );
        }
      },
      verify: (game, _) async {
        for (var frame = 0; frame < 13; frame += 1) {
          game.update(.05);
        }

        expect(
          audioCues.where((cue) => cue == AudioCue.talismanMasterAttack),
          hasLength(1),
        );
      },
    );

    audioGameTester.testGameWidget(
      'later seal explosion and master ward activation emit one master cue',
      setUp: (game, _) async {
        game.unlockedWeaponIds.add(talismanThrow);
        for (var level = 0; level < 6; level += 1) {
          game.weaponSystem.upgrade(talismanThrow, game.unlockedWeaponIds);
        }
        final origin = game.activePlayers.single.position;
        for (var index = 0; index < 12; index += 1) {
          await game.ensureAdd(
            EnemyComponent(
              enemyId: 'coincident_target_$index',
              maxHealth: 100000,
              moveSpeed: 0,
              damage: 0,
              position: origin + Vector2(20 + index * 5.0, 0),
            ),
          );
        }
      },
      verify: (game, _) async {
        for (var frame = 0; frame < 35; frame += 1) {
          game.update(.05);
        }
        expect(
          audioCues.where((cue) => cue == AudioCue.talismanMasterAttack),
          hasLength(2),
        );

        final ordinaryBefore = audioCues
            .where((cue) => cue == AudioCue.talismanAttack)
            .length;
        for (var frame = 0; frame < 100; frame += 1) {
          if (audioCues
                  .where((cue) => cue == AudioCue.talismanMasterAttack)
                  .length ==
              3) {
            break;
          }
          game.update(.05);
        }

        expect(
          audioCues.where((cue) => cue == AudioCue.talismanMasterAttack),
          hasLength(3),
        );
        expect(
          audioCues.where((cue) => cue == AudioCue.talismanAttack).length,
          ordinaryBefore + 1,
        );
      },
    );

    gameTester.testGameWidget(
      'live talisman wards retain runtime caps',
      setUp: (game, _) async {
        game.unlockedWeaponIds.add(talismanThrow);
        for (var level = 0; level < 6; level += 1) {
          game.weaponSystem.upgrade(talismanThrow, game.unlockedWeaponIds);
        }
        final origin = game.activePlayers.single.position;
        for (var index = 0; index < 18; index += 1) {
          await game.ensureAdd(
            EnemyComponent(
              enemyId: 'cap_target_$index',
              maxHealth: 100000,
              moveSpeed: 0,
              damage: 0,
              position:
                  origin + Vector2((index ~/ 6) * 85.0 + 20, (index % 6) * 6.0),
            ),
          );
        }
      },
      verify: (game, _) async {
        for (var frame = 0; frame < 100; frame += 1) {
          game.update(.05);
          final wards = game.children.whereType<FiveColorWardComponent>();
          expect(
            wards
                .where(
                  (ward) =>
                      ward.attack.spec.presentation ==
                      AttackPresentation.master,
                )
                .length,
            lessThanOrEqualTo(3),
          );
          expect(
            wards
                .where(
                  (ward) =>
                      ward.attack.spec.presentation !=
                      AttackPresentation.master,
                )
                .length,
            lessThanOrEqualTo(12),
          );
        }
      },
    );

    gameTester.testGameWidget(
      'player keeps moving during an automatic hwando attack',
      setUp: (game, _) async {
        final player = game.activePlayers.single;
        await game.ensureAdd(
          EnemyComponent(
            enemyId: 'movement_target',
            maxHealth: 1000,
            moveSpeed: 0,
            damage: 0,
            position: player.position + Vector2(30, 0),
          ),
        );
        game.updateMovementInput(const VectorInput(1, 0));
      },
      verify: (game, _) async {
        final player = game.activePlayers.single;
        final before = player.position.x;

        game.update(.05);

        expect(player.position.x, greaterThan(before));
        expect(player.isMoving, isTrue);
        expect(player.isAttacking, isTrue);
      },
    );

    masterGameTester.testGameWidget(
      'hwando mastery enhances only sequence start and finish',
      verify: (game, _) async {
        game.update(0);
        final effect = game.children.whereType<AttackEffectComponent>().single;
        final enemies = game.children.whereType<EnemyComponent>().toList();
        final expected = enemies
            .where(
              (enemy) => AttackGeometry.contains(
                effect.instance,
                enemy.position,
                enemy.size.x / 2,
              ),
            )
            .toSet();
        final damaged = enemies
            .where((enemy) => enemy.currentHealth < enemy.maxHealth)
            .toSet();

        expect(damaged, expected);
        expect(effect.instance.isCritical, isFalse);
        expect(
          damaged.single.maxHealth - damaged.single.currentHealth,
          effect.instance.spec.damage,
        );
        expect(
          game.children.whereType<CombatEffectComponent>().single.kind,
          CombatEffectKind.hit,
        );
        expect(game.combatHitStopRemaining, .035);
        var masteryFeedbackBeats = 1;
        game.update(game.combatHitStopRemaining);

        for (
          var frame = 0;
          frame < 20 && masteryFeedbackBeats < 2;
          frame += 1
        ) {
          game.update(.05);
          if (game.combatHitStopRemaining > 0) {
            expect(game.combatHitStopRemaining, .035);
            masteryFeedbackBeats += 1;
          }
        }

        expect(masteryFeedbackBeats, 2);
        expect(game.combatHitStopRemaining, .035);
        expect(
          audioCues.where((cue) => cue == AudioCue.hwandoMasterAttack),
          hasLength(1),
        );
      },
    );

    criticalMasterGameTester.testGameWidget(
      'critical chance one doubles shared hwando damage and feedback',
      verify: (game, _) async {
        game.update(.05);
        game.update(0);
        final attack = game.children.whereType<AttackEffectComponent>().single;
        final enemy = game.children.whereType<EnemyComponent>().single;

        expect(attack.instance.isCritical, isTrue);
        expect(
          enemy.maxHealth - enemy.currentHealth,
          attack.instance.spec.damage * 2,
        );
        expect(
          game.children.whereType<CombatEffectComponent>().single.kind,
          CombatEffectKind.critical,
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

    gameTester.testGameWidget(
      'sakkat projectile damages player once and is removed',
      setUp: (game, _) async {
        final player = game.activePlayers.single;
        game.debugSpawnEnemy(
          sakkatSpecter,
          position: player.position + Vector2(180, 0),
        );
      },
      verify: (game, _) async {
        final player = game.activePlayers.single;
        final healthBefore = player.currentHealth;
        for (var i = 0; i < 60; i++) {
          game.update(.05);
        }
        expect(player.currentHealth, lessThan(healthBefore));
        expect(game.children.whereType<EnemyProjectileComponent>(), isEmpty);
      },
    );

    cappedProjectileGameTester.testGameWidget(
      'hostile projectiles share the projectile population cap',
      setUp: (game, _) async {
        final player = game.activePlayers.single;
        game.debugSpawnEnemy(
          sakkatSpecter,
          position: player.position + Vector2(180, -40),
        );
        game.debugSpawnEnemy(
          sakkatSpecter,
          position: player.position + Vector2(180, 40),
        );
      },
      verify: (game, _) async {
        for (var i = 0; i < 70; i++) {
          game.update(.05);
        }
        expect(
          game.children.whereType<EnemyProjectileComponent>().length,
          lessThanOrEqualTo(1),
        );
        expect(
          game.performanceSnapshot.counts[GamePopulationKind.projectile],
          lessThanOrEqualTo(1),
        );
      },
    );

    mixedProjectileGameTester.testGameWidget(
      'player and hostile same-frame projectiles share one admission budget',
      setUp: (game, _) async {
        final player = game.activePlayers.single;
        final enemy = game.debugSpawnEnemy(
          sakkatSpecter,
          position: player.position + Vector2(180, 0),
        );
        enemy.update(3.3);
      },
      verify: (game, _) async {
        game.update(.05);
        game.update(0);

        final playerProjectiles = game.children
            .whereType<ProjectileComponent>()
            .length;
        final hostileProjectiles = game.children
            .whereType<EnemyProjectileComponent>()
            .length;
        expect(playerProjectiles + hostileProjectiles, 1);
        expect(
          game.performanceSnapshot.counts[GamePopulationKind.projectile],
          1,
        );
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

    test(
      'piercing projectile receives the lighter frontal reduction',
      () async {
        final game = newGame();
        game.onGameResize(Vector2(960, 540));
        await game.onLoad();
        final enemy = EnemyComponent.fromDefinition(
          enemyDefinitionFor(dokkaebi)!,
          position: Vector2(40, 40),
        )..debugFace(Vector2(1, 0));
        await game.add(enemy);
        await game.add(
          ProjectileComponent(
            weaponId: gakgungShot,
            damage: 10,
            position: enemy.position + Vector2(5, 0),
            velocity: Vector2.zero(),
            pierce: 1,
          ),
        );

        game.update(0);

        expect(enemy.currentHealth, 30);
      },
    );

    test('area attack explosion bypasses frontal tank defense', () async {
      final game = newGame();
      game.onGameResize(Vector2(960, 540));
      await game.onLoad();
      final enemy = EnemyComponent.fromDefinition(
        enemyDefinitionFor(dokkaebi)!,
        position: Vector2(40, 40),
      )..debugFace(Vector2(1, 0));
      await game.add(enemy);
      await game.add(
        AreaAttackComponent(
          weaponId: thunderCrashBomb,
          damage: 10,
          radius: 20,
          delaySeconds: 0,
          knockback: 0,
          position: enemy.position + Vector2(5, 0),
        ),
      );

      game.update(0);

      expect(enemy.currentHealth, 28);
    });

    test('damage number and telemetry report effective health loss', () async {
      final game = newGame();
      game.onGameResize(Vector2(960, 540));
      await game.onLoad();
      final enemy = EnemyComponent.fromDefinition(
        enemyDefinitionFor(dokkaebi)!,
        position: Vector2(40, 40),
      )..debugFace(Vector2(1, 0));
      await game.add(enemy);

      game.debugApplyDamageEvent(
        DamageEvent(
          target: enemy,
          damage: 10,
          knockback: 0,
          direction: Vector2(-1, 0),
          weaponId: gakgungShot,
          sourceId: 'critical_test',
          isCritical: true,
          traits: const {AttackTrait.projectile},
        ),
      );
      game.processLifecycleEvents();

      final number = game.children.whereType<DamageNumberComponent>().single;
      expect(enemy.currentHealth, 33);
      expect(number.damage, 5);
      expect(number.isCritical, isTrue);
      expect(game.currentRunResult().weaponDamageTotals[gakgungShot], 5);
      expect(
        game.children.whereType<ShieldBlockEffectComponent>(),
        hasLength(1),
      );
      expect(game.children.whereType<CombatEffectComponent>(), isEmpty);
    });

    test(
      'spawned enemy warning overlay outranks attacks without raising body',
      () async {
        final game = newGame();
        game.onGameResize(Vector2(960, 540));
        await game.onLoad();
        final enemy = game.debugSpawnEnemy(
          plagueCrow,
          position: Vector2(40, 40),
        );
        game.processLifecycleEvents();
        final overlay = game.children
            .whereType<EnemyWarningOverlayComponent>()
            .singleWhere((item) => identical(item.enemy, enemy));

        expect(enemy.priority, lessThan(AttackPresentationPriority.attack));
        expect(
          overlay.priority,
          greaterThan(AttackPresentationPriority.attack),
        );
      },
    );

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
