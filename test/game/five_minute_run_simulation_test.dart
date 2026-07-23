import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/models/player_slot.dart';
import 'package:pixel_survivor/game/models/run_outcome.dart';
import 'package:pixel_survivor/game/pixel_survivor_game.dart';

void main() {
  test(
    'fixed-seed five-minute boundary has one boss and bounded enemies',
    () async {
      final game = PixelSurvivorGame(
        playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
        random: Random(7),
        onRunEnded: null,
        loadVisualAssets: false,
      );
      game.onGameResize(Vector2(960, 540));
      await game.onLoad();

      game.debugAdvanceTo(270);
      game.debugAdvanceTo(300);

      expect(game.elapsedSeconds, 300);
      expect(game.bossRequestCount, 1);
      expect(game.bossSpawnCount, 1);
      expect(game.enemyCount, lessThanOrEqualTo(game.currentEnemyCap));
      expect(game.runOutcome, RunOutcome.inProgress);
      expect(game.weaponLevelLabels, isNotEmpty);
      expect(game.debugPopulationIndexIsConsistent(), isTrue);
    },
  );

  test(
    'stage visual seed does not alter the fixed-seed five-minute run',
    () async {
      Future<PixelSurvivorGame> loadGame(int stageVisualSeed) async {
        final game = PixelSurvivorGame(
          playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
          random: Random(7),
          onRunEnded: null,
          stageVisualSeed: stageVisualSeed,
          loadVisualAssets: false,
        );
        game.onGameResize(Vector2(960, 540));
        await game.onLoad();
        return game;
      }

      final first = await loadGame(101);
      final second = await loadGame(202);

      for (final secondMark in [270.0, 300.0]) {
        first.debugAdvanceTo(secondMark);
        second.debugAdvanceTo(secondMark);
      }

      expect(first.elapsedSeconds, second.elapsedSeconds);
      expect(first.bossRequestCount, second.bossRequestCount);
      expect(first.bossSpawnCount, second.bossSpawnCount);
      expect(first.currentEnemyCap, second.currentEnemyCap);
      expect(first.enemyCount, second.enemyCount);
      expect(first.runOutcome, second.runOutcome);
      expect(first.weaponLevelLabels, second.weaponLevelLabels);
      expect(first.weaponSystem.levels, second.weaponSystem.levels);
      expect(first.debugPopulationIndexIsConsistent(), isTrue);
      expect(second.debugPopulationIndexIsConsistent(), isTrue);
      expect(
        first.children
            .whereType<EnemyComponent>()
            .where((enemy) => !enemy.isDead)
            .map(
              (enemy) => (enemy.enemyId, enemy.position.x, enemy.position.y),
            ),
        orderedEquals(
          second.children
              .whereType<EnemyComponent>()
              .where((enemy) => !enemy.isDead)
              .map(
                (enemy) => (enemy.enemyId, enemy.position.x, enemy.position.y),
              ),
        ),
      );
    },
  );
}
