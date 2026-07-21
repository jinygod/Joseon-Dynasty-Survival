import 'run_outcome.dart';
import 'run_choice_record.dart';
import 'combat_playtest_metrics.dart';

class RunResult {
  const RunResult({
    required this.outcome,
    required this.survivalSeconds,
    required this.kills,
    required this.level,
    required this.bossDefeated,
    required this.wonWithLowHealth,
    required this.weaponKillCounts,
    required this.weaponLevels,
    this.weaponDamageTotals = const {},
    this.choices = const [],
    this.totalDamageTaken = 0,
    this.lastDamageSource,
    this.deathAtSeconds,
    this.eliteKills = 0,
    this.spiritJadeCollected = 0,
    this.combatMetrics = CombatPlaytestMetrics.empty,
  });

  final RunOutcome outcome;
  final int survivalSeconds;
  final int kills;
  final int level;
  final bool bossDefeated;
  final bool wonWithLowHealth;
  final Map<String, int> weaponKillCounts;
  final Map<String, int> weaponLevels;
  final Map<String, double> weaponDamageTotals;
  final List<RunChoiceRecord> choices;
  final double totalDamageTaken;
  final String? lastDamageSource;
  final int? deathAtSeconds;
  final int eliteKills;
  final int spiritJadeCollected;
  final CombatPlaytestMetrics combatMetrics;
}
