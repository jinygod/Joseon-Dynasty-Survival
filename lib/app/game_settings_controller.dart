import 'package:flutter/foundation.dart';

import 'game_settings.dart';
import 'game_settings_repository.dart';

class GameSettingsDiagnostic {
  const GameSettingsDiagnostic({
    required this.operation,
    required this.error,
    required this.stackTrace,
  });

  final String operation;
  final Object error;
  final StackTrace stackTrace;
}

class GameSettingsController extends ChangeNotifier {
  factory GameSettingsController({
    required GameSettingsStore store,
    void Function(GameSettingsDiagnostic)? reportDiagnostic,
  }) => GameSettingsController._(store, reportDiagnostic);

  GameSettingsController._(this._store, this._reportDiagnostic);

  final GameSettingsStore _store;
  final void Function(GameSettingsDiagnostic)? _reportDiagnostic;
  GameSettings _settings = GameSettings.defaults;
  Future<void> _saveQueue = Future<void>.value();
  int _revision = 0;
  bool _disposed = false;

  GameSettings get settings => _settings;

  Future<void> load() async {
    if (_disposed) return;
    final startingRevision = _revision;
    try {
      final loaded = await _store.load();
      if (_disposed || startingRevision != _revision || loaded == _settings) {
        return;
      }
      _settings = loaded;
      notifyListeners();
    } catch (error, stackTrace) {
      _report('load', error, stackTrace);
    }
  }

  Future<void> setMusicVolume(double value) =>
      _update(_settings.copyWith(musicVolume: value));

  Future<void> setSfxVolume(double value) =>
      _update(_settings.copyWith(sfxVolume: value));

  Future<void> setVibrationEnabled(bool value) =>
      _update(_settings.copyWith(vibrationEnabled: value));

  Future<void> setScreenShakeEnabled(bool value) =>
      _update(_settings.copyWith(screenShakeEnabled: value));

  Future<void> setDamageNumbersEnabled(bool value) =>
      _update(_settings.copyWith(damageNumbersEnabled: value));

  Future<void> setUiScale(UiScale value) =>
      _update(_settings.copyWith(uiScale: value));

  Future<void> _update(GameSettings next) {
    if (_disposed || next == _settings) return Future<void>.value();
    _settings = next;
    _revision += 1;
    notifyListeners();
    final snapshot = _settings;
    final saving = _saveQueue.then((_) => _save(snapshot));
    _saveQueue = saving;
    return saving;
  }

  Future<void> _save(GameSettings snapshot) async {
    try {
      await _store.save(snapshot);
    } catch (error, stackTrace) {
      _report('save', error, stackTrace);
    }
  }

  void _report(String operation, Object error, StackTrace stackTrace) {
    try {
      _reportDiagnostic?.call(
        GameSettingsDiagnostic(
          operation: operation,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    } on Object {
      // Diagnostics must never become a second settings failure.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
