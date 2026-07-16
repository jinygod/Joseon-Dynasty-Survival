import 'package:flutter_test/flutter_test.dart';
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
}

class _MemorySettingsStore implements GameSettingsStore {
  GameSettings value = GameSettings.defaults;

  @override
  Future<GameSettings> load() async => value;

  @override
  Future<void> save(GameSettings settings) async => value = settings;
}
