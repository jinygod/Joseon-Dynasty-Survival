class RunResult {
  const RunResult({
    required this.survivalSeconds,
    required this.kills,
    required this.level,
    required this.bossDefeated,
    required this.wonWithLowHealth,
    required this.weaponKillCounts,
  });

  final int survivalSeconds;
  final int kills;
  final int level;
  final bool bossDefeated;
  final bool wonWithLowHealth;
  final Map<String, int> weaponKillCounts;
}
