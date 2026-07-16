import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'game_settings.dart';

abstract interface class GameSettingsStore {
  Future<GameSettings> load();

  Future<void> save(GameSettings settings);
}

class GameSettingsRepository implements GameSettingsStore {
  GameSettingsRepository({this.preferences});

  static const settingsKey = 'settings.v1';
  static const legacyMusicVolumeKey = 'audio.musicVolume';
  static const legacySfxVolumeKey = 'audio.sfxVolume';
  static const legacyVibrationEnabledKey = 'audio.vibrationEnabled';

  final SharedPreferences? preferences;

  @override
  Future<GameSettings> load() async {
    final active = preferences ?? await SharedPreferences.getInstance();
    final unified = _readUnified(active.getString(settingsKey));
    if (unified != null) return unified;
    return GameSettings(
      musicVolume:
          _readDouble(active, legacyMusicVolumeKey) ??
          GameSettings.defaults.musicVolume,
      sfxVolume:
          _readDouble(active, legacySfxVolumeKey) ??
          GameSettings.defaults.sfxVolume,
      vibrationEnabled:
          _readBool(active, legacyVibrationEnabledKey) ??
          GameSettings.defaults.vibrationEnabled,
    );
  }

  @override
  Future<void> save(GameSettings settings) async {
    final active = preferences ?? await SharedPreferences.getInstance();
    final encoded = jsonEncode({
      'version': 1,
      'musicVolume': settings.musicVolume,
      'sfxVolume': settings.sfxVolume,
      'vibrationEnabled': settings.vibrationEnabled,
      'screenShakeEnabled': settings.screenShakeEnabled,
      'damageNumbersEnabled': settings.damageNumbersEnabled,
      'uiScale': settings.uiScale.name,
    });
    final results = await Future.wait([
      active.setString(settingsKey, encoded),
      active.setDouble(legacyMusicVolumeKey, settings.musicVolume),
      active.setDouble(legacySfxVolumeKey, settings.sfxVolume),
      active.setBool(legacyVibrationEnabledKey, settings.vibrationEnabled),
    ]);
    if (results.any((saved) => !saved)) {
      throw StateError('Game settings could not be persisted');
    }
  }

  GameSettings? _readUnified(String? raw) {
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic> || decoded['version'] != 1) {
        return null;
      }
      const defaults = GameSettings.defaults;
      return GameSettings(
        musicVolume:
            _jsonDouble(decoded['musicVolume']) ?? defaults.musicVolume,
        sfxVolume: _jsonDouble(decoded['sfxVolume']) ?? defaults.sfxVolume,
        vibrationEnabled: decoded['vibrationEnabled'] is bool
            ? decoded['vibrationEnabled'] as bool
            : defaults.vibrationEnabled,
        screenShakeEnabled: decoded['screenShakeEnabled'] is bool
            ? decoded['screenShakeEnabled'] as bool
            : defaults.screenShakeEnabled,
        damageNumbersEnabled: decoded['damageNumbersEnabled'] is bool
            ? decoded['damageNumbersEnabled'] as bool
            : defaults.damageNumbersEnabled,
        uiScale: UiScale.values.firstWhere(
          (value) => value.name == decoded['uiScale'],
          orElse: () => defaults.uiScale,
        ),
      );
    } on FormatException {
      return null;
    }
  }

  double? _readDouble(SharedPreferences preferences, String key) {
    try {
      return _jsonDouble(preferences.get(key));
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

  double? _jsonDouble(Object? value) {
    if (value is! num) return null;
    final number = value.toDouble();
    return number.isFinite ? number : null;
  }
}
