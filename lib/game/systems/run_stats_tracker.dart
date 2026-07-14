import '../models/run_choice_record.dart';
import '../models/run_result.dart';
import '../models/run_outcome.dart';

class RunStatsTracker {
  int _kills = 0;
  bool _bossDefeated = false;
  final Map<String, int> _weaponKillCounts = {};
  final Map<String, double> _weaponDamageTotals = {};
  final List<RunChoiceRecord> _choices = [];
  double _totalDamageTaken = 0;
  String? _lastDamageSource;
  int? _deathAtSeconds;

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

  void recordWeaponDamage({required String weaponId, required double amount}) {
    if (amount <= 0) return;
    _weaponDamageTotals.update(
      weaponId,
      (total) => total + amount,
      ifAbsent: () => amount,
    );
  }

  void recordChoice(RunChoiceRecord choice) {
    _choices.add(choice);
  }

  void recordPlayerDamage({
    required double amount,
    required String sourceId,
    required int atSeconds,
    required bool isLethal,
  }) {
    if (amount <= 0) return;
    _totalDamageTaken += amount;
    _lastDamageSource = sourceId;
    if (isLethal) {
      _deathAtSeconds ??= atSeconds;
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
      weaponDamageTotals: Map.unmodifiable(_weaponDamageTotals),
      choices: List.unmodifiable(_choices),
      totalDamageTaken: _totalDamageTaken,
      lastDamageSource: _lastDamageSource,
      deathAtSeconds: _deathAtSeconds,
    );
  }
}
