import '../models/run_result.dart';
import '../models/run_outcome.dart';

class RunStatsTracker {
  int _kills = 0;
  bool _bossDefeated = false;
  final Map<String, int> _weaponKillCounts = {};

  int get kills => _kills;
  bool get bossDefeated => _bossDefeated;

  void recordEnemyDefeat({required bool isBoss, String? weaponId}) {
    _kills += 1;
    _bossDefeated = _bossDefeated || isBoss;
    if (weaponId != null) {
      _weaponKillCounts.update(
        weaponId,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
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
      weaponKillCounts: Map.unmodifiable(_weaponKillCounts),
      weaponLevels: Map.unmodifiable(weaponLevels),
    );
  }
}
