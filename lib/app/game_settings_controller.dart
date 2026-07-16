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
  Future<void>? _activeLoad;
  bool _loading = false;
  final Set<_SettingField> _dirtyDuringLoad = {};
  bool _disposed = false;

  GameSettings get settings => _settings;

  Future<void> load() {
    if (_disposed) return Future<void>.value();
    final active = _activeLoad;
    if (active != null) return active;
    final loading = _performLoad();
    _activeLoad = loading;
    return loading.whenComplete(() {
      if (identical(_activeLoad, loading)) _activeLoad = null;
    });
  }

  Future<void> _performLoad() async {
    _loading = true;
    try {
      final loaded = await _store.load();
      if (_disposed) return;
      final hadLocalChanges = _dirtyDuringLoad.isNotEmpty;
      final merged = _mergeLoaded(loaded);
      if (merged != _settings) {
        _settings = merged;
        notifyListeners();
      }
      _loading = false;
      _dirtyDuringLoad.clear();
      if (hadLocalChanges) await _enqueueSave(_settings);
    } catch (error, stackTrace) {
      _report('load', error, stackTrace);
      final hadLocalChanges = _dirtyDuringLoad.isNotEmpty;
      _loading = false;
      _dirtyDuringLoad.clear();
      if (hadLocalChanges && !_disposed) await _enqueueSave(_settings);
    }
  }

  Future<void> setMusicVolume(double value) =>
      _update(_settings.copyWith(musicVolume: value), _SettingField.music);

  Future<void> setSfxVolume(double value) =>
      _update(_settings.copyWith(sfxVolume: value), _SettingField.sfx);

  Future<void> setVibrationEnabled(bool value) => _update(
    _settings.copyWith(vibrationEnabled: value),
    _SettingField.vibration,
  );

  Future<void> setScreenShakeEnabled(bool value) => _update(
    _settings.copyWith(screenShakeEnabled: value),
    _SettingField.screenShake,
  );

  Future<void> setDamageNumbersEnabled(bool value) => _update(
    _settings.copyWith(damageNumbersEnabled: value),
    _SettingField.damageNumbers,
  );

  Future<void> setUiScale(UiScale value) =>
      _update(_settings.copyWith(uiScale: value), _SettingField.uiScale);

  Future<void> _update(GameSettings next, _SettingField field) {
    if (_disposed || next == _settings) return Future<void>.value();
    _settings = next;
    notifyListeners();
    if (_loading) {
      _dirtyDuringLoad.add(field);
      return _activeLoad ?? Future<void>.value();
    }
    return _enqueueSave(_settings);
  }

  Future<void> _enqueueSave(GameSettings snapshot) {
    final saving = _saveQueue.then((_) => _save(snapshot));
    _saveQueue = saving;
    return saving;
  }

  GameSettings _mergeLoaded(GameSettings loaded) => GameSettings(
    musicVolume: _dirtyDuringLoad.contains(_SettingField.music)
        ? _settings.musicVolume
        : loaded.musicVolume,
    sfxVolume: _dirtyDuringLoad.contains(_SettingField.sfx)
        ? _settings.sfxVolume
        : loaded.sfxVolume,
    vibrationEnabled: _dirtyDuringLoad.contains(_SettingField.vibration)
        ? _settings.vibrationEnabled
        : loaded.vibrationEnabled,
    screenShakeEnabled: _dirtyDuringLoad.contains(_SettingField.screenShake)
        ? _settings.screenShakeEnabled
        : loaded.screenShakeEnabled,
    damageNumbersEnabled: _dirtyDuringLoad.contains(_SettingField.damageNumbers)
        ? _settings.damageNumbersEnabled
        : loaded.damageNumbersEnabled,
    uiScale: _dirtyDuringLoad.contains(_SettingField.uiScale)
        ? _settings.uiScale
        : loaded.uiScale,
  );

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

enum _SettingField {
  music,
  sfx,
  vibration,
  screenShake,
  damageNumbers,
  uiScale,
}
