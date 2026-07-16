import 'dart:async';

import 'audio_backend.dart';
import 'audio_cue.dart';
import 'audio_playback_policy.dart';
import 'audio_settings.dart';

class AudioDiagnostic {
  const AudioDiagnostic({
    required this.operation,
    required this.cue,
    required this.error,
    required this.stackTrace,
  });

  final String operation;
  final AudioCue? cue;
  final Object error;
  final StackTrace stackTrace;
}

class GameAudioService {
  factory GameAudioService({
    required AudioBackend backend,
    void Function(AudioDiagnostic)? reportDiagnostic,
    AudioSettings Function()? readSettings,
  }) => GameAudioService._(
    backend,
    reportDiagnostic,
    AudioPlaybackPolicy(),
    readSettings ?? _readDefaultSettings,
  );

  GameAudioService._(
    this._backend,
    this._reportDiagnostic,
    this._policy,
    this._readSettings,
  );

  final AudioBackend _backend;
  final void Function(AudioDiagnostic)? _reportDiagnostic;
  final AudioPlaybackPolicy _policy;
  final AudioSettings Function() _readSettings;
  final List<_ActiveVoice> _activeVoices = [];
  Future<void> _admissionQueue = Future<void>.value();
  int _nextSequence = 0;
  bool _disposed = false;

  Future<void> play(AudioCue cue) {
    if (_disposed) return Future<void>.value();
    final channel = AudioCueCatalog.channelFor(cue);
    final volume = _readSettings().volumeFor(channel);
    if (volume <= 0) return Future<void>.value();
    return _enqueue(() => _admitCue(cue));
  }

  static AudioSettings _readDefaultSettings() => AudioSettings.defaults;

  Future<void> stopMusic() {
    if (_disposed) return Future<void>.value();
    return _enqueue(() async {
      _activeVoices.removeWhere(
        (voice) => voice.request.channel == AudioChannel.music,
      );
      await _guard(operation: 'stopMusic', action: _backend.stopMusic);
    });
  }

  Future<void> stopNonMusic() {
    if (_disposed) return Future<void>.value();
    return _enqueue(() async {
      final targets = _activeVoices
          .where((voice) => voice.request.channel != AudioChannel.music)
          .toList(growable: false);
      for (final voice in targets) {
        _activeVoices.remove(voice);
        await _guard(
          operation: 'stopVoice',
          cue: voice.request.cue,
          action: voice.handle.stop,
        );
      }
    });
  }

  Future<void> applySettings() {
    if (_disposed) return Future<void>.value();
    return _enqueue(() async {
      final settings = _readSettings();
      final targets = _activeVoices
          .where((voice) => settings.volumeFor(voice.request.channel) <= 0)
          .toList(growable: false);
      for (final voice in targets) {
        _activeVoices.remove(voice);
        await _guard(
          operation: 'stopVoice',
          cue: voice.request.cue,
          action: voice.handle.stop,
        );
      }
    });
  }

  Future<void> pauseAll() async {
    if (_disposed) return;
    await _guard(operation: 'pauseAll', action: _backend.pauseAll);
  }

  Future<void> resumeAll() async {
    if (_disposed) return;
    await _guard(operation: 'resumeAll', action: _backend.resumeAll);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _admissionQueue;
    _activeVoices.clear();
    await _guard(operation: 'dispose', action: _backend.dispose);
  }

  Future<void> _admitCue(AudioCue cue) async {
    final channel = AudioCueCatalog.channelFor(cue);
    final volume = _readSettings().volumeFor(channel);
    if (volume <= 0) return;
    final request = _policy.requestFor(cue, volume: volume);
    await _playRequest(request);
  }

  Future<void> _playRequest(AudioPlaybackRequest request) async {
    if (_disposed) return;
    final channelVoices = _activeVoices
        .where((voice) => voice.request.channel == request.channel)
        .toList(growable: false);
    if (request.channel == AudioChannel.music && channelVoices.isNotEmpty) {
      for (final voice in channelVoices) {
        _activeVoices.remove(voice);
        await _guard(
          operation: 'stopVoice',
          cue: voice.request.cue,
          action: voice.handle.stop,
        );
      }
    }
    final remainingChannelVoices = _activeVoices
        .where((voice) => voice.request.channel == request.channel)
        .toList(growable: false);
    if (remainingChannelVoices.length >=
        AudioPlaybackPolicy.limitFor(request.channel)) {
      final victim = _lowestPriorityOldestVoice(remainingChannelVoices);
      if (request.priority.index <= victim.request.priority.index) return;
      _activeVoices.remove(victim);
      await _guard(
        operation: 'stopVoice',
        cue: victim.request.cue,
        action: victim.handle.stop,
      );
    }

    final handle = await _startPlayback(request);
    if (handle == null) return;
    if (_disposed) {
      await _guard(
        operation: 'stopVoice',
        cue: request.cue,
        action: handle.stop,
      );
      return;
    }

    final voice = _ActiveVoice(
      request: request,
      handle: handle,
      sequence: _nextSequence,
    );
    _nextSequence += 1;
    _activeVoices.add(voice);
    unawaited(
      handle.completed.then<void>(
        (_) => _activeVoices.remove(voice),
        onError: (Object error, StackTrace stackTrace) {
          _activeVoices.remove(voice);
          _report(
            operation: 'playbackCompleted',
            cue: request.cue,
            error: error,
            stackTrace: stackTrace,
          );
        },
      ),
    );
  }

  _ActiveVoice _lowestPriorityOldestVoice(List<_ActiveVoice> voices) {
    var victim = voices.first;
    for (final voice in voices.skip(1)) {
      final hasLowerPriority =
          voice.request.priority.index < victim.request.priority.index;
      final isOlderAtSamePriority =
          voice.request.priority == victim.request.priority &&
          voice.sequence < victim.sequence;
      if (hasLowerPriority || isOlderAtSamePriority) victim = voice;
    }
    return victim;
  }

  Future<AudioPlaybackHandle?> _startPlayback(
    AudioPlaybackRequest request,
  ) async {
    try {
      return await _backend.play(request);
    } catch (error, stackTrace) {
      _report(
        operation: 'play',
        cue: request.cue,
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final result = _admissionQueue.then((_) => action());
    _admissionQueue = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  Future<void> _guard({
    required String operation,
    AudioCue? cue,
    required Future<void> Function() action,
  }) async {
    try {
      await action();
    } catch (error, stackTrace) {
      _report(
        operation: operation,
        cue: cue,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _report({
    required String operation,
    required AudioCue? cue,
    required Object error,
    required StackTrace stackTrace,
  }) {
    final diagnostic = AudioDiagnostic(
      operation: operation,
      cue: cue,
      error: error,
      stackTrace: stackTrace,
    );
    try {
      _reportDiagnostic?.call(diagnostic);
    } catch (_) {
      // Diagnostics must never become a second audio failure.
    }
  }
}

class _ActiveVoice {
  const _ActiveVoice({
    required this.request,
    required this.handle,
    required this.sequence,
  });

  final AudioPlaybackRequest request;
  final AudioPlaybackHandle handle;
  final int sequence;
}
