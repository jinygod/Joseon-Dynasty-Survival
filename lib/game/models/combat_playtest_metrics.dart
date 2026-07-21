// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';

@immutable
class CombatPlaytestMetrics {
  const CombatPlaytestMetrics({
    required Map<String, int> weaponOfferCounts,
    required Map<String, int> weaponSelectionCounts,
    required Map<String, Map<int, double>> weaponLevelTimes,
    required Map<String, double> firstMasterAtSeconds,
    required Map<String, int> masterKillsInTenSeconds,
    required Map<String, double> firstSynergyAtSeconds,
    required Map<String, double> synergyDamageTotals,
    required Map<String, double> enemyRoleDamageToPlayer,
    required Map<String, int> enemyRoleDeathCauses,
    required this.averageEnemyCount,
    required this.maxEnemyCount,
    required this.lateAverageFps,
    required this.lateMinFps,
    required Set<String> masteredWeaponIds,
    required this.isRepeatRun,
  }) : _weaponOfferCounts = weaponOfferCounts,
       _weaponSelectionCounts = weaponSelectionCounts,
       _weaponLevelTimes = weaponLevelTimes,
       _firstMasterAtSeconds = firstMasterAtSeconds,
       _masterKillsInTenSeconds = masterKillsInTenSeconds,
       _firstSynergyAtSeconds = firstSynergyAtSeconds,
       _synergyDamageTotals = synergyDamageTotals,
       _enemyRoleDamageToPlayer = enemyRoleDamageToPlayer,
       _enemyRoleDeathCauses = enemyRoleDeathCauses,
       _masteredWeaponIds = masteredWeaponIds;

  static const empty = CombatPlaytestMetrics(
    weaponOfferCounts: {},
    weaponSelectionCounts: {},
    weaponLevelTimes: {},
    firstMasterAtSeconds: {},
    masterKillsInTenSeconds: {},
    firstSynergyAtSeconds: {},
    synergyDamageTotals: {},
    enemyRoleDamageToPlayer: {},
    enemyRoleDeathCauses: {},
    averageEnemyCount: 0,
    maxEnemyCount: 0,
    lateAverageFps: 0,
    lateMinFps: 0,
    masteredWeaponIds: {},
    isRepeatRun: false,
  );

  final Map<String, int> _weaponOfferCounts;
  final Map<String, int> _weaponSelectionCounts;
  final Map<String, Map<int, double>> _weaponLevelTimes;
  final Map<String, double> _firstMasterAtSeconds;
  final Map<String, int> _masterKillsInTenSeconds;
  final Map<String, double> _firstSynergyAtSeconds;
  final Map<String, double> _synergyDamageTotals;
  final Map<String, double> _enemyRoleDamageToPlayer;
  final Map<String, int> _enemyRoleDeathCauses;
  final Set<String> _masteredWeaponIds;

  final double averageEnemyCount;
  final int maxEnemyCount;
  final double lateAverageFps;
  final double lateMinFps;
  final bool isRepeatRun;

  Map<String, int> get weaponOfferCounts =>
      Map<String, int>.unmodifiable(_weaponOfferCounts);
  Map<String, int> get weaponSelectionCounts =>
      Map<String, int>.unmodifiable(_weaponSelectionCounts);
  Map<String, Map<int, double>> get weaponLevelTimes =>
      Map<String, Map<int, double>>.unmodifiable(
        _weaponLevelTimes.map(
          (weaponId, times) =>
              MapEntry(weaponId, Map<int, double>.unmodifiable(times)),
        ),
      );
  Map<String, double> get firstMasterAtSeconds =>
      Map<String, double>.unmodifiable(_firstMasterAtSeconds);
  Map<String, int> get masterKillsInTenSeconds =>
      Map<String, int>.unmodifiable(_masterKillsInTenSeconds);
  Map<String, double> get firstSynergyAtSeconds =>
      Map<String, double>.unmodifiable(_firstSynergyAtSeconds);
  Map<String, double> get synergyDamageTotals =>
      Map<String, double>.unmodifiable(_synergyDamageTotals);
  Map<String, double> get enemyRoleDamageToPlayer =>
      Map<String, double>.unmodifiable(_enemyRoleDamageToPlayer);
  Map<String, int> get enemyRoleDeathCauses =>
      Map<String, int>.unmodifiable(_enemyRoleDeathCauses);
  Set<String> get masteredWeaponIds =>
      Set<String>.unmodifiable(_masteredWeaponIds);

  Map<String, dynamic> toJson() => {
    'weaponOfferCounts': _sortedMap(_weaponOfferCounts),
    'weaponSelectionCounts': _sortedMap(_weaponSelectionCounts),
    'weaponLevelTimes': {
      for (final weaponId in _weaponLevelTimes.keys.toList()..sort())
        weaponId: {
          for (final level
              in _weaponLevelTimes[weaponId]!.keys.toList()..sort())
            '$level': _weaponLevelTimes[weaponId]![level],
        },
    },
    'firstMasterAtSeconds': _sortedMap(_firstMasterAtSeconds),
    'masterKillsInTenSeconds': _sortedMap(_masterKillsInTenSeconds),
    'firstSynergyAtSeconds': _sortedMap(_firstSynergyAtSeconds),
    'synergyDamageTotals': _sortedMap(_synergyDamageTotals),
    'enemyRoleDamageToPlayer': _sortedMap(_enemyRoleDamageToPlayer),
    'enemyRoleDeathCauses': _sortedMap(_enemyRoleDeathCauses),
    'averageEnemyCount': averageEnemyCount,
    'maxEnemyCount': maxEnemyCount,
    'lateAverageFps': lateAverageFps,
    'lateMinFps': lateMinFps,
    'masteredWeaponIds': _masteredWeaponIds.toList()..sort(),
    'isRepeatRun': isRepeatRun,
  };

  factory CombatPlaytestMetrics.fromJson(Map<String, dynamic> json) {
    try {
      return CombatPlaytestMetrics(
        weaponOfferCounts: _intMap(json['weaponOfferCounts']),
        weaponSelectionCounts: _intMap(json['weaponSelectionCounts']),
        weaponLevelTimes: _levelTimes(json['weaponLevelTimes']),
        firstMasterAtSeconds: _doubleMap(json['firstMasterAtSeconds']),
        masterKillsInTenSeconds: _intMap(json['masterKillsInTenSeconds']),
        firstSynergyAtSeconds: _doubleMap(json['firstSynergyAtSeconds']),
        synergyDamageTotals: _doubleMap(json['synergyDamageTotals']),
        enemyRoleDamageToPlayer: _doubleMap(json['enemyRoleDamageToPlayer']),
        enemyRoleDeathCauses: _intMap(json['enemyRoleDeathCauses']),
        averageEnemyCount: _finiteDouble(json['averageEnemyCount']),
        maxEnemyCount: json['maxEnemyCount'] as int,
        lateAverageFps: _finiteDouble(json['lateAverageFps']),
        lateMinFps: _finiteDouble(json['lateMinFps']),
        masteredWeaponIds: _stringSet(json['masteredWeaponIds']),
        isRepeatRun: json['isRepeatRun'] as bool,
      );
    } on FormatException {
      rethrow;
    } on Object catch (error) {
      throw FormatException('Invalid combat playtest metrics', error);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CombatPlaytestMetrics &&
          mapEquals(_weaponOfferCounts, other._weaponOfferCounts) &&
          mapEquals(_weaponSelectionCounts, other._weaponSelectionCounts) &&
          _nestedMapEquals(_weaponLevelTimes, other._weaponLevelTimes) &&
          mapEquals(_firstMasterAtSeconds, other._firstMasterAtSeconds) &&
          mapEquals(_masterKillsInTenSeconds, other._masterKillsInTenSeconds) &&
          mapEquals(_firstSynergyAtSeconds, other._firstSynergyAtSeconds) &&
          mapEquals(_synergyDamageTotals, other._synergyDamageTotals) &&
          mapEquals(_enemyRoleDamageToPlayer, other._enemyRoleDamageToPlayer) &&
          mapEquals(_enemyRoleDeathCauses, other._enemyRoleDeathCauses) &&
          averageEnemyCount == other.averageEnemyCount &&
          maxEnemyCount == other.maxEnemyCount &&
          lateAverageFps == other.lateAverageFps &&
          lateMinFps == other.lateMinFps &&
          setEquals(_masteredWeaponIds, other._masteredWeaponIds) &&
          isRepeatRun == other.isRepeatRun;

  @override
  int get hashCode => Object.hashAll([
    ..._sortedEntries(_weaponOfferCounts),
    ..._sortedEntries(_weaponSelectionCounts),
    for (final key in _weaponLevelTimes.keys.toList()..sort())
      Object.hash(
        key,
        Object.hashAll([
          for (final level in _weaponLevelTimes[key]!.keys.toList()..sort())
            Object.hash(level, _weaponLevelTimes[key]![level]),
        ]),
      ),
    ..._sortedEntries(_firstMasterAtSeconds),
    ..._sortedEntries(_masterKillsInTenSeconds),
    ..._sortedEntries(_firstSynergyAtSeconds),
    ..._sortedEntries(_synergyDamageTotals),
    ..._sortedEntries(_enemyRoleDamageToPlayer),
    ..._sortedEntries(_enemyRoleDeathCauses),
    averageEnemyCount,
    maxEnemyCount,
    lateAverageFps,
    lateMinFps,
    ...(_masteredWeaponIds.toList()..sort()),
    isRepeatRun,
  ]);
}

Map<String, T> _sortedMap<T>(Map<String, T> source) => {
  for (final key in source.keys.toList()..sort()) key: source[key] as T,
};

Iterable<Object> _sortedEntries<T>(Map<String, T> source) sync* {
  for (final key in source.keys.toList()..sort()) {
    yield Object.hash(key, source[key]);
  }
}

bool _nestedMapEquals(
  Map<String, Map<int, double>> left,
  Map<String, Map<int, double>> right,
) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    if (!mapEquals(entry.value, right[entry.key])) return false;
  }
  return true;
}

Map<String, int> _intMap(Object? value) {
  if (value is! Map) throw const FormatException('Expected integer map');
  return Map<String, int>.unmodifiable(
    value.map((key, amount) {
      if (key is! String || amount is! int) {
        throw const FormatException('Invalid integer map entry');
      }
      return MapEntry(key, amount);
    }),
  );
}

Map<String, double> _doubleMap(Object? value) {
  if (value is! Map) throw const FormatException('Expected number map');
  return Map<String, double>.unmodifiable(
    value.map((key, amount) {
      if (key is! String) {
        throw const FormatException('Invalid number map key');
      }
      return MapEntry(key, _finiteDouble(amount));
    }),
  );
}

Map<String, Map<int, double>> _levelTimes(Object? value) {
  if (value is! Map) throw const FormatException('Expected level-time map');
  return Map<String, Map<int, double>>.unmodifiable(
    value.map((weaponId, times) {
      if (weaponId is! String || times is! Map) {
        throw const FormatException('Invalid level-time entry');
      }
      final parsed = <int, double>{};
      for (final entry in times.entries) {
        final level = entry.key is int
            ? entry.key as int
            : int.tryParse(entry.key as String? ?? '');
        if (level == null) {
          throw const FormatException('Invalid weapon level');
        }
        parsed[level] = _finiteDouble(entry.value);
      }
      return MapEntry(weaponId, Map<int, double>.unmodifiable(parsed));
    }),
  );
}

Set<String> _stringSet(Object? value) {
  if (value is! List || value.any((item) => item is! String)) {
    throw const FormatException('Expected string list');
  }
  return Set<String>.unmodifiable(value.cast<String>());
}

double _finiteDouble(Object? value) {
  if (value is! num || !value.isFinite) {
    throw const FormatException('Expected finite number');
  }
  return value.toDouble();
}
