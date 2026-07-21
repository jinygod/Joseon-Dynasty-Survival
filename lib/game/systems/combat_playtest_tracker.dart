import '../models/combat_playtest_metrics.dart';

class CombatPlaytestTracker {
  CombatPlaytestTracker({this.isRepeatRun = false});

  static const lateRunStartSeconds = 240.0;
  static const masterKillWindowSeconds = 10.0;

  final bool isRepeatRun;
  final Map<String, int> _weaponOfferCounts = {};
  final Map<String, int> _weaponSelectionCounts = {};
  final Map<String, Map<int, double>> _weaponLevelTimes = {};
  final Map<String, double> _firstMasterAtSeconds = {};
  final Map<String, int> _masterKillsInTenSeconds = {};
  final Map<String, double> _firstSynergyAtSeconds = {};
  final Map<String, double> _synergyDamageTotals = {};
  final Map<String, double> _enemyRoleDamageToPlayer = {};
  final Map<String, int> _enemyRoleDeathCauses = {};
  final Set<String> _masteredWeaponIds = {};
  int _frameCount = 0;
  int _enemyCountTotal = 0;
  int _maxEnemyCount = 0;
  int _lateFrameCount = 0;
  double _lateFpsTotal = 0;
  double _lateMinFps = double.infinity;

  void recordOffer({required String weaponId}) {
    _increment(_weaponOfferCounts, weaponId);
  }

  void recordLevel({
    required String weaponId,
    required int level,
    required double atSeconds,
  }) {
    if (level <= 0 || !atSeconds.isFinite || atSeconds < 0) return;
    _increment(_weaponSelectionCounts, weaponId);
    (_weaponLevelTimes[weaponId] ??= {}).putIfAbsent(level, () => atSeconds);
  }

  void recordMasterActivation({
    required String weaponId,
    required double atSeconds,
  }) {
    if (!atSeconds.isFinite || atSeconds < 0) return;
    _masteredWeaponIds.add(weaponId);
    _firstMasterAtSeconds.putIfAbsent(weaponId, () => atSeconds);
    _masterKillsInTenSeconds.putIfAbsent(weaponId, () => 0);
  }

  void recordKill({
    required double atSeconds,
    required String? sourceId,
    required String enemyBehaviorId,
  }) {
    if (sourceId == null || !atSeconds.isFinite) return;
    final activatedAt = _firstMasterAtSeconds[sourceId];
    if (activatedAt == null ||
        atSeconds < activatedAt ||
        atSeconds > activatedAt + masterKillWindowSeconds) {
      return;
    }
    _increment(_masterKillsInTenSeconds, sourceId);
  }

  void recordSynergyDamage({
    required String synergyId,
    required double amount,
    required double atSeconds,
  }) {
    if (amount <= 0 || !amount.isFinite || !atSeconds.isFinite) return;
    _firstSynergyAtSeconds.putIfAbsent(synergyId, () => atSeconds);
    _synergyDamageTotals.update(
      synergyId,
      (total) => total + amount,
      ifAbsent: () => amount,
    );
  }

  void recordEnemyDamage({
    required String enemyBehaviorId,
    required double amount,
  }) {
    if (amount <= 0 || !amount.isFinite) return;
    _enemyRoleDamageToPlayer.update(
      enemyBehaviorId,
      (total) => total + amount,
      ifAbsent: () => amount,
    );
  }

  void recordEnemyDeath({required String enemyBehaviorId}) {
    _increment(_enemyRoleDeathCauses, enemyBehaviorId);
  }

  void recordFrame({
    required double dt,
    required int enemyCount,
    required double atSeconds,
  }) {
    if (enemyCount < 0 || !atSeconds.isFinite) return;
    _frameCount += 1;
    _enemyCountTotal += enemyCount;
    if (enemyCount > _maxEnemyCount) _maxEnemyCount = enemyCount;
    if (atSeconds < lateRunStartSeconds || !dt.isFinite || dt <= 0) return;
    final fps = 1 / dt;
    _lateFrameCount += 1;
    _lateFpsTotal += fps;
    if (fps < _lateMinFps) _lateMinFps = fps;
  }

  CombatPlaytestMetrics snapshot() => CombatPlaytestMetrics(
    weaponOfferCounts: Map.unmodifiable(_weaponOfferCounts),
    weaponSelectionCounts: Map.unmodifiable(_weaponSelectionCounts),
    weaponLevelTimes: Map.unmodifiable(
      _weaponLevelTimes.map(
        (weaponId, times) =>
            MapEntry(weaponId, Map<int, double>.unmodifiable(times)),
      ),
    ),
    firstMasterAtSeconds: Map.unmodifiable(_firstMasterAtSeconds),
    masterKillsInTenSeconds: Map.unmodifiable(_masterKillsInTenSeconds),
    firstSynergyAtSeconds: Map.unmodifiable(_firstSynergyAtSeconds),
    synergyDamageTotals: Map.unmodifiable(_synergyDamageTotals),
    enemyRoleDamageToPlayer: Map.unmodifiable(_enemyRoleDamageToPlayer),
    enemyRoleDeathCauses: Map.unmodifiable(_enemyRoleDeathCauses),
    averageEnemyCount: _frameCount == 0 ? 0 : _enemyCountTotal / _frameCount,
    maxEnemyCount: _maxEnemyCount,
    lateAverageFps: _lateFrameCount == 0 ? 0 : _lateFpsTotal / _lateFrameCount,
    lateMinFps: _lateFrameCount == 0 ? 0 : _lateMinFps,
    masteredWeaponIds: Set.unmodifiable(_masteredWeaponIds),
    isRepeatRun: isRepeatRun,
  );
}

void _increment(Map<String, int> values, String id) {
  values.update(id, (count) => count + 1, ifAbsent: () => 1);
}
