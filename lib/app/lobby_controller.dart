import 'dart:async';

import 'package:flutter/foundation.dart';

import '../backend/progress/progress_sync_controller.dart';
import '../game/content/character_definitions.dart';
import '../game/content/stage_definitions.dart';
import '../game/systems/save_system.dart';

class LobbyController extends ChangeNotifier {
  LobbyController({required this.store, this.progressSyncController});

  final SaveStore store;
  ProgressSyncController? progressSyncController;
  Future<void> _operationQueue = Future<void>.value();
  final Completer<void> _disposeSignal = Completer<void>();
  bool _disposed = false;
  int _generation = 0;

  SaveState state = SaveState.defaults();
  bool loading = true;
  bool saving = false;
  String? _recoveryNotice;

  Future<void> load() {
    if (_disposed) return Future<void>.value();
    loading = true;
    _notify();
    return _enqueueOperation(
      (generation) => _load(generation, announce: false),
    );
  }

  Future<void> syncNow() => _enqueueOperation((generation) async {
    final sync = progressSyncController;
    if (sync != null) await sync.syncNow();
    if (!_isActive(generation)) return;
    await _load(generation, announce: true);
  });

  Future<void> _load(int generation, {required bool announce}) async {
    if (!_isActive(generation)) return;
    if (announce) {
      loading = true;
      _notify();
    }
    try {
      final loaded = await store.load();
      if (!_isActive(generation)) return;
      state = SaveState.fromJson(loaded.toJson());
    } on Object {
      if (!_isActive(generation)) return;
      state = SaveState.defaults();
      _recoveryNotice = '저장 데이터를 복구해 기본 상태로 시작합니다.';
    } finally {
      if (_isActive(generation)) {
        loading = false;
        _notify();
      }
    }
  }

  Future<void> selectCharacter(String characterId) {
    if (_disposed ||
        !state.unlockedCharacterIds.contains(characterId) ||
        !characterDefinitions.any((character) => character.id == characterId)) {
      return Future<void>.value();
    }
    return _enqueueOperation(
      (generation) => _persist(
        (current) => current.copyWith(selectedCharacterId: characterId),
        generation,
      ),
    );
  }

  Future<void> selectStage(String stageId) {
    if (_disposed ||
        !state.unlockedStageIds.contains(stageId) ||
        !stageDefinitions.any((stage) => stage.id == stageId)) {
      return Future<void>.value();
    }
    return _enqueueOperation(
      (generation) => _persist(
        (current) => current.copyWith(selectedStageId: stageId),
        generation,
      ),
    );
  }

  Future<void> markCompendiumEntriesSeen(Set<String> entryIds) {
    if (_disposed || entryIds.isEmpty) return Future<void>.value();
    return _enqueueOperation(
      (generation) => _persist(
        (current) => current.copyWith(
          seenCompendiumEntryIds: {
            ...current.seenCompendiumEntryIds,
            ...entryIds,
          },
        ),
        generation,
      ),
    );
  }

  Future<bool> resetProgress() =>
      _enqueueOperation((generation) => _persistReset(generation));

  Future<void> clearAccountLocalState() async {
    if (!await resetProgress()) {
      throw StateError('Failed to clear account-local save state');
    }
  }

  String? takeRecoveryNotice() {
    final notice = _recoveryNotice;
    _recoveryNotice = null;
    return notice;
  }

  Future<T> _enqueueOperation<T>(Future<T> Function(int generation) action) {
    if (_disposed) {
      return Future<T>.value(_disposedResult<T>());
    }
    final generation = _generation;
    final result = Completer<T>();
    _operationQueue = _operationQueue.then((_) async {
      if (!_isActive(generation)) {
        result.complete(_disposedResult<T>());
        return;
      }
      try {
        result.complete(await action(generation));
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return Future.any<T>([
      result.future,
      _disposeSignal.future.then((_) => _disposedResult<T>()),
    ]);
  }

  T _disposedResult<T>() {
    if (T == bool) return false as T;
    return null as T;
  }

  Future<void> _persist(
    SaveState Function(SaveState current) update,
    int generation,
  ) async {
    if (!_isActive(generation)) return;
    saving = true;
    _notify();
    final next = update(state);
    try {
      await store.save(next);
      if (!_isActive(generation)) return;
      state = next;
    } on Object {
      if (!_isActive(generation)) return;
      _recoveryNotice = '저장하지 못했습니다. 다시 시도해 주세요.';
    } finally {
      if (_isActive(generation)) {
        saving = false;
        _notify();
      }
    }
  }

  Future<bool> _persistReset(int generation) async {
    if (!_isActive(generation)) return false;
    saving = true;
    _notify();
    final next = SaveState.defaults();
    try {
      await store.save(next);
      if (!_isActive(generation)) return false;
      state = next;
      return true;
    } on Object {
      if (!_isActive(generation)) return false;
      _recoveryNotice = '저장하지 못했습니다. 다시 시도해 주세요.';
      return false;
    } finally {
      if (_isActive(generation)) {
        saving = false;
        _notify();
      }
    }
  }

  bool _isActive(int generation) => !_disposed && generation == _generation;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    _disposeSignal.complete();
    progressSyncController = null;
    super.dispose();
  }
}
