import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
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
    },
  );
}
