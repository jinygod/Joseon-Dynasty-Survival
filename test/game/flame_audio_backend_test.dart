import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/audio/audio_cue.dart';
import 'package:pixel_survivor/game/audio/audio_playback_policy.dart';
import 'package:pixel_survivor/game/audio/flame_audio_backend.dart';

void main() {
  test('forwards catalog path loop volume and pitch to the player starter', () async {
    final starter = RecordingPlayerStarter();
    final backend = FlameAudioBackend(startPlayer: starter.call);

    await backend.play(
      const AudioPlaybackRequest(
        cue: AudioCue.battleMusic,
        channel: AudioChannel.music,
        priority: AudioPriority.normal,
        pitch: 1.02,
        volume: 0.45,
      ),
    );

    expect(starter.calls.single.path, 'music/battle.ogg');
    expect(starter.calls.single.loop, isTrue);
    expect(starter.calls.single.volume, 0.45);
    expect(starter.calls.single.pitch, 1.02);
  });

  test('stopMusic stops and disposes only active music', () async {
    final starter = RecordingPlayerStarter();
    final backend = FlameAudioBackend(startPlayer: starter.call);
    await backend.play(_request(AudioCue.battleMusic, AudioChannel.music));
    await backend.play(_request(AudioCue.playerHit, AudioChannel.sfx));

    await backend.stopMusic();

    expect(starter.players[0].stopCount, 1);
    expect(starter.players[0].disposeCount, 1);
    expect(starter.players[1].stopCount, 0);
  });

  test('pause and resume apply to every active voice', () async {
    final starter = RecordingPlayerStarter();
    final backend = FlameAudioBackend(startPlayer: starter.call);
    await backend.play(_request(AudioCue.battleMusic, AudioChannel.music));
    await backend.play(_request(AudioCue.playerHit, AudioChannel.sfx));

    await backend.pauseAll();
    await backend.resumeAll();

    expect(starter.players.map((player) => player.pauseCount), [1, 1]);
    expect(starter.players.map((player) => player.resumeCount), [1, 1]);
  });

  test('natural completion disposes the player and completes the handle', () async {
    final starter = RecordingPlayerStarter();
    final backend = FlameAudioBackend(startPlayer: starter.call);
    final handle = await backend.play(
      _request(AudioCue.uiConfirm, AudioChannel.ui),
    );

    starter.players.single.complete();
    await handle.completed;

    expect(starter.players.single.disposeCount, 1);
  });

  test('dispose is idempotent and closes every active player', () async {
    final starter = RecordingPlayerStarter();
    final backend = FlameAudioBackend(startPlayer: starter.call);
    await backend.play(_request(AudioCue.battleMusic, AudioChannel.music));
    await backend.play(_request(AudioCue.playerHit, AudioChannel.sfx));

    await backend.dispose();
    await backend.dispose();

    expect(starter.players.map((player) => player.stopCount), [1, 1]);
    expect(starter.players.map((player) => player.disposeCount), [1, 1]);
  });
}

AudioPlaybackRequest _request(AudioCue cue, AudioChannel channel) {
  return AudioPlaybackRequest(
    cue: cue,
    channel: channel,
    priority: AudioPriority.normal,
    pitch: 1,
    volume: 0.8,
  );
}

class RecordingPlayerStarter {
  final List<PlayerStartRequest> calls = [];
  final List<ControlledPlayerPort> players = [];

  Future<AudioPlayerPort> call(PlayerStartRequest request) async {
    calls.add(request);
    final player = ControlledPlayerPort();
    players.add(player);
    return player;
  }
}

class ControlledPlayerPort implements AudioPlayerPort {
  final Completer<void> _completed = Completer<void>();
  int pauseCount = 0;
  int resumeCount = 0;
  int stopCount = 0;
  int disposeCount = 0;

  @override
  Future<void> get completed => _completed.future;

  void complete() {
    if (!_completed.isCompleted) _completed.complete();
  }

  @override
  Future<void> pause() async => pauseCount += 1;

  @override
  Future<void> resume() async => resumeCount += 1;

  @override
  Future<void> stop() async {
    stopCount += 1;
    complete();
  }

  @override
  Future<void> dispose() async => disposeCount += 1;
}
