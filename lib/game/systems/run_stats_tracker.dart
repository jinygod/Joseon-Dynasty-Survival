import '../models/run_result.dart';
import '../models/run_outcome.dart';

class RunStatsTracker {
  int _kills = 0;
  bool _bossDefeated = false;

  int get kills => _kills;
  bool get bossDefeated => _bossDefeated;

  void recordEnemyDefeat({required bool isBoss}) {
    _kills += 1;
    _bossDefeated = _bossDefeated || isBoss;
  }

  RunResult toRunResult({
    required RunOutcome outcome,
    required int survivalSeconds,
    required int level,
    required bool wonWithLowHealth,
    required Map<String, int> weaponLevels,
  }) {
    return RunResult(
      outcome: outcome,
      survivalSeconds: survivalSeconds,
      kills: _kills,
      level: level,
      bossDefeated: _bossDefeated,
      wonWithLowHealth: wonWithLowHealth,
      weaponKillCounts: const {},
      weaponLevels: weaponLevels,
    );
  }
}
