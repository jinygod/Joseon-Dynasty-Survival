import '../game/audio/audio_cue.dart';

enum UiScale {
  small(0.9),
  normal(1),
  large(1.15);

  const UiScale(this.factor);

  final double factor;
}

class GameSettings {
  factory GameSettings({
    required double musicVolume,
    required double sfxVolume,
    required bool vibrationEnabled,
    bool screenShakeEnabled = true,
    bool damageNumbersEnabled = true,
    UiScale uiScale = UiScale.normal,
  }) => GameSettings._(
    musicVolume: _normalize(musicVolume, defaults.musicVolume),
    sfxVolume: _normalize(sfxVolume, defaults.sfxVolume),
    vibrationEnabled: vibrationEnabled,
    screenShakeEnabled: screenShakeEnabled,
    damageNumbersEnabled: damageNumbersEnabled,
    uiScale: uiScale,
  );

  const GameSettings._({
    required this.musicVolume,
    required this.sfxVolume,
    required this.vibrationEnabled,
    required this.screenShakeEnabled,
    required this.damageNumbersEnabled,
    required this.uiScale,
  });

  static const defaults = GameSettings._(
    musicVolume: 0.7,
    sfxVolume: 0.8,
    vibrationEnabled: true,
    screenShakeEnabled: true,
    damageNumbersEnabled: true,
    uiScale: UiScale.normal,
  );

  final double musicVolume;
  final double sfxVolume;
  final bool vibrationEnabled;
  final bool screenShakeEnabled;
  final bool damageNumbersEnabled;
  final UiScale uiScale;

  GameSettings copyWith({
    double? musicVolume,
    double? sfxVolume,
    bool? vibrationEnabled,
    bool? screenShakeEnabled,
    bool? damageNumbersEnabled,
    UiScale? uiScale,
  }) => GameSettings._(
    musicVolume: _normalize(musicVolume ?? this.musicVolume, this.musicVolume),
    sfxVolume: _normalize(sfxVolume ?? this.sfxVolume, this.sfxVolume),
    vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    screenShakeEnabled: screenShakeEnabled ?? this.screenShakeEnabled,
    damageNumbersEnabled: damageNumbersEnabled ?? this.damageNumbersEnabled,
    uiScale: uiScale ?? this.uiScale,
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
      other is GameSettings &&
          musicVolume == other.musicVolume &&
          sfxVolume == other.sfxVolume &&
          vibrationEnabled == other.vibrationEnabled &&
          screenShakeEnabled == other.screenShakeEnabled &&
          damageNumbersEnabled == other.damageNumbersEnabled &&
          uiScale == other.uiScale;

  @override
  int get hashCode => Object.hash(
    musicVolume,
    sfxVolume,
    vibrationEnabled,
    screenShakeEnabled,
    damageNumbersEnabled,
    uiScale,
  );
}
