import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/painting.dart';

import 'models/player_slot.dart';

class PixelSurvivorGame extends FlameGame {
  PixelSurvivorGame({required List<PlayerSlot> playerSlots})
    : playerSlots = List.unmodifiable(playerSlots) {
    if (this.playerSlots.isEmpty) {
      throw ArgumentError.value(
        playerSlots,
        'playerSlots',
        'must not be empty',
      );
    }
  }

  final List<PlayerSlot> playerSlots;

  @override
  Color backgroundColor() => const Color(0xff101820);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    camera.viewfinder.anchor = Anchor.center;

    await add(
      TextComponent(
        text: 'Joseon Dynasty Survival',
        anchor: Anchor.center,
        position: size / 2,
        textRenderer: TextPaint(
          style: const TextStyle(
            color: Color(0xfff4ead2),
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
