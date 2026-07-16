import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/game_settings.dart';
import 'package:pixel_survivor/app/game_settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('legacy audio keys migrate into unified defaults', () async {
    SharedPreferences.setMockInitialValues({
      GameSettingsRepository.legacyMusicVolumeKey: 0.25,
      GameSettingsRepository.legacySfxVolumeKey: 0.45,
      GameSettingsRepository.legacyVibrationEnabledKey: false,
    });
    final repository = GameSettingsRepository(
      preferences: await SharedPreferences.getInstance(),
    );

    final loaded = await repository.load();

    expect(loaded.musicVolume, 0.25);
    expect(loaded.sfxVolume, 0.45);
    expect(loaded.vibrationEnabled, isFalse);
    expect(loaded.screenShakeEnabled, isTrue);
    expect(loaded.damageNumbersEnabled, isTrue);
    expect(loaded.uiScale, UiScale.normal);
  });

  test('all six settings restore in a new repository instance', () async {
    final preferences = await SharedPreferences.getInstance();
    final first = GameSettingsRepository(preferences: preferences);
    final expected = GameSettings(
      musicVolume: 0.2,
      sfxVolume: 0.35,
      vibrationEnabled: false,
      screenShakeEnabled: false,
      damageNumbersEnabled: false,
      uiScale: UiScale.large,
    );

    await first.save(expected);
    final loaded = await GameSettingsRepository(
      preferences: preferences,
    ).load();

    expect(loaded, expected);
    expect(preferences.getDouble('audio.musicVolume'), 0.2);
    expect(preferences.getDouble('audio.sfxVolume'), 0.35);
    expect(preferences.getBool('audio.vibrationEnabled'), isFalse);
  });

  test('unified JSON wins and invalid fields recover independently', () async {
    SharedPreferences.setMockInitialValues({
      GameSettingsRepository.settingsKey: jsonEncode({
        'version': 1,
        'musicVolume': 4,
        'sfxVolume': 'loud',
        'vibrationEnabled': false,
        'screenShakeEnabled': false,
        'damageNumbersEnabled': false,
        'uiScale': 'large',
      }),
      GameSettingsRepository.legacyMusicVolumeKey: 0.1,
    });
    final repository = GameSettingsRepository(
      preferences: await SharedPreferences.getInstance(),
    );

    final loaded = await repository.load();

    expect(loaded.musicVolume, 1);
    expect(loaded.sfxVolume, GameSettings.defaults.sfxVolume);
    expect(loaded.vibrationEnabled, isFalse);
    expect(loaded.screenShakeEnabled, isFalse);
    expect(loaded.damageNumbersEnabled, isFalse);
    expect(loaded.uiScale, UiScale.large);
  });

  test('copy normalizes volumes and exposes UI scale factor', () {
    final settings = GameSettings.defaults.copyWith(
      musicVolume: double.nan,
      sfxVolume: -2,
      uiScale: UiScale.small,
    );

    expect(settings.musicVolume, GameSettings.defaults.musicVolume);
    expect(settings.sfxVolume, 0);
    expect(settings.uiScale.factor, 0.9);
    expect(UiScale.large.factor, 1.15);
  });
}
