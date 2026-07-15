import 'audio_cue.dart';

class AudioSettings {
  factory AudioSettings({
    required double musicVolume,
    required double sfxVolume,
    required bool vibrationEnabled,
  }) => AudioSettings._(
    musicVolume: _normalize(musicVolume, defaults.musicVolume),
    sfxVolume: _normalize(sfxVolume, defaults.sfxVolume),
    vibrationEnabled: vibrationEnabled,
  );

  const AudioSettings._({
    required this.musicVolume,
    required this.sfxVolume,
    required this.vibrationEnabled,
  });

  static const defaults = AudioSettings._(
    musicVolume: 0.7,
    sfxVolume: 0.8,
    vibrationEnabled: true,
  );

  final double musicVolume;
  final double sfxVolume;
  final bool vibrationEnabled;

  AudioSettings copyWith({
    double? musicVolume,
    double? sfxVolume,
    bool? vibrationEnabled,
  }) => AudioSettings._(
    musicVolume: _normalize(musicVolume ?? this.musicVolume, this.musicVolume),
    sfxVolume: _normalize(sfxVolume ?? this.sfxVolume, this.sfxVolume),
    vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
  );

  double volumeFor(AudioChannel channel) => switch (channel) {
    AudioChannel.music => musicVolume,
    AudioChannel.sfx || AudioChannel.ui => sfxVolume,
  };

  static double _normalize(double value, double fallback) {
    if (!value.isFinite) return fallback;
    return value.clamp(0.0, 1.0).toDouble();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioSettings &&
          musicVolume == other.musicVolume &&
          sfxVolume == other.sfxVolume &&
          vibrationEnabled == other.vibrationEnabled;

  @override
  int get hashCode => Object.hash(musicVolume, sfxVolume, vibrationEnabled);
}
