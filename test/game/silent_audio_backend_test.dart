import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/audio/audio_backend.dart';
import 'package:pixel_survivor/game/audio/audio_cue.dart';
import 'package:pixel_survivor/game/audio/audio_playback_policy.dart';

void main() {
  test(
    'silent backend accepts every command without platform bindings',
    () async {
      const backend = SilentAudioBackend();

      final handle = await backend.play(
        const AudioPlaybackRequest(
          cue: AudioCue.playerHit,
          channel: AudioChannel.sfx,
          priority: AudioPriority.high,
          pitch: 1,
        ),
      );
      await expectLater(handle.completed, completes);
      await handle.stop();
      await backend.stopMusic();
      await backend.pauseAll();
      await backend.resumeAll();
      await backend.dispose();
    },
  );
}
