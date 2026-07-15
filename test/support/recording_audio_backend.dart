import 'package:pixel_survivor/game/audio/audio_backend.dart';
import 'package:pixel_survivor/game/audio/audio_playback_policy.dart';

class RecordingAudioBackend implements AudioBackend {
  final List<AudioPlaybackRequest> requests = [];
  final List<String> commands = [];

  @override
  Future<AudioPlaybackHandle> play(AudioPlaybackRequest request) async {
    requests.add(request);
    return const SilentAudioPlaybackHandle();
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
