import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/lobby_controller.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';

void main() {
  test('loads persisted selections and serializes saves', () async {
    final store = _MemorySaveStore(
      SaveState.defaults().copyWith(
        unlockedCharacterIds: {rookieConstable, exorcistDosa},
      ),
    );
    final controller = LobbyController(store: store);

    await controller.load();
    await Future.wait([
      controller.selectCharacter(exorcistDosa),
      controller.selectStage(moonlitAbandonedOffice),
    ]);

    expect(controller.state.selectedCharacterId, exorcistDosa);
    expect(controller.state.selectedStageId, moonlitAbandonedOffice);
    expect(store.maxConcurrentSaves, 1);
  });

  test('load failure uses defaults and exposes recovery notice once', () async {
    final controller = LobbyController(store: _ThrowingSaveStore());

    await controller.load();

    expect(controller.state.selectedCharacterId, rookieConstable);
    expect(controller.takeRecoveryNotice(), isNotNull);
    expect(controller.takeRecoveryNotice(), isNull);
  });

  test('load normalizes selections that are not unlocked', () async {
    final store = _MemorySaveStore(
      SaveState.defaults().copyWith(
        selectedCharacterId: exorcistDosa,
        selectedStageId: plagueMarket,
      ),
    );
    final controller = LobbyController(store: store);

    await controller.load();

    expect(controller.state.selectedCharacterId, rookieConstable);
    expect(controller.state.selectedStageId, moonlitAbandonedOffice);
  });

  test('cannot persist a locked stage selection', () async {
    final store = _MemorySaveStore(SaveState.defaults());
    final controller = LobbyController(store: store);
    await controller.load();

    await controller.selectStage(plagueMarket);

    expect(controller.state.selectedStageId, moonlitAbandonedOffice);
    expect(store.value.selectedStageId, moonlitAbandonedOffice);
  });
}

class _MemorySaveStore implements SaveStore {
  _MemorySaveStore(this.value);

  SaveState value;
  int concurrentSaves = 0;
  int maxConcurrentSaves = 0;

  @override
  Future<SaveState> load() async => value;

  @override
  Future<void> save(SaveState state) async {
    concurrentSaves += 1;
    maxConcurrentSaves = maxConcurrentSaves < concurrentSaves
        ? concurrentSaves
        : maxConcurrentSaves;
    await Future<void>.delayed(Duration.zero);
    value = state;
    concurrentSaves -= 1;
  }
}

class _ThrowingSaveStore implements SaveStore {
  @override
  Future<SaveState> load() => Future.error(StateError('load failed'));

  @override
  Future<void> save(SaveState state) async {}
}
