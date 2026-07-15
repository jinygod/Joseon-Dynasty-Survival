import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/audio/audio_cue.dart';
import 'package:pixel_survivor/game/audio/audio_settings.dart';
import 'package:pixel_survivor/game/audio/audio_settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('defaults are 70 percent music 80 percent effects and vibration', () {
    expect(AudioSettings.defaults.musicVolume, 0.7);
    expect(AudioSettings.defaults.sfxVolume, 0.8);
    expect(AudioSettings.defaults.vibrationEnabled, isTrue);
  });

  test('copy clamps finite volumes and retains current value for NaN', () {
    final settings = AudioSettings.defaults.copyWith(
      musicVolume: 2,
      sfxVolume: -1,
    );

    expect(settings.musicVolume, 1);
    expect(settings.sfxVolume, 0);
    expect(settings.copyWith(musicVolume: double.nan).musicVolume, 1);
  });

  test('channel volume maps UI to the effects preference', () {
    final settings = AudioSettings(
      musicVolume: 0.25,
      sfxVolume: 0.6,
      vibrationEnabled: false,
    );

    expect(settings.volumeFor(AudioChannel.music), 0.25);
    expect(settings.volumeFor(AudioChannel.sfx), 0.6);
    expect(settings.volumeFor(AudioChannel.ui), 0.6);
  });

  test('repository round-trips all preferences', () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = AudioSettingsRepository(preferences: preferences);
    final expected = AudioSettings(
      musicVolume: 0.3,
      sfxVolume: 0.9,
      vibrationEnabled: false,
    );

    await repository.save(expected);

    final loaded = await AudioSettingsRepository(
      preferences: preferences,
    ).load();
    expect(loaded, expected);
  });

  test('missing and wrong-type fields recover independently', () async {
    SharedPreferences.setMockInitialValues({
      'audio.musicVolume': 'loud',
      'audio.sfxVolume': 0.4,
      'audio.vibrationEnabled': 7,
    });
    final repository = AudioSettingsRepository(
      preferences: await SharedPreferences.getInstance(),
    );

    final loaded = await repository.load();

    expect(loaded.musicVolume, 0.7);
    expect(loaded.sfxVolume, 0.4);
    expect(loaded.vibrationEnabled, isTrue);
  });

  test('non-finite values recover and finite outliers clamp', () async {
    SharedPreferences.setMockInitialValues({
      'audio.musicVolume': double.infinity,
      'audio.sfxVolume': 4.0,
      'audio.vibrationEnabled': false,
    });
    final repository = AudioSettingsRepository(
      preferences: await SharedPreferences.getInstance(),
    );

    final loaded = await repository.load();

    expect(loaded.musicVolume, 0.7);
    expect(loaded.sfxVolume, 1);
    expect(loaded.vibrationEnabled, isFalse);
  });
}
