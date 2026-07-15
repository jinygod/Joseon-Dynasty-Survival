import 'package:shared_preferences/shared_preferences.dart';

import 'audio_settings.dart';

abstract interface class AudioSettingsStore {
  Future<AudioSettings> load();

  Future<void> save(AudioSettings settings);
}

class AudioSettingsRepository implements AudioSettingsStore {
  AudioSettingsRepository({this.preferences});

  static const musicVolumeKey = 'audio.musicVolume';
  static const sfxVolumeKey = 'audio.sfxVolume';
  static const vibrationEnabledKey = 'audio.vibrationEnabled';

  final SharedPreferences? preferences;

  @override
  Future<AudioSettings> load() async {
    final activePreferences =
        preferences ?? await SharedPreferences.getInstance();
    return AudioSettings(
      musicVolume:
          _readDouble(activePreferences, musicVolumeKey) ??
          AudioSettings.defaults.musicVolume,
      sfxVolume:
          _readDouble(activePreferences, sfxVolumeKey) ??
          AudioSettings.defaults.sfxVolume,
      vibrationEnabled:
          _readBool(activePreferences, vibrationEnabledKey) ??
          AudioSettings.defaults.vibrationEnabled,
    );
  }

  @override
  Future<void> save(AudioSettings settings) async {
    final activePreferences =
        preferences ?? await SharedPreferences.getInstance();
    final results = await Future.wait([
      activePreferences.setDouble(musicVolumeKey, settings.musicVolume),
      activePreferences.setDouble(sfxVolumeKey, settings.sfxVolume),
      activePreferences.setBool(
        vibrationEnabledKey,
        settings.vibrationEnabled,
      ),
    ]);
    if (results.any((saved) => !saved)) {
      throw StateError('Audio settings could not be persisted');
    }
  }

  double? _readDouble(SharedPreferences preferences, String key) {
    try {
      final value = preferences.get(key);
      if (value is! num) return null;
      final number = value.toDouble();
      return number.isFinite ? number : null;
    } on Object {
      return null;
    }
  }

  bool? _readBool(SharedPreferences preferences, String key) {
    try {
      final value = preferences.get(key);
      return value is bool ? value : null;
    } on Object {
      return null;
    }
  }
}
