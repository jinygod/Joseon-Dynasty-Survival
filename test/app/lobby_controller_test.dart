import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/lobby_controller.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/models/meta_progress.dart';
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

  test('marking compendium entries seen persists namespaced keys', () async {
    final store = _MemorySaveStore(SaveState.defaults());
    final controller = LobbyController(store: store);
    await controller.load();

    await controller.markCompendiumEntriesSeen({
      'character:$rookieConstable',
      'weapon:$hwandoSlash',
    });

    expect(store.value.seenCompendiumEntryIds, {
      'character:$rookieConstable',
      'weapon:$hwandoSlash',
    });
  });

  test('cannot persist a locked stage selection', () async {
    final store = _MemorySaveStore(SaveState.defaults());
    final controller = LobbyController(store: store);
    await controller.load();

    await controller.selectStage(plagueMarket);

    expect(controller.state.selectedStageId, moonlitAbandonedOffice);
    expect(store.value.selectedStageId, moonlitAbandonedOffice);
  });

  test(
    'reset waits for pending saves and becomes the authoritative state',
    () async {
      final store = _BlockingSaveStore(
        SaveState.defaults().copyWith(
          unlockedCharacterIds: {rookieConstable, exorcistDosa},
          wallet: const Wallet(coin: 500, spiritJade: 3),
        ),
      );
      final controller = LobbyController(store: store);
      await controller.load();

      final selection = controller.selectCharacter(exorcistDosa);
      await store.firstSaveStarted.future;
      final reset = controller.resetProgress();
      store.releaseFirstSave.complete();
      await Future.wait([selection, reset]);

      expect(controller.state.wallet, Wallet.empty);
      expect(
        controller.state.unlockedCharacterIds,
        SaveState.defaults().unlockedCharacterIds,
      );
      expect(store.value.wallet, Wallet.empty);
      expect(
        store.value.unlockedCharacterIds,
        SaveState.defaults().unlockedCharacterIds,
      );
    },
  );

  test(
    'dispose prevents an in-flight load from mutating or notifying',
    () async {
      final store = _BlockingLoadSaveStore();
      final controller = LobbyController(store: store);
      var notifications = 0;
      controller.addListener(() => notifications++);

      final loading = controller.load();
      expect(notifications, 1);
      controller.dispose();
      store.loadResult.complete(SaveState.defaults().copyWith(totalKills: 999));
      await loading;

      expect(controller.state.totalKills, 0);
      expect(notifications, 1);
    },
  );

  test('dispose prevents queued saves from starting', () async {
    final store = _BlockingSaveStore(
      SaveState.defaults().copyWith(
        unlockedCharacterIds: {rookieConstable, exorcistDosa},
        unlockedStageIds: {moonlitAbandonedOffice, plagueMarket},
      ),
    );
    final controller = LobbyController(store: store);
    await controller.load();

    final first = controller.selectCharacter(exorcistDosa);
    await store.firstSaveStarted.future;
    final queued = controller.selectStage(plagueMarket);
    controller.dispose();
    store.releaseFirstSave.complete();
    await Future.wait([first, queued]);

    expect(store.saveCount, 1);
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

class _BlockingSaveStore implements SaveStore {
  _BlockingSaveStore(this.value);

  SaveState value;
  final firstSaveStarted = Completer<void>();
  final releaseFirstSave = Completer<void>();
  var saveCount = 0;

  @override
  Future<SaveState> load() async => value;

  @override
  Future<void> save(SaveState state) async {
    saveCount += 1;
    if (saveCount == 1) {
      firstSaveStarted.complete();
      await releaseFirstSave.future;
    }
    value = state;
  }
}

class _BlockingLoadSaveStore implements SaveStore {
  final loadResult = Completer<SaveState>();

  @override
  Future<SaveState> load() => loadResult.future;

  @override
  Future<void> save(SaveState state) async {}
}
