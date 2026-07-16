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
    var retiredGameCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          audioSettingsController: settingsController,
          audioService: audioService,
          metaProgressionService: progression,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    for (var run = 0; run < 20; run += 1) {
      final game = _activeGame(tester);
      await tester.runAsync(game.ready);
      expect(game.performanceSnapshot.isWithinBudget, isTrue);

      game.debugAdvanceTo(300);
      game.debugKillPlayer();
      game.update(.016);
      await tester.pump();
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      for (var attempt = 0; attempt < 20; attempt += 1) {
        if (find.byType(RunSummaryScreen).evaluate().isNotEmpty) break;
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(RunSummaryScreen), findsOneWidget, reason: 'run $run');
      await tester.pump(const Duration(milliseconds: 100));
      retiredGameCount += 1;

      if (run < 19) {
        tester
            .widget<RunSummaryScreen>(find.byType(RunSummaryScreen))
            .onStart();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.byGame<PixelSurvivorGame>(), findsOneWidget);
        expect(_activeGame(tester), isNot(same(game)));
        // Test-only lifecycle probe; the factory controller cannot be subclassed.
        // ignore: invalid_use_of_protected_member
        expect(settingsController.hasListeners, isTrue);
        expect(backend.activeMusicHandles, lessThanOrEqualTo(1));
      }
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 300));
    // Test-only lifecycle probe; every GameScreen/ListenableBuilder is gone.
    // ignore: invalid_use_of_protected_member
    expect(settingsController.hasListeners, isFalse);
    expect(retiredGameCount, 20);
    expect(find.byGame<PixelSurvivorGame>(), findsNothing);
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
