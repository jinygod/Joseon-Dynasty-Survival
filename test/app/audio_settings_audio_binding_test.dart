import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/audio_settings_audio_binding.dart';
import 'package:pixel_survivor/game/audio/audio_backend.dart';
import 'package:pixel_survivor/game/audio/audio_cue.dart';
import 'package:pixel_survivor/game/audio/audio_playback_policy.dart';
import 'package:pixel_survivor/game/audio/audio_settings.dart';
import 'package:pixel_survivor/game/audio/audio_settings_controller.dart';
import 'package:pixel_survivor/game/audio/audio_settings_repository.dart';
import 'package:pixel_survivor/game/audio/game_audio_service.dart';

void main() {
  test('settings notifications stop active muted audio', () async {
    final controller = AudioSettingsController(store: _MemoryStore());
    final backend = _RecordingBackend();
    final service = GameAudioService(
      backend: backend,
      readSettings: () => controller.settings,
    );
    final binding = AudioSettingsAudioBinding(
      controller: controller,
      service: service,
    );

    await service.play(AudioCue.battleMusic);
    await controller.setMusicVolume(0);
    await Future<void>.delayed(Duration.zero);

    expect(backend.handles.single.stopCount, 1);
    binding.dispose();
  });

  test('disposed binding no longer forwards settings notifications', () async {
    final controller = AudioSettingsController(store: _MemoryStore());
    final backend = _RecordingBackend();
    final service = GameAudioService(
      backend: backend,
      readSettings: () => controller.settings,
    );
    final binding = AudioSettingsAudioBinding(
      controller: controller,
      service: service,
    );

    await service.play(AudioCue.playerHit);
    binding.dispose();
    await controller.setSfxVolume(0);
    await Future<void>.delayed(Duration.zero);

    expect(backend.handles.single.stopCount, 0);
  });
}

class _MemoryStore implements AudioSettingsStore {
  AudioSettings value = AudioSettings.defaults;

  @override
  Future<AudioSettings> load() async => value;

  @override
  Future<void> save(AudioSettings settings) async => value = settings;
}

class _RecordingBackend implements AudioBackend {
  final List<_Handle> handles = [];

  @override
  Future<AudioPlaybackHandle> play(AudioPlaybackRequest request) async {
    final handle = _Handle();
    handles.add(handle);
    return handle;
  }

  @override
  Future<void> dispose() async {}

  @override
  Future<void> pauseAll() async {}

  @override
  Future<void> resumeAll() async {}

  @override
  Future<void> stopMusic() async {}
}

class _Handle implements AudioPlaybackHandle {
  final Completer<void> _completed = Completer<void>();
  int stopCount = 0;

  @override
  Future<void> get completed => _completed.future;

  @override
  Future<void> stop() async {
    stopCount += 1;
    if (!_completed.isCompleted) _completed.complete();
  }
}
