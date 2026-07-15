import 'audio_backend.dart';
import 'audio_cue.dart';

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
  GameAudioService({
    required AudioBackend backend,
    void Function(AudioDiagnostic)? reportDiagnostic,
  }) : _backend = backend,
       _reportDiagnostic = reportDiagnostic;

  final AudioBackend _backend;
  final void Function(AudioDiagnostic)? _reportDiagnostic;
  bool _disposed = false;

  Future<void> play(AudioCue cue) async {
    if (_disposed) return;
    await _guard(
      operation: 'play',
      cue: cue,
      action: () => _backend.play(cue, AudioCueCatalog.channelFor(cue)),
    );
  }

  Future<void> stopMusic() async {
    if (_disposed) return;
    await _guard(operation: 'stopMusic', action: _backend.stopMusic);
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
    await _guard(operation: 'dispose', action: _backend.dispose);
  }

  Future<void> _guard({
    required String operation,
    AudioCue? cue,
    required Future<void> Function() action,
  }) async {
    try {
      await action();
    } catch (error, stackTrace) {
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
}
