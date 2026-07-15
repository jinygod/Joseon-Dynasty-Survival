import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/models/run_outcome.dart';
import 'package:pixel_survivor/game/models/run_result.dart';
import 'package:pixel_survivor/game/systems/meta_reward_policy.dart';

void main() {
  test('coin formula uses centralized reward inputs', () {
    final result = _runResult(
      survivalSeconds: 100,
      kills: 100,
      eliteKills: 5,
      bossDefeated: true,
    );

    expect(const MetaRewardPolicy().coinForRun(result), 175);
  });

  test('first boss reward is guaranteed', () {
    expect(
      const MetaRewardPolicy().shouldDropSpiritJade(
        isElite: false,
        isBoss: true,
        firstBossRewardAvailable: true,
        roll: .99,
      ),
      isTrue,
    );
  });

  test('normal drops use strict elite and boss thresholds', () {
    const policy = MetaRewardPolicy();

    expect(
      policy.shouldDropSpiritJade(
        isElite: true,
        isBoss: false,
        firstBossRewardAvailable: false,
        roll: .009,
      ),
      isTrue,
    );
    expect(
      policy.shouldDropSpiritJade(
        isElite: true,
        isBoss: false,
        firstBossRewardAvailable: false,
        roll: .01,
      ),
      isFalse,
    );
    expect(
      policy.shouldDropSpiritJade(
        isElite: false,
        isBoss: true,
        firstBossRewardAvailable: false,
        roll: .249,
      ),
      isTrue,
    );
    expect(
      policy.shouldDropSpiritJade(
        isElite: false,
        isBoss: true,
        firstBossRewardAvailable: false,
        roll: .25,
      ),
      isFalse,
    );
  });
}

RunResult _runResult({
  required int survivalSeconds,
  required int kills,
  required int eliteKills,
  required bool bossDefeated,
}) {
  return RunResult(
    outcome: bossDefeated ? RunOutcome.victory : RunOutcome.defeat,
    survivalSeconds: survivalSeconds,
    kills: kills,
    eliteKills: eliteKills,
    level: 1,
    bossDefeated: bossDefeated,
    wonWithLowHealth: false,
    weaponKillCounts: const {},
    weaponLevels: const {},
  );
}
