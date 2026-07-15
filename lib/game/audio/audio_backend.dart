import 'audio_cue.dart';

abstract interface class AudioBackend {
  Future<void> play(AudioCue cue, AudioChannel channel);

  Future<void> stopMusic();

  Future<void> pauseAll();

  Future<void> resumeAll();

  Future<void> dispose();
}

class SilentAudioBackend implements AudioBackend {
  const SilentAudioBackend();

  @override
  Future<void> play(AudioCue cue, AudioChannel channel) async {}

  @override
  Future<void> stopMusic() async {}

  @override
  Future<void> pauseAll() async {}

  @override
  Future<void> resumeAll() async {}

  @override
  Future<void> dispose() async {}
}
