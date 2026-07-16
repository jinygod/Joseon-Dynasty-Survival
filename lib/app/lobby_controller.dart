import 'package:flutter/foundation.dart';

import '../game/content/character_definitions.dart';
import '../game/content/stage_definitions.dart';
import '../game/systems/save_system.dart';

class LobbyController extends ChangeNotifier {
  LobbyController({required this.store});

  final SaveStore store;
  Future<void> _saveQueue = Future<void>.value();

  SaveState state = SaveState.defaults();
  bool loading = true;
  bool saving = false;
  String? _recoveryNotice;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      state = await store.load();
    } on Object {
      state = SaveState.defaults();
      _recoveryNotice = '저장 데이터를 복구해 기본 상태로 시작합니다.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> selectCharacter(String characterId) {
    if (!state.unlockedCharacterIds.contains(characterId) ||
        !characterDefinitions.any((character) => character.id == characterId)) {
      return Future<void>.value();
    }
    return _enqueue(
      (current) => current.copyWith(selectedCharacterId: characterId),
    );
  }

  Future<void> selectStage(String stageId) {
    if (!stageDefinitions.any((stage) => stage.id == stageId)) {
      return Future<void>.value();
    }
    return _enqueue((current) => current.copyWith(selectedStageId: stageId));
  }

  Future<bool> resetProgress() {
    final operation = _saveQueue.then((_) => _persistReset());
    _saveQueue = operation.then<void>((_) {});
    return operation;
  }

  String? takeRecoveryNotice() {
    final notice = _recoveryNotice;
    _recoveryNotice = null;
    return notice;
  }

  Future<void> _enqueue(SaveState Function(SaveState current) update) {
    final operation = _saveQueue.then((_) => _persist(update));
    _saveQueue = operation;
    return operation;
  }

  Future<void> _persist(SaveState Function(SaveState current) update) async {
    saving = true;
    notifyListeners();
    final next = update(state);
    try {
      await store.save(next);
      state = next;
    } on Object {
      _recoveryNotice = '저장하지 못했습니다. 다시 시도해 주세요.';
    } finally {
      saving = false;
      notifyListeners();
    }
  }

  Future<bool> _persistReset() async {
    saving = true;
    notifyListeners();
    final next = SaveState.defaults();
    try {
      await store.save(next);
      state = next;
      return true;
    } on Object {
      _recoveryNotice = '저장하지 못했습니다. 다시 시도해 주세요.';
      return false;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
