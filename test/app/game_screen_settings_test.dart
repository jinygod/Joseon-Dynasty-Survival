import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/game_settings.dart';
import 'package:pixel_survivor/app/game_settings_controller.dart';
import 'package:pixel_survivor/app/game_settings_repository.dart';
import 'package:pixel_survivor/app/game_screen.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/models/player_slot.dart';
import 'package:pixel_survivor/game/pixel_survivor_game.dart';

void main() {
  testWidgets('controller changes update active game feedback and HUD scale', (
    tester,
  ) async {
    final controller = GameSettingsController(store: _MemoryStore());
    final game = PixelSurvivorGame(
      playerSlot: const PlayerSlot(index: 0, characterId: rookieConstable),
      onRunEnded: null,
    );
    game.onGameResize(Vector2(960, 540));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: GameScreen(game: game, audioSettingsController: controller),
      ),
    );
    await tester.pump();

    await controller.setScreenShakeEnabled(false);
    await controller.setDamageNumbersEnabled(false);
    await controller.setUiScale(UiScale.large);
    await tester.pump();

    expect(game.screenShakeEnabled, isFalse);
    expect(game.damageNumbersEnabled, isFalse);
    expect(find.byKey(const Key('hud-ui-scale')), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('virtual-joystick'))),
      const Size.square(104),
    );
  });
}

class _MemoryStore implements GameSettingsStore {
  GameSettings value = GameSettings.defaults;

  @override
  Future<GameSettings> load() async => value;

  @override
  Future<void> save(GameSettings settings) async => value = settings;
}
