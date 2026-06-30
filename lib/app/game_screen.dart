import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/models/player_slot.dart';
import '../game/pixel_survivor_game.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GameWidget(
      game: PixelSurvivorGame(
        playerSlots: const [
          PlayerSlot(index: 0, characterId: 'rookie_constable'),
        ],
      ),
    );
  }
}
