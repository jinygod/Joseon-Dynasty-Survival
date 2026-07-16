import 'dart:math';

import '../content/ids.dart';
import '../content/wave_definitions.dart';

class SpawnRequest {
  const SpawnRequest({required this.enemyId, required this.isElite});

  final EnemyId enemyId;
  final bool isElite;
}

class WaveTickResult {
  const WaveTickResult({
    required this.spawnRequests,
    required this.spawnBoss,
    required this.maxActiveEnemies,
  });

  final List<SpawnRequest> spawnRequests;
  final bool spawnBoss;
  final int maxActiveEnemies;
}

class WaveDirector {
  factory WaveDirector({
    required Random random,
    List<WaveDefinition> definitions = waveDefinitions,
  }) => WaveDirector._(random, definitions);

  WaveDirector._(this._random, this._definitions);

  static const frameSpawnCap = 8;
  static const _bossSecond = 270;

  final Random _random;
  final List<WaveDefinition> _definitions;
  double _spawnBudget = 0;
  bool _hasRequestedBoss = false;

  WaveTickResult tick({
    required double elapsedSeconds,
    required double dt,
    required int activeEnemyCount,
  }) {
    final pressure = wavePressureForSecond(
      elapsedSeconds,
      definitions: _definitions,
    );
    _spawnBudget = min(
      frameSpawnCap.toDouble(),
      _spawnBudget + max(0, dt) * pressure.spawnsPerSecond,
    );

    final activeCapacity = max(0, pressure.maxActiveEnemies - activeEnemyCount);
    final spawnCount = min(
      min(_spawnBudget.floor(), activeCapacity),
      frameSpawnCap,
    );
    _spawnBudget -= spawnCount;

    return WaveTickResult(
      spawnRequests: _spawnRequests(pressure, spawnCount),
      spawnBoss: _shouldRequestBoss(elapsedSeconds),
      maxActiveEnemies: pressure.maxActiveEnemies,
    );
  }

  List<SpawnRequest> _spawnRequests(WavePressure pressure, int count) {
    final requests = <SpawnRequest>[];
    final definition = pressure.definition;
    EnemyId? previousEnemyId;
    var consecutiveCount = 0;

    for (var index = 0; index < count; index += 1) {
      final rolledElite =
          definition.eliteWeights.isNotEmpty &&
          _random.nextDouble() < pressure.eliteChance;
      if (rolledElite) {
        requests.add(
          SpawnRequest(
            enemyId: _selectEnemyId(definition.eliteWeights),
            isElite: true,
          ),
        );
        previousEnemyId = null;
        consecutiveCount = 0;
        continue;
      }
      if (consecutiveCount == 0 || consecutiveCount >= definition.groupSize) {
        previousEnemyId = _selectEnemyId(
          definition.enemyWeights,
          exclude: consecutiveCount >= definition.groupSize
              ? previousEnemyId
              : null,
        );
        consecutiveCount = 0;
      }

      requests.add(SpawnRequest(enemyId: previousEnemyId!, isElite: false));
      consecutiveCount += 1;
    }

    return requests;
  }

  EnemyId _selectEnemyId(Map<EnemyId, int> weights, {EnemyId? exclude}) {
    final entries = weights.entries
        .where((entry) => entry.key != exclude)
        .toList(growable: false);
    final candidates = entries.isEmpty ? weights.entries.toList() : entries;
    final totalWeight = candidates.fold<int>(
      0,
      (total, entry) => total + entry.value,
    );
    var roll = _random.nextInt(totalWeight);

    for (final entry in candidates) {
      if (roll < entry.value) {
        return entry.key;
      }
      roll -= entry.value;
    }

    return candidates.last.key;
  }

  bool _shouldRequestBoss(double elapsedSeconds) {
    if (_hasRequestedBoss || elapsedSeconds < _bossSecond) {
      return false;
    }

    _hasRequestedBoss = true;
    return true;
  }
}
