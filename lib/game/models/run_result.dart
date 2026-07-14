import 'run_outcome.dart';

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
  });

  final RunOutcome outcome;
  final int survivalSeconds;
  final int kills;
  final int level;
  final bool bossDefeated;
  final bool wonWithLowHealth;
  final Map<String, int> weaponKillCounts;
  final Map<String, int> weaponLevels;
}
