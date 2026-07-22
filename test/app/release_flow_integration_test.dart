import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/game_screen.dart';
import 'package:pixel_survivor/app/level_up_overlay.dart';
import 'package:pixel_survivor/app/lobby_controller.dart';
import 'package:pixel_survivor/app/lobby_screen.dart';
import 'package:pixel_survivor/app/run_summary_screen.dart';
import 'package:pixel_survivor/game/audio/audio_settings.dart';
import 'package:pixel_survivor/game/audio/audio_settings_controller.dart';
import 'package:pixel_survivor/game/audio/audio_settings_repository.dart';
import 'package:pixel_survivor/game/pixel_survivor_game.dart';
import 'package:pixel_survivor/game/models/run_outcome.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';
import 'package:pixel_survivor/game/systems/tutorial_progress_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'menu character stage game level-up result and retry form one flow',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(960, 540);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      SharedPreferences.setMockInitialValues({
        'first_run_tutorial_completed': true,
      });
      final preferences = await SharedPreferences.getInstance();
      final saveStore = _MemorySaveStore(SaveState.defaults());
      final lobbyController = LobbyController(store: saveStore);
      final settingsController = AudioSettingsController(
        store: _MemoryAudioSettingsStore(),
      );
      addTearDown(lobbyController.dispose);
      addTearDown(settingsController.dispose);
      await lobbyController.load();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(splashFactory: NoSplash.splashFactory),
          home: LobbyScreen(
            controller: lobbyController,
            audioSettingsController: settingsController,
            tutorialProgressRepository: TutorialProgressRepository(
              preferences: preferences,
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('lobby-character')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('character-confirm')), findsOneWidget);
      await tester.tap(find.byKey(const Key('character-confirm')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('lobby-stage')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('stage-confirm')), findsOneWidget);
      await tester.tap(find.byKey(const Key('stage-confirm')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('lobby-deploy')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(GameScreen), findsOneWidget);
      final firstGame = _activeGame(tester);
      await tester.runAsync(firstGame.ready);

      expect(firstGame.gainExperience(11), isTrue);
      await tester.pump();
      expect(find.byType(LevelUpOverlay), findsOneWidget);
      await tester.tap(
        find
            .descendant(
              of: find.byType(LevelUpOverlay),
              matching: find.byType(FilledButton),
            )
            .first,
      );
      await tester.pump();
      expect(firstGame.playerLevel, 2);
      expect(firstGame.isLevelUpPending, isFalse);

      firstGame.debugKillPlayer();
      firstGame.update(.016);
      expect(firstGame.runOutcome, RunOutcome.defeat);
      await tester.pump();
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      for (var attempt = 0; attempt < 20; attempt += 1) {
        if (find.byType(RunSummaryScreen).evaluate().isNotEmpty) break;
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(RunSummaryScreen), findsOneWidget);

      final retryButton = find.byKey(const Key('result-retry'));
      await tester.scrollUntilVisible(
        retryButton,
        240,
        scrollable: find.descendant(
          of: find.byType(RunSummaryScreen),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pump();
      await tester.tap(retryButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final retryGame = _activeGame(tester);
      await tester.runAsync(retryGame.ready);

      expect(retryGame, isNot(same(firstGame)));
      expect(retryGame.playerLevel, 1);
      expect(retryGame.elapsedSeconds, lessThan(1));
      expect(retryGame.isLevelUpPending, isFalse);
    },
  );
}

PixelSurvivorGame _activeGame(WidgetTester tester) {
  final widget = tester
      .widgetList<GameWidget<PixelSurvivorGame>>(
        find.byGame<PixelSurvivorGame>(),
      )
      .last;
  return widget.game!;
}

class _MemorySaveStore implements SaveStore {
  _MemorySaveStore(this.value);

  SaveState value;

  @override
  Future<SaveState> load() async => value;

  @override
  Future<void> save(SaveState state) async => value = state;
}

class _MemoryAudioSettingsStore implements AudioSettingsStore {
  AudioSettings value = AudioSettings.defaults;

  @override
  Future<AudioSettings> load() async => value;

  @override
  Future<void> save(AudioSettings settings) async => value = settings;
}
