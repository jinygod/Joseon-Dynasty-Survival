import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/audio/audio_cue.dart';
import 'package:pixel_survivor/game/audio/audio_playback_policy.dart';

void main() {
  test('every cue maps to a supported priority', () {
    for (final cue in AudioCue.values) {
      expect(AudioPlaybackPolicy.priorityFor(cue), isIn(AudioPriority.values));
    }
  });

  test('survival feedback receives the intended importance', () {
    expect(
      AudioPlaybackPolicy.priorityFor(AudioCue.bossWarning),
      AudioPriority.critical,
    );
    expect(
      AudioPlaybackPolicy.priorityFor(AudioCue.levelUp),
      AudioPriority.critical,
    );
    expect(
      AudioPlaybackPolicy.priorityFor(AudioCue.playerHit),
      AudioPriority.high,
    );
    expect(
      AudioPlaybackPolicy.priorityFor(AudioCue.experiencePickup),
      AudioPriority.low,
    );
    expect(
      AudioPlaybackPolicy.priorityFor(AudioCue.enemyDeath),
      AudioPriority.low,
    );
    expect(
      AudioPlaybackPolicy.priorityFor(AudioCue.hwandoAttack),
      AudioPriority.normal,
    );
  });

  test('channel limits are positive and match the voice budget', () {
    expect(AudioPlaybackPolicy.limitFor(AudioChannel.music), 1);
    expect(AudioPlaybackPolicy.limitFor(AudioChannel.sfx), 8);
    expect(AudioPlaybackPolicy.limitFor(AudioChannel.ui), 2);
  });

  test('repeated SFX cycles through deterministic pitch values', () {
    final policy = AudioPlaybackPolicy();

    final pitches = List.generate(
      7,
      (_) => policy.requestFor(AudioCue.hwandoAttack, volume: 0.8).pitch,
    );

    expect(pitches, [0.96, 0.98, 1.0, 1.02, 1.04, 0.96, 0.98]);
  });

  test('SFX pitch counters are independent per cue', () {
    final policy = AudioPlaybackPolicy();

    expect(policy.requestFor(AudioCue.hwandoAttack, volume: 0.8).pitch, 0.96);
    expect(policy.requestFor(AudioCue.hwandoAttack, volume: 0.8).pitch, 0.98);
    expect(policy.requestFor(AudioCue.bowAttack, volume: 0.8).pitch, 0.96);
  });

  test('music and UI always use neutral pitch', () {
    final policy = AudioPlaybackPolicy();

    for (var index = 0; index < 6; index += 1) {
      expect(policy.requestFor(AudioCue.battleMusic, volume: 0.7).pitch, 1.0);
      expect(policy.requestFor(AudioCue.uiConfirm, volume: 0.8).pitch, 1.0);
    }
  });

  test('request carries catalog channel and priority', () {
    final request = AudioPlaybackPolicy().requestFor(
      AudioCue.playerHit,
      volume: 0.8,
    );

    expect(request.cue, AudioCue.playerHit);
    expect(request.channel, AudioChannel.sfx);
    expect(request.priority, AudioPriority.high);
    expect(request.volume, 0.8);
  });

  test('request clamps volume to the normalized range', () {
    final policy = AudioPlaybackPolicy();

    expect(policy.requestFor(AudioCue.battleMusic, volume: 2).volume, 1);
    expect(policy.requestFor(AudioCue.uiBack, volume: -1).volume, 0);
  });
}
