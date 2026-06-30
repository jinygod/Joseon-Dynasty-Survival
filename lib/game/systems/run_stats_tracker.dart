import '../models/run_result.dart';

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
    required int survivalSeconds,
    required int level,
    required bool wonWithLowHealth,
  }) {
    return RunResult(
      survivalSeconds: survivalSeconds,
      kills: _kills,
      level: level,
      bossDefeated: _bossDefeated,
      wonWithLowHealth: wonWithLowHealth,
      weaponKillCounts: const {},
    );
  }
}
