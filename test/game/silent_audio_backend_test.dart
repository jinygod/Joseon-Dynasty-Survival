import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/audio/audio_backend.dart';
import 'package:pixel_survivor/game/audio/audio_cue.dart';

void main() {
  test(
    'silent backend accepts every command without platform bindings',
    () async {
      const backend = SilentAudioBackend();

      await backend.play(AudioCue.playerHit, AudioChannel.sfx);
      await backend.stopMusic();
      await backend.pauseAll();
      await backend.resumeAll();
      await backend.dispose();
    },
  );
}
