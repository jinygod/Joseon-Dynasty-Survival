import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/models/meta_progress.dart';
import 'package:pixel_survivor/game/models/run_outcome.dart';
import 'package:pixel_survivor/game/models/run_result.dart';
import 'package:pixel_survivor/game/systems/meta_progression_service.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';

void main() {
  test('same pickup id is persisted only once', () async {
    final store = _MemorySaveStore(SaveState.defaults());
    final service = MetaProgressionService(saveStore: store);

    expect(await service.collectSpiritJade(pickupId: 'drop-1'), isTrue);
    expect(await service.collectSpiritJade(pickupId: 'drop-1'), isFalse);

    final saved = await store.load();
    expect(saved.wallet.spiritJade, 1);
    expect(saved.claimedRewardIds, contains('drop-1'));
  });

  test('first boss claim is stored atomically with its jade', () async {
    final store = _MemorySaveStore(SaveState.defaults());
    final service = MetaProgressionService(saveStore: store);

    expect(await service.loadFirstBossRewardAvailability(), isTrue);
    await service.collectSpiritJade(
      pickupId: 'boss-drop',
      claimsFirstBossReward: true,
    );

    final saved = await store.load();
    expect(saved.wallet.spiritJade, 1);
    expect(
      saved.claimedRewardIds,
      contains(MetaProgressionService.firstBossRewardId),
    );
    expect(await service.loadFirstBossRewardAvailability(), isFalse);
  });

  test('settlement adds coin while preserving collected jade', () async {
    final store = _MemorySaveStore(
      SaveState.defaults().copyWith(
        wallet: const Wallet(coin: 10, spiritJade: 2),
      ),
    );
    final service = MetaProgressionService(saveStore: store);

    final settlement = await service.settleRun(_runResult());

    expect(settlement.after.wallet.coin, 10 + settlement.coinEarned);
    expect(settlement.after.wallet.spiritJade, 2);
    expect(settlement.spiritJadeEarned, 0);
    expect((await store.load()).totalKills, 100);
  });

  test(
    'concurrent pickup writes are serialized against the latest save',
    () async {
      final store = _MemorySaveStore(SaveState.defaults());
      final service = MetaProgressionService(saveStore: store);

      await Future.wait([
        service.collectSpiritJade(pickupId: 'drop-a'),
        service.collectSpiritJade(pickupId: 'drop-b'),
      ]);

      final saved = await store.load();
      expect(saved.wallet.spiritJade, 2);
      expect(saved.claimedRewardIds, containsAll(['drop-a', 'drop-b']));
    },
  );
}

RunResult _runResult() => const RunResult(
  outcome: RunOutcome.defeat,
  survivalSeconds: 100,
  kills: 100,
  level: 5,
  bossDefeated: false,
  wonWithLowHealth: false,
  weaponKillCounts: {},
  weaponLevels: {},
);

class _MemorySaveStore implements SaveStore {
  _MemorySaveStore(this.state);

  SaveState state;

  @override
  Future<SaveState> load() async => state;

  @override
  Future<void> save(SaveState state) async {
    this.state = state;
  }
}
