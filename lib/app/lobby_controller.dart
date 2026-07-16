import 'package:flutter/foundation.dart';

import '../backend/progress/progress_sync_controller.dart';
import '../game/content/character_definitions.dart';
import '../game/content/stage_definitions.dart';
import '../game/systems/save_system.dart';

class LobbyController extends ChangeNotifier {
  LobbyController({required this.store, this.progressSyncController});

  final SaveStore store;
  ProgressSyncController? progressSyncController;
  Future<void> _saveQueue = Future<void>.value();
  bool _disposed = false;
  int _generation = 0;

  SaveState state = SaveState.defaults();
  bool loading = true;
  bool saving = false;
  String? _recoveryNotice;

  Future<void> load() async {
    if (_disposed) return;
    final generation = _generation;
    loading = true;
    _notify();
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

  Future<void> syncNow() async {
    if (_disposed) return;
    final generation = _generation;
    final sync = progressSyncController;
    if (sync != null) await sync.syncNow();
    if (!_isActive(generation)) return;
    await load();
  }

  Future<void> selectCharacter(String characterId) {
    if (_disposed ||
        !state.unlockedCharacterIds.contains(characterId) ||
        !characterDefinitions.any((character) => character.id == characterId)) {
      return Future<void>.value();
    }
    return _enqueue(
      (current) => current.copyWith(selectedCharacterId: characterId),
    );
  }

  Future<void> selectStage(String stageId) {
    if (_disposed ||
        !state.unlockedStageIds.contains(stageId) ||
        !stageDefinitions.any((stage) => stage.id == stageId)) {
      return Future<void>.value();
    }
    return _enqueue((current) => current.copyWith(selectedStageId: stageId));
  }

  Future<void> markCompendiumEntriesSeen(Set<String> entryIds) {
    if (_disposed || entryIds.isEmpty) return Future<void>.value();
    return _enqueue(
      (current) => current.copyWith(
        seenCompendiumEntryIds: {
          ...current.seenCompendiumEntryIds,
          ...entryIds,
        },
      ),
    );
  }

  Future<bool> resetProgress() {
    if (_disposed) return Future<bool>.value(false);
    final generation = _generation;
    final operation = _saveQueue.then((_) => _persistReset(generation));
    _saveQueue = operation.then<void>((_) {});
    return operation;
  }

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

  Future<void> _enqueue(SaveState Function(SaveState current) update) {
    if (_disposed) return Future<void>.value();
    final generation = _generation;
    final operation = _saveQueue.then((_) => _persist(update, generation));
    _saveQueue = operation;
    return operation;
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
    progressSyncController = null;
    super.dispose();
  }
}
