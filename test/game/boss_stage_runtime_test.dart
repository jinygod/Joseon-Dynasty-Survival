import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/boss_definitions.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';
import 'package:pixel_survivor/game/models/player_slot.dart';
import 'package:pixel_survivor/game/pixel_survivor_game.dart';

void main() {
  Future<PixelSurvivorGame> spawnBoss({
    required String stageId,
    required double roll,
  }) async {
    final game = PixelSurvivorGame(
      playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
      stageId: stageId,
      bossRoll: () => roll,
      random: Random(7),
      onRunEnded: null,
    );
    game.onGameResize(Vector2(960, 540));
    await game.onLoad();
    game.debugAdvanceTo(270);
    return game;
  }

  test('moonlit runs can spawn the fallen general', () async {
    final game = await spawnBoss(stageId: moonlitAbandonedOffice, roll: 0);

    expect(game.bossId, fallenGeneral);
  });

  test('moonlit runs can spawn the masked executioner', () async {
    final game = await spawnBoss(stageId: moonlitAbandonedOffice, roll: 0.99);

    expect(game.bossId, maskedExecutioner);
  });

  test('plague market runs spawn the plague magistrate', () async {
    final game = await spawnBoss(stageId: plagueMarket, roll: 0.5);

    expect(game.bossId, plagueMagistrate);
  });
}
