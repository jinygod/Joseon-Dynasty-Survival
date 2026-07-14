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
  factory WaveDirector({required Random random}) => WaveDirector._(random);

  WaveDirector._(this._random);

  static const _frameSpawnCap = 8;
  static const _bossSecond = 270;

  final Random _random;
  double _spawnBudget = 0;
  bool _hasRequestedBoss = false;

  WaveTickResult tick({
    required double elapsedSeconds,
    required double dt,
    required int activeEnemyCount,
  }) {
    final definition = waveDefinitionForSecond(elapsedSeconds.floor());
    _spawnBudget += dt * definition.spawnsPerSecond;

    final activeCapacity = max(
      0,
      definition.maxActiveEnemies - activeEnemyCount,
    );
    final spawnCount = min(
      min(_spawnBudget.floor(), activeCapacity),
      _frameSpawnCap,
    );
    _spawnBudget -= spawnCount;

    return WaveTickResult(
      spawnRequests: _spawnRequests(definition, spawnCount),
      spawnBoss: _shouldRequestBoss(elapsedSeconds),
      maxActiveEnemies: definition.maxActiveEnemies,
    );
  }

  List<SpawnRequest> _spawnRequests(WaveDefinition definition, int count) {
    final requests = <SpawnRequest>[];
    EnemyId? previousEnemyId;
    var consecutiveCount = 0;

    for (var index = 0; index < count; index += 1) {
      if (consecutiveCount == 0 || consecutiveCount >= definition.groupSize) {
        previousEnemyId = _selectEnemyId(
          definition.enemyWeights,
          exclude: consecutiveCount >= definition.groupSize
              ? previousEnemyId
              : null,
        );
        consecutiveCount = 0;
      }

      requests.add(
        SpawnRequest(
          enemyId: previousEnemyId!,
          isElite: _random.nextDouble() < definition.eliteChance,
        ),
      );
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
