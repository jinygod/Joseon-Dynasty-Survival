import 'audio_playback_policy.dart';

abstract interface class AudioPlaybackHandle {
  Future<void> get completed;

  Future<void> stop();
}

abstract interface class AudioBackend {
  Future<AudioPlaybackHandle> play(AudioPlaybackRequest request);

  Future<void> stopMusic();

  Future<void> pauseAll();

  Future<void> resumeAll();

  Future<void> dispose();
}

class SilentAudioBackend implements AudioBackend {
  const SilentAudioBackend();

  @override
  Future<AudioPlaybackHandle> play(AudioPlaybackRequest request) async =>
      const SilentAudioPlaybackHandle();

  @override
  Future<void> stopMusic() async {}

  @override
  Future<void> pauseAll() async {}

  @override
  Future<void> resumeAll() async {}

  @override
  Future<void> dispose() async {}
}

class SilentAudioPlaybackHandle implements AudioPlaybackHandle {
  const SilentAudioPlaybackHandle();

  @override
  Future<void> get completed => Future<void>.value();

  @override
  Future<void> stop() async {}
}
