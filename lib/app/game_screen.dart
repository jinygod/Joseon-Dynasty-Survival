import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game_hud.dart';
import 'level_up_overlay.dart';
import '../game/models/player_slot.dart';
import '../game/pixel_survivor_game.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final PixelSurvivorGame _game;

  @override
  void initState() {
    super.initState();
    _game = PixelSurvivorGame(
      playerSlots: const [
        PlayerSlot(index: 0, characterId: 'rookie_constable'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GameWidget<PixelSurvivorGame>(
      game: _game,
      overlayBuilderMap: {
        'hud': (_, game) => GameHud(game: game),
        PixelSurvivorGame.levelUpOverlayId: (_, game) => LevelUpOverlay(
          choices: game.pendingLevelUpChoices,
          onChoiceSelected: game.applyLevelUpChoice,
        ),
      },
      initialActiveOverlays: const ['hud'],
    );
  }
}
