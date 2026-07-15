import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/audio/audio_backend.dart';
import 'package:pixel_survivor/game/audio/audio_cue.dart';
import 'package:pixel_survivor/game/audio/audio_playback_policy.dart';
import 'package:pixel_survivor/game/audio/audio_settings.dart';
import 'package:pixel_survivor/game/audio/game_audio_service.dart';

void main() {
  test('service forwards a complete policy request', () async {
    final backend = RecordingAudioBackend();
    final service = GameAudioService(backend: backend);

    await service.play(AudioCue.playerHit);

    expect(backend.requests, hasLength(1));
    expect(backend.requests.single.cue, AudioCue.playerHit);
    expect(backend.requests.single.channel, AudioChannel.sfx);
    expect(backend.requests.single.priority, AudioPriority.high);
    expect(backend.requests.single.pitch, 0.96);
    expect(backend.requests.single.volume, 0.8);
  });

  test('service reads the latest settings for each playback', () async {
    var settings = AudioSettings(
      musicVolume: 0.2,
      sfxVolume: 0.4,
      vibrationEnabled: true,
    );
    final backend = RecordingAudioBackend();
    final service = GameAudioService(
      backend: backend,
      readSettings: () => settings,
    );

    await service.play(AudioCue.battleMusic);
    backend.handles.single.complete();
    await Future<void>.delayed(Duration.zero);
    settings = settings.copyWith(musicVolume: 0.6);
    await service.play(AudioCue.menuMusic);

    expect(backend.requests.map((request) => request.volume), [0.2, 0.6]);
  });

  test('zero music volume suppresses music only', () async {
    final backend = RecordingAudioBackend();
    final service = GameAudioService(
      backend: backend,
      readSettings: () => AudioSettings(
        musicVolume: 0,
        sfxVolume: 0.5,
        vibrationEnabled: true,
      ),
    );

    await service.play(AudioCue.battleMusic);
    await service.play(AudioCue.playerHit);

    expect(backend.requests.map((request) => request.cue), [AudioCue.playerHit]);
    expect(backend.requests.single.volume, 0.5);
  });

  test('zero effects volume suppresses SFX and UI only', () async {
    final backend = RecordingAudioBackend();
    final service = GameAudioService(
      backend: backend,
      readSettings: () => AudioSettings(
        musicVolume: 0.3,
        sfxVolume: 0,
        vibrationEnabled: true,
      ),
    );

    await service.play(AudioCue.playerHit);
    await service.play(AudioCue.uiConfirm);
    await service.play(AudioCue.battleMusic);

    expect(backend.requests.map((request) => request.cue), [
      AudioCue.battleMusic,
    ]);
  });

  test('muted SFX does not advance its pitch cycle', () async {
    var settings = AudioSettings(
      musicVolume: 0.7,
      sfxVolume: 0,
      vibrationEnabled: true,
    );
    final backend = RecordingAudioBackend();
    final service = GameAudioService(
      backend: backend,
      readSettings: () => settings,
    );

    await service.play(AudioCue.hwandoAttack);
    settings = settings.copyWith(sfxVolume: 0.8);
    await service.play(AudioCue.hwandoAttack);

    expect(backend.requests.single.pitch, 0.96);
  });

  test('completed voices release their channel slot', () async {
    final backend = RecordingAudioBackend();
    final service = GameAudioService(backend: backend);

    await service.play(AudioCue.uiConfirm);
    await service.play(AudioCue.uiBack);
    backend.handles.first.complete();
    await Future<void>.delayed(Duration.zero);
    await service.play(AudioCue.uiConfirm);

    expect(backend.requests, hasLength(3));
  });

  test('channel limits are independent', () async {
    final backend = RecordingAudioBackend();
    final service = GameAudioService(backend: backend);

    await service.play(AudioCue.battleMusic);
    await service.play(AudioCue.uiConfirm);
    await service.play(AudioCue.uiBack);
    for (var index = 0; index < 8; index += 1) {
      await service.play(AudioCue.hwandoAttack);
    }

    expect(backend.requests, hasLength(11));
  });

  test('equal priority request is rejected when channel is full', () async {
    final backend = RecordingAudioBackend();
    final service = GameAudioService(backend: backend);

    await service.play(AudioCue.uiConfirm);
    await service.play(AudioCue.uiBack);
    await service.play(AudioCue.uiConfirm);

    expect(backend.requests, hasLength(2));
    expect(backend.handles.every((handle) => handle.stopCount == 0), isTrue);
  });

  test('higher priority preempts oldest lowest-priority voice', () async {
    final backend = RecordingAudioBackend();
    final service = GameAudioService(backend: backend);

    await service.play(AudioCue.enemyDeath);
    await service.play(AudioCue.experiencePickup);
    for (var index = 0; index < 6; index += 1) {
      await service.play(AudioCue.hwandoAttack);
    }
    await service.play(AudioCue.playerHit);

    expect(backend.requests, hasLength(9));
    expect(backend.handles[0].stopCount, 1);
    expect(backend.handles[1].stopCount, 0);
    expect(backend.requests.last.cue, AudioCue.playerHit);
  });

  test('lower priority request is rejected when channel is full', () async {
    final backend = RecordingAudioBackend();
    final service = GameAudioService(backend: backend);

    for (var index = 0; index < 8; index += 1) {
      await service.play(AudioCue.hwandoAttack);
    }
    await service.play(AudioCue.experiencePickup);

    expect(backend.requests, hasLength(8));
  });

  test('concurrent callers cannot exceed channel capacity', () async {
    final barrier = Completer<void>();
    final backend = RecordingAudioBackend(playBarrier: barrier.future);
    final service = GameAudioService(backend: backend);

    final plays = [
      service.play(AudioCue.uiConfirm),
      service.play(AudioCue.uiBack),
      service.play(AudioCue.uiConfirm),
    ];
    await Future<void>.delayed(Duration.zero);
    expect(backend.requests, hasLength(1));

    barrier.complete();
    await Future.wait(plays);

    expect(backend.requests, hasLength(2));
  });

  test(
    'failed preemption stop is diagnosed and replacement still plays',
    () async {
      final diagnostics = <AudioDiagnostic>[];
      final backend = RecordingAudioBackend(firstHandleThrowsOnStop: true);
      final service = GameAudioService(
        backend: backend,
        reportDiagnostic: diagnostics.add,
      );

      await service.play(AudioCue.enemyDeath);
      for (var index = 0; index < 7; index += 1) {
        await service.play(AudioCue.hwandoAttack);
      }
      await service.play(AudioCue.playerHit);

      expect(backend.requests, hasLength(9));
      expect(diagnostics, hasLength(1));
      expect(diagnostics.single.operation, 'stopVoice');
      expect(diagnostics.single.cue, AudioCue.enemyDeath);
    },
  );

  test('failed completion is diagnosed and releases its slot', () async {
    final diagnostics = <AudioDiagnostic>[];
    final backend = RecordingAudioBackend();
    final service = GameAudioService(
      backend: backend,
      reportDiagnostic: diagnostics.add,
    );

    await service.play(AudioCue.battleMusic);
    backend.handles.single.completeError(StateError('decoder failed'));
    await Future<void>.delayed(Duration.zero);
    await service.play(AudioCue.menuMusic);

    expect(backend.requests, hasLength(2));
    expect(diagnostics, hasLength(1));
    expect(diagnostics.single.operation, 'playbackCompleted');
    expect(diagnostics.single.cue, AudioCue.battleMusic);
  });

  test('service forwards lifecycle commands in call order', () async {
    final backend = RecordingAudioBackend();
    final service = GameAudioService(backend: backend);

    await service.stopMusic();
    await service.pauseAll();
    await service.resumeAll();
    await service.dispose();

    expect(backend.commands, ['stopMusic', 'pauseAll', 'resumeAll', 'dispose']);
  });

  test('stopMusic releases the tracked music slot', () async {
    final backend = RecordingAudioBackend();
    final service = GameAudioService(backend: backend);

    await service.play(AudioCue.battleMusic);
    await service.stopMusic();
    await service.play(AudioCue.menuMusic);

    expect(backend.requests, hasLength(2));
  });

  test('backend errors become one diagnostic and never escape', () async {
    final diagnostics = <AudioDiagnostic>[];
    final service = GameAudioService(
      backend: const ThrowingAudioBackend(),
      reportDiagnostic: diagnostics.add,
    );

    await service.play(AudioCue.bossWarning);

    expect(diagnostics, hasLength(1));
    expect(diagnostics.single.operation, 'play');
    expect(diagnostics.single.cue, AudioCue.bossWarning);
    expect(diagnostics.single.error, isA<StateError>());
  });

  test('diagnostic reporter errors never escape', () async {
    final service = GameAudioService(
      backend: const ThrowingAudioBackend(),
      reportDiagnostic: (_) => throw StateError('reporter failed'),
    );

    await service.pauseAll();
  });

  test(
    'dispose is idempotent and suppresses queued and later commands',
    () async {
      final barrier = Completer<void>();
      final backend = RecordingAudioBackend(playBarrier: barrier.future);
      final service = GameAudioService(backend: backend);

      final pendingPlay = service.play(AudioCue.uiConfirm);
      await Future<void>.delayed(Duration.zero);
      final dispose = service.dispose();
      barrier.complete();
      await pendingPlay;
      await dispose;
      await service.dispose();
      await service.play(AudioCue.uiBack);
      await service.resumeAll();

      expect(backend.commands.last, 'dispose');
      expect(
        backend.commands.where((command) => command == 'dispose'),
        hasLength(1),
      );
      expect(backend.requests, hasLength(1));
      expect(backend.handles.single.stopCount, 1);
    },
  );
}

class RecordingAudioBackend implements AudioBackend {
  RecordingAudioBackend({
    this.playBarrier,
    this.firstHandleThrowsOnStop = false,
  });

  final Future<void>? playBarrier;
  final bool firstHandleThrowsOnStop;
  final List<String> commands = [];
  final List<AudioPlaybackRequest> requests = [];
  final List<ControlledAudioPlaybackHandle> handles = [];

  @override
  Future<AudioPlaybackHandle> play(AudioPlaybackRequest request) async {
    requests.add(request);
    commands.add('play:${request.cue.name}:${request.channel.name}');
    await playBarrier;
    final handle = ControlledAudioPlaybackHandle(
      throwsOnStop: firstHandleThrowsOnStop && handles.isEmpty,
    );
    handles.add(handle);
    return handle;
  }

  @override
  Future<void> stopMusic() async => commands.add('stopMusic');

  @override
  Future<void> pauseAll() async => commands.add('pauseAll');

  @override
  Future<void> resumeAll() async => commands.add('resumeAll');

  @override
  Future<void> dispose() async => commands.add('dispose');
}

class ControlledAudioPlaybackHandle implements AudioPlaybackHandle {
  ControlledAudioPlaybackHandle({this.throwsOnStop = false});

  final bool throwsOnStop;
  final Completer<void> _completion = Completer<void>();
  int stopCount = 0;

  @override
  Future<void> get completed => _completion.future;

  void complete() {
    if (!_completion.isCompleted) _completion.complete();
  }

  void completeError(Object error) {
    if (!_completion.isCompleted) _completion.completeError(error);
  }

  @override
  Future<void> stop() async {
    stopCount += 1;
    if (throwsOnStop) throw StateError('stop failed');
    complete();
  }
}

class ThrowingAudioBackend implements AudioBackend {
  const ThrowingAudioBackend();

  Never _fail() => throw StateError('audio backend failed');

  @override
  Future<AudioPlaybackHandle> play(AudioPlaybackRequest request) async =>
      _fail();

  @override
  Future<void> stopMusic() async => _fail();

  @override
  Future<void> pauseAll() async => _fail();

  @override
  Future<void> resumeAll() async => _fail();

  @override
  Future<void> dispose() async => _fail();
}
