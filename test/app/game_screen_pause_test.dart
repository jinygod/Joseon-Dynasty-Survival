import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/game_screen.dart';
import 'package:pixel_survivor/app/pause_menu_overlay.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';
import 'package:pixel_survivor/game/audio/audio_settings_controller.dart';
import 'package:pixel_survivor/game/audio/audio_settings_repository.dart';
import 'package:pixel_survivor/game/audio/game_audio_service.dart';
import 'package:pixel_survivor/game/models/player_slot.dart';
import 'package:pixel_survivor/game/models/vector_input.dart';
import 'package:pixel_survivor/game/pixel_survivor_game.dart';
import 'package:pixel_survivor/game/systems/tutorial_progress_repository.dart';
import 'package:pixel_survivor/game/systems/playtest_session_repository.dart';
import 'package:pixel_survivor/game/systems/meta_progression_service.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/recording_audio_backend.dart';

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

  testWidgets('pause and resume forward the audio lifecycle', (tester) async {
    final backend = RecordingAudioBackend();
    final audio = GameAudioService(backend: backend);
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(game: _game(), audioService: audio),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('hud-pause')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('pause-resume')));
    await tester.pump();

    expect(backend.commands, ['pauseAll', 'resumeAll']);
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
        home: GameScreen(
          playerSlot: slot,
          stageId: moonlitAbandonedOffice,
          loadVisualAssets: false,
        ),
      ),
    );
    await _pumpUntil(
      tester,
      () => find.byKey(const Key('hud-pause')).evaluate().isNotEmpty,
    );

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

  testWidgets('rapid duplicate pause restart starts exactly one new run', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final sessions = PlaytestSessionRepository(preferences: preferences);
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          playtestSessionRepository: sessions,
          loadVisualAssets: false,
        ),
      ),
    );
    await _pumpUntil(
      tester,
      () => find.byKey(const Key('hud-pause')).evaluate().isNotEmpty,
    );

    await tester.tap(find.byKey(const Key('hud-pause')));
    await tester.pump();
    final pause = tester.widget<PauseMenuOverlay>(
      find.byType(PauseMenuOverlay),
    );
    pause.onRestart();
    pause.onRestart();

    await _pumpUntil(
      tester,
      () => find.byType(GameScreen).evaluate().length == 1,
    );
    await _pumpUntil(tester, () async => await sessions.loadRunCount() == 2);
    expect(await sessions.loadRunCount(), 2);
  });

  testWidgets('late boss availability does not mutate a disposed game', (
    tester,
  ) async {
    final store = _DelayedSaveStore();
    final game = _game()..firstBossRewardAvailable = false;
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          game: game,
          metaProgressionService: MetaProgressionService(saveStore: store),
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    store.release.complete(SaveState.defaults());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    expect(game.firstBossRewardAvailable, isFalse);
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

Future<void> _pumpUntil(
  WidgetTester tester,
  FutureOr<bool> Function() condition,
) async {
  for (var attempt = 0; attempt < 120; attempt += 1) {
    if (await condition()) return;
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 16));
  }
  fail('Timed out waiting for condition');
}

class _DelayedSaveStore implements SaveStore {
  final release = Completer<SaveState>();

  @override
  Future<SaveState> load() => release.future;

  @override
  Future<void> save(SaveState state) async {}
}

PixelSurvivorGame _game() {
  return PixelSurvivorGame(
    playerSlot: const PlayerSlot(index: 0, characterId: 'rookie_constable'),
    onRunEnded: null,
    loadVisualAssets: false,
  );
}
