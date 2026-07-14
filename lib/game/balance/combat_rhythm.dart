enum CombatRhythmPhaseId { learning, build, pressure, boss }

class CombatRhythmPhaseDefinition {
  const CombatRhythmPhaseDefinition({
    required this.id,
    required this.startSecond,
    required this.endSecond,
    required this.playerIntent,
    required this.balanceSignals,
  });

  final CombatRhythmPhaseId id;
  final int startSecond;
  final int endSecond;
  final String playerIntent;
  final List<String> balanceSignals;
}

const combatRhythmSampleIntervalSeconds = 15;
const combatRhythmEndSecond = 330;

const combatRhythmPhases = <CombatRhythmPhaseDefinition>[
  CombatRhythmPhaseDefinition(
    id: CombatRhythmPhaseId.learning,
    startSecond: 0,
    endSecond: 60,
    playerIntent: '이동과 자동 공격을 익히고 첫 레벨업을 경험한다.',
    balanceSignals: ['첫 레벨업 시점', '받은 피해', '적 동시 수'],
  ),
  CombatRhythmPhaseDefinition(
    id: CombatRhythmPhaseId.build,
    startSecond: 60,
    endSecond: 180,
    playerIntent: '무기와 증강 조합을 선택해 빌드의 방향을 만든다.',
    balanceSignals: ['레벨업 횟수', '무기별 피해량', '처치 속도'],
  ),
  CombatRhythmPhaseDefinition(
    id: CombatRhythmPhaseId.pressure,
    startSecond: 180,
    endSecond: 270,
    playerIntent: '증가한 밀도와 엘리트 압박을 완성된 빌드로 버틴다.',
    balanceSignals: ['체력 손실', '활성 적 수', '엘리트 생성 수'],
  ),
  CombatRhythmPhaseDefinition(
    id: CombatRhythmPhaseId.boss,
    startSecond: 270,
    endSecond: combatRhythmEndSecond,
    playerIntent: '잔여 적을 관리하며 보스 패턴을 읽고 처치한다.',
    balanceSignals: ['보스 체력 변화', '보스전 피해량', '사망 시점'],
  ),
];

CombatRhythmPhaseDefinition combatRhythmPhaseForSecond(num second) {
  if (!second.isFinite) {
    throw ArgumentError.value(second, 'second', 'must be finite');
  }
  final normalizedSecond = second < 0 ? 0 : second;
  return combatRhythmPhases.firstWhere(
    (phase) =>
        normalizedSecond >= phase.startSecond &&
        normalizedSecond < phase.endSecond,
    orElse: () => combatRhythmPhases.last,
  );
}

class CombatRhythmSnapshot {
  CombatRhythmSnapshot({
    required this.second,
    required this.activeEnemies,
    required this.spawnedEnemies,
    required this.eliteSpawns,
    required this.playerLevel,
    required this.healthFraction,
    required this.kills,
    required this.damageDealt,
    required this.damageTaken,
    required Map<String, double> weaponDamageTotals,
    required this.bossHealthFraction,
  }) : phase = combatRhythmPhaseForSecond(second),
       weaponDamageTotals = Map.unmodifiable(weaponDamageTotals) {
    if (second < 0 ||
        second > combatRhythmEndSecond ||
        second % combatRhythmSampleIntervalSeconds != 0) {
      throw ArgumentError.value(
        second,
        'second',
        'must be a 15-second sample from 0 through 330',
      );
    }
    for (final entry in <String, int>{
      'activeEnemies': activeEnemies,
      'spawnedEnemies': spawnedEnemies,
      'eliteSpawns': eliteSpawns,
      'playerLevel': playerLevel,
      'kills': kills,
    }.entries) {
      if (entry.value < 0) {
        throw ArgumentError.value(
          entry.value,
          entry.key,
          'must be non-negative',
        );
      }
    }
    _validateFraction(healthFraction, 'healthFraction');
    if (bossHealthFraction case final fraction?) {
      _validateFraction(fraction, 'bossHealthFraction');
    }
    _validateNonNegative(damageDealt, 'damageDealt');
    _validateNonNegative(damageTaken, 'damageTaken');
    for (final entry in weaponDamageTotals.entries) {
      _validateNonNegative(entry.value, 'weaponDamageTotals[${entry.key}]');
    }
  }

  final int second;
  final CombatRhythmPhaseDefinition phase;
  final int activeEnemies;
  final int spawnedEnemies;
  final int eliteSpawns;
  final int playerLevel;
  final double healthFraction;
  final int kills;
  final double damageDealt;
  final double damageTaken;
  final Map<String, double> weaponDamageTotals;
  final double? bossHealthFraction;

  Map<String, Object?> toJson() => {
    'second': second,
    'phase': phase.id.name,
    'activeEnemies': activeEnemies,
    'spawnedEnemies': spawnedEnemies,
    'eliteSpawns': eliteSpawns,
    'playerLevel': playerLevel,
    'healthFraction': healthFraction,
    'kills': kills,
    'damageDealt': damageDealt,
    'damageTaken': damageTaken,
    'weaponDamageTotals': weaponDamageTotals,
    'bossHealthFraction': bossHealthFraction,
  };

  static void _validateFraction(double value, String name) {
    if (!value.isFinite || value < 0 || value > 1) {
      throw ArgumentError.value(value, name, 'must be between 0 and 1');
    }
  }

  static void _validateNonNegative(double value, String name) {
    if (!value.isFinite || value < 0) {
      throw ArgumentError.value(value, name, 'must be finite and non-negative');
    }
  }
}
