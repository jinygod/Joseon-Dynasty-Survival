import 'audio_cue.dart';

enum AudioPriority { low, normal, high, critical }

class AudioPlaybackRequest {
  const AudioPlaybackRequest({
    required this.cue,
    required this.channel,
    required this.priority,
    required this.pitch,
    required this.volume,
  });

  final AudioCue cue;
  final AudioChannel channel;
  final AudioPriority priority;
  final double pitch;
  final double volume;
}

class AudioPlaybackPolicy {
  static const _sfxPitchCycle = [0.96, 0.98, 1.0, 1.02, 1.04];

  final Map<AudioCue, int> _repeatCounts = {};

  static int limitFor(AudioChannel channel) => switch (channel) {
    AudioChannel.music => 1,
    AudioChannel.sfx => 8,
    AudioChannel.ui => 2,
  };

  static AudioPriority priorityFor(AudioCue cue) => switch (cue) {
    AudioCue.bossWarning || AudioCue.levelUp => AudioPriority.critical,
    AudioCue.playerHit || AudioCue.criticalHit => AudioPriority.high,
    AudioCue.experiencePickup || AudioCue.enemyDeath => AudioPriority.low,
    _ => AudioPriority.normal,
  };

  AudioPlaybackRequest requestFor(AudioCue cue, {required double volume}) {
    final channel = AudioCueCatalog.channelFor(cue);
    return AudioPlaybackRequest(
      cue: cue,
      channel: channel,
      priority: priorityFor(cue),
      pitch: _pitchFor(cue, channel),
      volume: volume.isFinite ? volume.clamp(0.0, 1.0).toDouble() : 0,
    );
  }

  double _pitchFor(AudioCue cue, AudioChannel channel) {
    if (channel != AudioChannel.sfx) return 1.0;
    final repeatCount = _repeatCounts[cue] ?? 0;
    _repeatCounts[cue] = repeatCount + 1;
    return _sfxPitchCycle[repeatCount % _sfxPitchCycle.length];
  }
}
