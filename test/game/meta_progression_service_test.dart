import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/models/meta_progress.dart';
import 'package:pixel_survivor/game/content/ids.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';
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

  test(
    'loadUnlockProgress reports ordered clamped UI-ready progress',
    () async {
      final store = _MemorySaveStore(
        SaveState.defaults().copyWith(totalKills: 450),
      );
      final service = MetaProgressionService(saveStore: store);

      final progress = await service.loadUnlockProgress();
      final kill300 = progress.singleWhere(
        (item) => item.goalId == 'defeat_300_enemies',
      );
      final kill500 = progress.singleWhere(
        (item) => item.goalId == 'defeat_500_enemies',
      );

      expect(progress, hasLength(15));
      expect(kill300.currentValue, 450);
      expect(kill300.fraction, 1);
      expect(kill300.isCompleted, isTrue);
      expect(kill300.rewardType, UnlockRewardType.weapon);
      expect(kill500.fraction, 0.9);
      expect(kill500.isCompleted, isFalse);
      expect(
        (await store.load()).completedGoalIds,
        contains('defeat_300_enemies'),
      );
    },
  );

  test('settlement reports a stage reward once and persists it', () async {
    final store = _MemorySaveStore(SaveState.defaults());
    final service = MetaProgressionService(saveStore: store);
    final victory = _runResult(outcome: RunOutcome.victory);

    final first = await service.settleRun(victory);
    final second = await service.settleRun(victory);

    expect(first.unlocks.stageIds, [plagueMarket]);
    expect(first.after.unlockedStageIds, contains(plagueMarket));
    expect(second.unlocks.stageIds, isEmpty);
    expect((await store.load()).unlockedStageIds, contains(plagueMarket));
  });
}

RunResult _runResult({RunOutcome outcome = RunOutcome.defeat}) => RunResult(
  outcome: outcome,
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
