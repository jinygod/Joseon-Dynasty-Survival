import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/audio/audio_settings.dart';
import 'package:pixel_survivor/game/audio/audio_settings_controller.dart';
import 'package:pixel_survivor/game/audio/audio_settings_repository.dart';

void main() {
  test('load publishes persisted settings', () async {
    final store = MemoryAudioSettingsStore(
      AudioSettings(musicVolume: 0.2, sfxVolume: 0.4, vibrationEnabled: false),
    );
    final controller = AudioSettingsController(store: store);
    var notifications = 0;
    controller.addListener(() => notifications += 1);

    await controller.load();

    expect(controller.settings, store.settings);
    expect(notifications, 1);
  });

  test('setter publishes immediately before persistence completes', () async {
    final barrier = Completer<void>();
    final store = MemoryAudioSettingsStore(
      AudioSettings.defaults,
      saveBarrier: barrier.future,
    );
    final controller = AudioSettingsController(store: store);

    final saving = controller.setMusicVolume(0.3);

    expect(controller.settings.musicVolume, 0.3);
    expect(store.saveCount, 0);
    barrier.complete();
    await saving;
    expect(store.settings.musicVolume, 0.3);
  });

  test('saved settings load in a new controller instance', () async {
    final store = MemoryAudioSettingsStore(AudioSettings.defaults);
    final first = AudioSettingsController(store: store);
    await first.setMusicVolume(0.1);
    await first.setSfxVolume(0.5);
    await first.setVibrationEnabled(false);

    final second = AudioSettingsController(store: store);
    await second.load();

    expect(second.settings.musicVolume, 0.1);
    expect(second.settings.sfxVolume, 0.5);
    expect(second.settings.vibrationEnabled, isFalse);
  });

  test('equal normalized value does not notify or save', () async {
    final store = MemoryAudioSettingsStore(AudioSettings.defaults);
    final controller = AudioSettingsController(store: store);
    var notifications = 0;
    controller.addListener(() => notifications += 1);

    await controller.setMusicVolume(0.7);
    await controller.setSfxVolume(double.nan);
    await controller.setVibrationEnabled(true);

    expect(notifications, 0);
    expect(store.saveCount, 0);
  });

  test('rapid writes persist in call order', () async {
    final store = MemoryAudioSettingsStore(AudioSettings.defaults);
    final controller = AudioSettingsController(store: store);

    await Future.wait([
      controller.setMusicVolume(0.1),
      controller.setMusicVolume(0.2),
      controller.setMusicVolume(0.3),
    ]);

    expect(store.saved.map((settings) => settings.musicVolume), [
      0.1,
      0.2,
      0.3,
    ]);
    expect(store.settings.musicVolume, 0.3);
  });

  test('load and save failures are diagnosed and contained', () async {
    final diagnostics = <AudioSettingsDiagnostic>[];
    final store = MemoryAudioSettingsStore(
      AudioSettings.defaults,
      loadError: StateError('load failed'),
      saveError: StateError('save failed'),
    );
    final controller = AudioSettingsController(
      store: store,
      reportDiagnostic: diagnostics.add,
    );

    await controller.load();
    await controller.setMusicVolume(0.2);

    expect(controller.settings.musicVolume, 0.2);
    expect(diagnostics.map((value) => value.operation), ['load', 'save']);
  });

  test('diagnostic reporter errors never escape', () async {
    final controller = AudioSettingsController(
      store: MemoryAudioSettingsStore(
        AudioSettings.defaults,
        loadError: StateError('load failed'),
      ),
      reportDiagnostic: (_) => throw StateError('report failed'),
    );

    await controller.load();
  });
}

class MemoryAudioSettingsStore implements AudioSettingsStore {
  MemoryAudioSettingsStore(
    this.settings, {
    this.saveBarrier,
    this.loadError,
    this.saveError,
  });

  AudioSettings settings;
  final Future<void>? saveBarrier;
  final Object? loadError;
  final Object? saveError;
  final List<AudioSettings> saved = [];
  int saveCount = 0;

  @override
  Future<AudioSettings> load() async {
    if (loadError case final error?) throw error;
    return settings;
  }

  @override
  Future<void> save(AudioSettings settings) async {
    await saveBarrier;
    if (saveError case final error?) throw error;
    saveCount += 1;
    saved.add(settings);
    this.settings = settings;
  }
}
