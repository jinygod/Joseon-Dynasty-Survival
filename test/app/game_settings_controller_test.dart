import 'package:flutter_test/flutter_test.dart';
import 'dart:async';
import 'package:pixel_survivor/app/game_settings.dart';
import 'package:pixel_survivor/app/game_settings_controller.dart';
import 'package:pixel_survivor/app/game_settings_repository.dart';

void main() {
  test('display settings save and restore in a new controller', () async {
    final store = _MemorySettingsStore();
    final first = GameSettingsController(store: store);

    await first.setScreenShakeEnabled(false);
    await first.setDamageNumbersEnabled(false);
    await first.setUiScale(UiScale.large);

    final second = GameSettingsController(store: store);
    await second.load();
    expect(second.settings.screenShakeEnabled, isFalse);
    expect(second.settings.damageNumbersEnabled, isFalse);
    expect(second.settings.uiScale, UiScale.large);
  });

  test(
    'change during load merges with persisted fields before saving',
    () async {
      final loadBarrier = Completer<void>();
      final store = _DelayedLoadStore(
        GameSettings(
          musicVolume: 0.2,
          sfxVolume: 0.35,
          vibrationEnabled: false,
          screenShakeEnabled: true,
          damageNumbersEnabled: false,
          uiScale: UiScale.large,
        ),
        loadBarrier.future,
      );
      final controller = GameSettingsController(store: store);

      final loading = controller.load();
      final changing = controller.setScreenShakeEnabled(false);
      loadBarrier.complete();
      await Future.wait([loading, changing]);

      expect(controller.settings.musicVolume, 0.2);
      expect(controller.settings.sfxVolume, 0.35);
      expect(controller.settings.vibrationEnabled, isFalse);
      expect(controller.settings.damageNumbersEnabled, isFalse);
      expect(controller.settings.uiScale, UiScale.large);
      expect(controller.settings.screenShakeEnabled, isFalse);
      expect(store.value, controller.settings);
    },
  );
}

class _MemorySettingsStore implements GameSettingsStore {
  GameSettings value = GameSettings.defaults;

  @override
  Future<GameSettings> load() async => value;

  @override
  Future<void> save(GameSettings settings) async => value = settings;
}

class _DelayedLoadStore implements GameSettingsStore {
  _DelayedLoadStore(this.value, this.loadBarrier);

  GameSettings value;
  final Future<void> loadBarrier;

  @override
  Future<GameSettings> load() async {
    final snapshot = value;
    await loadBarrier;
    return snapshot;
  }

  @override
  Future<void> save(GameSettings settings) async => value = settings;
}
