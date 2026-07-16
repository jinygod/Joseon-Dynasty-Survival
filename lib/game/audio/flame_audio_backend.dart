import 'dart:async';

import 'package:flame_audio/flame_audio.dart';

import 'audio_asset_catalog.dart';
import 'audio_backend.dart';
import 'audio_cue.dart';
import 'audio_playback_policy.dart';

class PlayerStartRequest {
  const PlayerStartRequest({
    required this.path,
    required this.loop,
    required this.volume,
    required this.pitch,
  });

  final String path;
  final bool loop;
  final double volume;
  final double pitch;
}

abstract interface class AudioPlayerPort {
  Future<void> get completed;

  Future<void> pause();

  Future<void> resume();

  Future<void> stop();

  Future<void> dispose();
}

typedef AudioPlayerStarter =
    Future<AudioPlayerPort> Function(PlayerStartRequest request);

class FlameAudioBackend implements AudioBackend {
  FlameAudioBackend({AudioPlayerStarter? startPlayer})
    : _startPlayer = startPlayer ?? _startWithFlame;

  final AudioPlayerStarter _startPlayer;
  final Set<_FlameAudioPlaybackHandle> _voices = {};
  bool _disposed = false;

  @override
  Future<AudioPlaybackHandle> play(AudioPlaybackRequest request) async {
    if (_disposed) throw StateError('Audio backend is disposed');
    if (request.channel == AudioChannel.music) await stopMusic();

    final asset = AudioAssetCatalog.forCue(request.cue);
    final port = await _startPlayer(
      PlayerStartRequest(
        path: asset.path.substring('audio/'.length),
        loop: asset.loop,
        volume: request.volume,
        pitch: request.pitch,
      ),
    );
    late final _FlameAudioPlaybackHandle handle;
    handle = _FlameAudioPlaybackHandle(
      port: port,
      channel: request.channel,
      onClosed: () => _voices.remove(handle),
    );
    _voices.add(handle);
    return handle;
  }

  @override
  Future<void> stopMusic() =>
      _closeWhere((voice) => voice.channel == AudioChannel.music);

  @override
  Future<void> pauseAll() => Future.wait(_voices.map((voice) => voice.pause()));

  @override
  Future<void> resumeAll() =>
      Future.wait(_voices.map((voice) => voice.resume()));

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _closeWhere((_) => true);
  }

  Future<void> _closeWhere(
    bool Function(_FlameAudioPlaybackHandle voice) predicate,
  ) async {
    final targets = _voices.where(predicate).toList(growable: false);
    await Future.wait(targets.map((voice) => voice.stop()));
  }

  static Future<AudioPlayerPort> _startWithFlame(
    PlayerStartRequest request,
  ) async {
    final player = request.loop
        ? await FlameAudio.loop(request.path, volume: request.volume)
        : await FlameAudio.play(request.path, volume: request.volume);
    if (request.pitch != 1) await player.setPlaybackRate(request.pitch);
    return _AudioplayersPort(player);
  }
}

class _AudioplayersPort implements AudioPlayerPort {
  const _AudioplayersPort(this._player);

  final AudioPlayer _player;

  @override
  Future<void> get completed => _player.onPlayerComplete.first;

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() => _player.resume();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}

class _FlameAudioPlaybackHandle implements AudioPlaybackHandle {
  _FlameAudioPlaybackHandle({
    required this.port,
    required this.channel,
    required this.onClosed,
  }) {
    unawaited(
      port.completed.then<void>(
        (_) => _close(stopFirst: false),
        onError: (Object error, StackTrace stackTrace) =>
            _close(stopFirst: false, error: error, stackTrace: stackTrace),
      ),
    );
  }

  final AudioPlayerPort port;
  final AudioChannel channel;
  final void Function() onClosed;
  final Completer<void> _completed = Completer<void>();
  bool _closed = false;

  @override
  Future<void> get completed => _completed.future;

  Future<void> pause() => _closed ? Future<void>.value() : port.pause();

  Future<void> resume() => _closed ? Future<void>.value() : port.resume();

  @override
  Future<void> stop() => _close(stopFirst: true);

  Future<void> _close({
    required bool stopFirst,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    if (_closed) return;
    _closed = true;
    try {
      if (stopFirst) await port.stop();
      await port.dispose();
      onClosed();
      if (error == null) {
        _completed.complete();
      } else {
        _completed.completeError(error, stackTrace);
      }
    } catch (closeError, closeStackTrace) {
      onClosed();
      _completed.completeError(closeError, closeStackTrace);
      rethrow;
    }
  }
}
