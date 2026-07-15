import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/audio/audio_backend.dart';
import 'package:pixel_survivor/game/audio/audio_cue.dart';
import 'package:pixel_survivor/game/audio/game_audio_service.dart';

void main() {
  test('service forwards a cue with its catalog channel', () async {
    final backend = RecordingAudioBackend();
    final service = GameAudioService(backend: backend);

    await service.play(AudioCue.playerHit);

    expect(backend.commands, ['play:playerHit:sfx']);
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

  test('dispose is idempotent and suppresses later commands', () async {
    final backend = RecordingAudioBackend();
    final service = GameAudioService(backend: backend);

    await service.dispose();
    await service.dispose();
    await service.play(AudioCue.uiConfirm);
    await service.resumeAll();

    expect(backend.commands, ['dispose']);
  });
}

class RecordingAudioBackend implements AudioBackend {
  final List<String> commands = [];

  @override
  Future<void> play(AudioCue cue, AudioChannel channel) async {
    commands.add('play:${cue.name}:${channel.name}');
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

class ThrowingAudioBackend implements AudioBackend {
  const ThrowingAudioBackend();

  Never _fail() => throw StateError('audio backend failed');

  @override
  Future<void> play(AudioCue cue, AudioChannel channel) async => _fail();

  @override
  Future<void> stopMusic() async => _fail();

  @override
  Future<void> pauseAll() async => _fail();

  @override
  Future<void> resumeAll() async => _fail();

  @override
  Future<void> dispose() async => _fail();
}
