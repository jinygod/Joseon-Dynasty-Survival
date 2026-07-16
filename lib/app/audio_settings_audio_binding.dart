import 'dart:async';

import '../game/audio/audio_settings_controller.dart';
import '../game/audio/game_audio_service.dart';

class AudioSettingsAudioBinding {
  AudioSettingsAudioBinding({
    required AudioSettingsController controller,
    required GameAudioService service,
  }) : _controller = controller,
       _service = service {
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
