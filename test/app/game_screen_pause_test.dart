import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/game_screen.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';
import 'package:pixel_survivor/game/audio/audio_settings_controller.dart';
import 'package:pixel_survivor/game/audio/audio_settings_repository.dart';
import 'package:pixel_survivor/game/models/player_slot.dart';
import 'package:pixel_survivor/game/models/vector_input.dart';
import 'package:pixel_survivor/game/pixel_survivor_game.dart';
import 'package:pixel_survivor/game/systems/tutorial_progress_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('HUD pause clears input and can explicitly resume', (
    tester,
  ) async {
    final game = _game();
    await tester.pumpWidget(MaterialApp(home: GameScreen(game: game)));
    await tester.pump();
    game.updateMovementInput(const VectorInput(1, 0));

    await tester.tap(find.byKey(const Key('hud-pause')));
    await tester.pump();

    expect(game.paused, isTrue);
    expect(game.movementInput, same(VectorInput.zero));
    expect(find.byKey(const Key('pause-resume')), findsOneWidget);

    await tester.tap(find.byKey(const Key('pause-resume')));
    await tester.pump();
    expect(game.paused, isFalse);
    expect(find.byKey(const Key('pause-resume')), findsNothing);
  });

  testWidgets('background pause never auto-resumes on foreground', (
    tester,
  ) async {
    final game = _game();
    await tester.pumpWidget(MaterialApp(home: GameScreen(game: game)));
    await tester.pump();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(game.paused, isTrue);
    expect(find.byKey(const Key('pause-resume')), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(game.paused, isTrue);
    expect(find.byKey(const Key('pause-resume')), findsOneWidget);
  });

  testWidgets('system back pauses instead of leaving an active run', (
    tester,
  ) async {
    final game = _game();
    await tester.pumpWidget(MaterialApp(home: GameScreen(game: game)));
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(game.paused, isTrue);
    expect(find.byKey(const Key('pause-resume')), findsOneWidget);
    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets('first-run tutorial pauses, persists, and explicitly resumes', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = TutorialProgressRepository(preferences: preferences);
    final game = _game();
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          game: game,
          showFirstRunTutorial: true,
          tutorialProgressRepository: repository,
        ),
      ),
    );
    await tester.pump();

    expect(game.paused, isTrue);
    expect(find.byKey(const Key('tutorial-skip')), findsOneWidget);

    await tester.tap(find.byKey(const Key('tutorial-skip')));
    await tester.pump();

    expect(await repository.isCompleted(), isTrue);
    expect(game.paused, isFalse);
    expect(find.byKey(const Key('tutorial-skip')), findsNothing);
  });

  testWidgets('pause restart preserves the selected character slot', (
    tester,
  ) async {
    const slot = PlayerSlot(index: 0, characterId: exorcistDosa);
    await tester.pumpWidget(
      const MaterialApp(
        home: GameScreen(playerSlot: slot, stageId: moonlitAbandonedOffice),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('hud-pause')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('pause-restart')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final gameWidgets = tester.widgetList<GameWidget<PixelSurvivorGame>>(
      find.byType(GameWidget<PixelSurvivorGame>),
    );
    expect(gameWidgets, isNotEmpty);
    expect(
      gameWidgets.every(
        (widget) => widget.game!.playerSlot.characterId == exorcistDosa,
      ),
      isTrue,
    );
    final screens = tester.widgetList<GameScreen>(find.byType(GameScreen));
    expect(
      screens.every((screen) => screen.stageId == moonlitAbandonedOffice),
      isTrue,
    );
  });

  testWidgets('game screen loads persisted audio settings', (tester) async {
    SharedPreferences.setMockInitialValues({
      AudioSettingsRepository.musicVolumeKey: 0.2,
      AudioSettingsRepository.sfxVolumeKey: 0.4,
      AudioSettingsRepository.vibrationEnabledKey: false,
    });
    final game = _game();
    await tester.pumpWidget(MaterialApp(home: GameScreen(game: game)));
    await tester.pump();

    await tester.tap(find.byKey(const Key('hud-pause')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('pause-settings')));
    await tester.pump();

    expect(find.text('음악 20%'), findsOneWidget);
    expect(find.text('효과음 40%'), findsOneWidget);
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('audio-vibration')))
          .value,
      isFalse,
    );
  });

  testWidgets('game screen does not dispose an injected settings controller', (
    tester,
  ) async {
    final controller = AudioSettingsController(
      store: AudioSettingsRepository(
        preferences: await SharedPreferences.getInstance(),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(game: _game(), audioSettingsController: controller),
      ),
    );
    await tester.pumpWidget(const SizedBox());

    await controller.setMusicVolume(0.3);
    expect(controller.settings.musicVolume, 0.3);
    controller.dispose();
  });
}

PixelSurvivorGame _game() {
  return PixelSurvivorGame(
    playerSlot: const PlayerSlot(index: 0, characterId: 'rookie_constable'),
    onRunEnded: null,
  );
}
