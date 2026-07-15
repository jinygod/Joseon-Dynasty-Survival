import '../balance/meta_reward_balance.dart';
import '../models/run_result.dart';

class MetaRewardPolicy {
  const MetaRewardPolicy();

  int coinForRun(RunResult result) {
    return (MetaRewardBalance.participationCoin +
            result.survivalSeconds * MetaRewardBalance.coinPerSurvivalSecond +
            result.kills * MetaRewardBalance.coinPerKill +
            result.eliteKills * MetaRewardBalance.coinPerEliteKill +
            (result.bossDefeated ? MetaRewardBalance.bossDefeatCoin : 0))
        .floor();
  }

  bool shouldDropSpiritJade({
    required bool isElite,
    required bool isBoss,
    required bool firstBossRewardAvailable,
    required double roll,
  }) {
    if (isBoss && firstBossRewardAvailable) return true;
    if (isBoss) return roll < MetaRewardBalance.bossSpiritJadeDropChance;
    return isElite && roll < MetaRewardBalance.eliteSpiritJadeDropChance;
  }
}
