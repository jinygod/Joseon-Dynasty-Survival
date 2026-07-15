import '../balance/meta_reward_balance.dart';
import '../models/meta_progress.dart';
import '../models/run_result.dart';
import 'meta_reward_policy.dart';
import 'progression_system.dart';
import 'save_system.dart';

class RunSettlement {
  const RunSettlement({
    required this.before,
    required this.after,
    required this.coinEarned,
    required this.spiritJadeEarned,
  });

  final SaveState before;
  final SaveState after;
  final int coinEarned;
  final int spiritJadeEarned;
}

class MetaProgressionService {
  MetaProgressionService({
    required this.saveStore,
    this.policy = const MetaRewardPolicy(),
    this.progression = const ProgressionSystem(),
  });

  static const firstBossRewardId = 'first_boss_spirit_jade';

  final SaveStore saveStore;
  final MetaRewardPolicy policy;
  final ProgressionSystem progression;

  Future<void> _tail = Future<void>.value();

  Future<T> _serialize<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (_, _) {});
    return result;
  }

  Future<bool> loadFirstBossRewardAvailability() {
    return _serialize(() async {
      final state = await saveStore.load();
      return !state.claimedRewardIds.contains(firstBossRewardId);
    });
  }

  Future<bool> collectSpiritJade({
    required String pickupId,
    bool claimsFirstBossReward = false,
  }) {
    return _serialize(() async {
      final before = await saveStore.load();
      if (before.claimedRewardIds.contains(pickupId)) return false;

      final claimedRewardIds = Set<String>.of(before.claimedRewardIds)
        ..add(pickupId);
      if (claimsFirstBossReward) {
        claimedRewardIds.add(firstBossRewardId);
      }
      final after = before.copyWith(
        claimedRewardIds: claimedRewardIds,
        wallet: Wallet(
          coin: before.wallet.coin,
          spiritJade:
              before.wallet.spiritJade + MetaRewardBalance.spiritJadePerDrop,
        ),
      );
      await saveStore.save(after);
      return true;
    });
  }

  Future<RunSettlement> settleRun(RunResult result) {
    return _serialize(() async {
      final before = await saveStore.load();
      final coinEarned = policy.coinForRun(result);
      final progressed = progression.applyRunResult(before, result);
      final after = progressed.copyWith(
        wallet: Wallet(
          coin: progressed.wallet.coin + coinEarned,
          spiritJade: progressed.wallet.spiritJade,
        ),
      );
      await saveStore.save(after);
      return RunSettlement(
        before: before,
        after: after,
        coinEarned: coinEarned,
        spiritJadeEarned: result.spiritJadeCollected,
      );
    });
  }
}
