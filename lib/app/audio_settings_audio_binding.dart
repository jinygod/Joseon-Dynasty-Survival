import 'dart:async';

import '../game/audio/audio_settings_controller.dart';
import '../game/audio/game_audio_service.dart';

class AudioSettingsAudioBinding {
  factory AudioSettingsAudioBinding({
    required AudioSettingsController controller,
    required GameAudioService service,
  }) => AudioSettingsAudioBinding._(controller, service);

  AudioSettingsAudioBinding._(this._controller, this._service) {
    _controller.addListener(_applySettings);
  }

  final AudioSettingsController _controller;
  final GameAudioService _service;
  bool _disposed = false;

  void _applySettings() {
    unawaited(_service.applySettings());
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _controller.removeListener(_applySettings);
  }
}
