import 'dart:async';

import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/game_screen.dart';
import 'package:pixel_survivor/app/run_summary_screen.dart';
import 'package:pixel_survivor/game/audio/audio_backend.dart';
import 'package:pixel_survivor/game/audio/audio_cue.dart';
import 'package:pixel_survivor/game/audio/audio_playback_policy.dart';
import 'package:pixel_survivor/game/audio/audio_settings.dart';
import 'package:pixel_survivor/game/audio/audio_settings_controller.dart';
import 'package:pixel_survivor/game/audio/audio_settings_repository.dart';
import 'package:pixel_survivor/game/audio/game_audio_service.dart';
import 'package:pixel_survivor/game/pixel_survivor_game.dart';
import 'package:pixel_survivor/game/systems/meta_progression_service.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('twenty accelerated runs release every runtime owner', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(960, 540);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    SharedPreferences.setMockInitialValues({});

    final settingsController = AudioSettingsController(
      store: _MemoryAudioSettingsStore(),
    );
    final backend = _TrackingAudioBackend();
    final audioService = GameAudioService(backend: backend);
    final progression = MetaProgressionService(
      saveStore: _MemorySaveStore(SaveState.defaults()),
    );
    final games = <PixelSurvivorGame>[];

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          audioSettingsController: settingsController,
          audioService: audioService,
          metaProgressionService: progression,
        ),
      ),
    );
    await _pumpUntil(
      tester,
      () => find.byGame<PixelSurvivorGame>().evaluate().isNotEmpty,
      'first game widget',
    );

    for (var run = 0; run < 20; run += 1) {
      final game = _activeGame(tester);
      games.add(game);
      await tester.runAsync(game.ready);
      expect(game.performanceSnapshot.isWithinBudget, isTrue);

      game.debugAdvanceTo(300);
      game.debugKillPlayer();
      game.update(.016);
      await _pumpUntil(
        tester,
        () => find.byType(RunSummaryScreen).evaluate().isNotEmpty,
        'summary for run $run',
      );
      expect(find.byType(RunSummaryScreen), findsOneWidget, reason: 'run $run');
      await _pumpUntil(
        tester,
        () => !game.isAttached,
        'run $run game detachment',
      );
      await _pumpUntil(
        tester,
        () => game.children.isEmpty,
        'run $run game children teardown',
      );
      await _pumpUntil(
        tester,
        () => backend.activeNonMusicHandles == 0,
        'run $run audio teardown',
      );
      expect(game.isAttached, isFalse, reason: 'run $run game widget');
      expect(game.children, isEmpty, reason: 'run $run game children');
      expect(backend.activeNonMusicHandles, 0, reason: 'run $run audio');
      expect(backend.activeHandles, lessThanOrEqualTo(1), reason: 'run $run');

      if (run < 19) {
        tester
            .widget<RunSummaryScreen>(find.byType(RunSummaryScreen))
            .onStart();
        await _pumpUntil(
          tester,
          () =>
              find.byGame<PixelSurvivorGame>().evaluate().isNotEmpty &&
              !identical(_activeGame(tester), game),
          'replacement game for run $run',
        );
        expect(find.byGame<PixelSurvivorGame>(), findsOneWidget);
        expect(_activeGame(tester), isNot(same(game)));
        // Test-only lifecycle probe; the factory controller cannot be subclassed.
        // ignore: invalid_use_of_protected_member
        expect(settingsController.hasListeners, isTrue);
        expect(backend.activeMusicHandles, lessThanOrEqualTo(1));
      }
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpUntil(
      tester,
      () => games.every((game) => !game.isAttached && game.children.isEmpty),
      'all games removed',
    );
    // Test-only lifecycle probe; every GameScreen/ListenableBuilder is gone.
    // ignore: invalid_use_of_protected_member
    expect(settingsController.hasListeners, isFalse);
    expect(games, hasLength(20));
    expect(games.every((game) => !game.isAttached), isTrue);
    expect(games.every((game) => game.children.isEmpty), isTrue);
    expect(find.byGame<PixelSurvivorGame>(), findsNothing);
    expect(backend.activeNonMusicHandles, 0);
    expect(backend.activeHandles, lessThanOrEqualTo(1));
    expect(tester.takeException(), isNull);

    await audioService.dispose();
    expect(backend.disposeCount, 1);
    expect(backend.activeHandles, 0);
    settingsController.dispose();
  });
}

PixelSurvivorGame _activeGame(WidgetTester tester) => tester
    .widgetList<GameWidget<PixelSurvivorGame>>(find.byGame<PixelSurvivorGame>())
    .last
    .game!;

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition,
  String description,
) async {
  for (var attempt = 0; attempt < 180; attempt += 1) {
    if (condition()) return;
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump(const Duration(milliseconds: 16));
  }
  fail('Timed out waiting for $description');
}

class _TrackingAudioBackend implements AudioBackend {
  final List<_TrackingAudioHandle> handles = [];
  int disposeCount = 0;

  int get activeHandles => handles.where((handle) => !handle.isStopped).length;

  int get activeMusicHandles => handles
      .where(
        (handle) =>
            !handle.isStopped && handle.request.channel == AudioChannel.music,
      )
      .length;

  int get activeNonMusicHandles => handles
      .where(
        (handle) =>
            !handle.isStopped && handle.request.channel != AudioChannel.music,
      )
      .length;

  @override
  Future<AudioPlaybackHandle> play(AudioPlaybackRequest request) async {
    final handle = _TrackingAudioHandle(request);
    handles.add(handle);
    return handle;
  }

  @override
  Future<void> pauseAll() async {}

  @override
  Future<void> resumeAll() async {}

  @override
  Future<void> stopMusic() async {
    for (final handle in handles.where(
      (handle) => handle.request.channel == AudioChannel.music,
    )) {
      await handle.stop();
    }
  }

  @override
  Future<void> dispose() async {
    disposeCount += 1;
    for (final handle in handles) {
      await handle.stop();
    }
  }
}

class _TrackingAudioHandle implements AudioPlaybackHandle {
  _TrackingAudioHandle(this.request);

  final AudioPlaybackRequest request;
  final Completer<void> _completion = Completer<void>();
  bool isStopped = false;

  @override
  Future<void> get completed => _completion.future;

  @override
  Future<void> stop() async {
    if (isStopped) return;
    isStopped = true;
    _completion.complete();
  }
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
