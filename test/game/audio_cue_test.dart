import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/audio/audio_cue.dart';

void main() {
  test('every audio cue maps to exactly one supported channel', () {
    for (final cue in AudioCue.values) {
      expect(AudioCueCatalog.channelFor(cue), isIn(AudioChannel.values));
    }
  });

  test('music cues use only the music channel', () {
    const music = {
      AudioCue.menuMusic,
      AudioCue.battleMusic,
      AudioCue.bossMusic,
      AudioCue.victoryMusic,
      AudioCue.defeatMusic,
    };

    expect(
      music.every(
        (cue) => AudioCueCatalog.channelFor(cue) == AudioChannel.music,
      ),
      isTrue,
    );
  });

  test('combat and UI cues use their dedicated channels', () {
    expect(AudioCueCatalog.channelFor(AudioCue.playerHit), AudioChannel.sfx);
    expect(AudioCueCatalog.channelFor(AudioCue.levelUp), AudioChannel.sfx);
    expect(AudioCueCatalog.channelFor(AudioCue.uiConfirm), AudioChannel.ui);
    expect(AudioCueCatalog.channelFor(AudioCue.uiBack), AudioChannel.ui);
  });

  test('mastery combat cues use the sfx channel', () {
    expect(
      AudioCueCatalog.channelFor(AudioCue.hwandoMasterAttack),
      AudioChannel.sfx,
    );
    expect(
      AudioCueCatalog.channelFor(AudioCue.talismanMasterAttack),
      AudioChannel.sfx,
    );
    expect(
      AudioCueCatalog.channelFor(AudioCue.gakgungMasterAttack),
      AudioChannel.sfx,
    );
    expect(AudioCueCatalog.channelFor(AudioCue.sealingSlash), AudioChannel.sfx);
  });
}
