import 'dart:math';

import '../content/enemy_definitions.dart';
import '../content/ids.dart';
import '../content/wave_definitions.dart';
import '../systems/wave_director.dart';
import 'combat_rhythm.dart';

class WaveRegressionSimulator {
  const WaveRegressionSimulator({
    this.durationSeconds = 300,
    this.stepSeconds = 0.25,
  });

  final int durationSeconds;
  final double stepSeconds;

  WaveRegressionReport run(int seed) {
    if (durationSeconds <= 0 || stepSeconds <= 0 || !stepSeconds.isFinite) {
      throw ArgumentError('Duration and step must be positive and finite');
    }
    final director = WaveDirector(random: Random(seed));
    final active = <_ActiveSpawn>[];
    final phaseSpawnCounts = {
      for (final phase in CombatRhythmPhaseId.values) phase: 0,
    };
    final phaseEliteCounts = {
      for (final phase in CombatRhythmPhaseId.values) phase: 0,
    };
    final enemySpawnCounts = <EnemyId, int>{};
    var bossRequests = 0;
    var capViolations = 0;
    var overCapFrames = 0;
    var invalidPoolRequests = 0;
    var maxFrameSpawns = 0;
    var maxActiveEnemies = 0;

    final steps = (durationSeconds / stepSeconds).round();
    for (var index = 0; index < steps; index += 1) {
      final elapsed = index * stepSeconds;
      active.removeWhere((spawn) => spawn.expiresAt <= elapsed);
      final definition = waveDefinitionForSecond(elapsed.floor());
      final result = director.tick(
        elapsedSeconds: elapsed,
        dt: stepSeconds,
        activeEnemyCount: active.length,
      );
      if (result.spawnBoss) bossRequests += 1;
      maxFrameSpawns = max(maxFrameSpawns, result.spawnRequests.length);
      final activeCapacity = max(0, result.maxActiveEnemies - active.length);
      if (result.spawnRequests.length > activeCapacity) {
        capViolations += 1;
      }
      if (active.length + result.spawnRequests.length >
          result.maxActiveEnemies) {
        overCapFrames += 1;
      }

      final phase = combatRhythmPhaseForSecond(elapsed).id;
      for (final request in result.spawnRequests) {
        final expectedPool = request.isElite
            ? definition.eliteWeights
            : definition.enemyWeights;
        if (!expectedPool.containsKey(request.enemyId)) {
          invalidPoolRequests += 1;
        }
        phaseSpawnCounts[phase] = phaseSpawnCounts[phase]! + 1;
        if (request.isElite) {
          phaseEliteCounts[phase] = phaseEliteCounts[phase]! + 1;
        }
        enemySpawnCounts[request.enemyId] =
            (enemySpawnCounts[request.enemyId] ?? 0) + 1;
        active.add(
          _ActiveSpawn(expiresAt: elapsed + _lifetime(request.enemyId)),
        );
      }
      maxActiveEnemies = max(maxActiveEnemies, active.length);
    }

    return WaveRegressionReport(
      seed: seed,
      durationSeconds: durationSeconds,
      phaseSpawnCounts: phaseSpawnCounts,
      phaseEliteCounts: phaseEliteCounts,
      enemySpawnCounts: enemySpawnCounts,
      bossRequests: bossRequests,
      capViolations: capViolations,
      overCapFrames: overCapFrames,
      invalidPoolRequests: invalidPoolRequests,
      maxFrameSpawns: maxFrameSpawns,
      maxActiveEnemies: maxActiveEnemies,
    );
  }

  double _lifetime(EnemyId id) {
    final definition = enemyDefinitions.singleWhere((enemy) => enemy.id == id);
    return 18 + (definition.maxHealth / 5);
  }
}

class WaveRegressionReport {
  WaveRegressionReport({
    required this.seed,
    required this.durationSeconds,
    required Map<CombatRhythmPhaseId, int> phaseSpawnCounts,
    required Map<CombatRhythmPhaseId, int> phaseEliteCounts,
    required Map<EnemyId, int> enemySpawnCounts,
    required this.bossRequests,
    required this.capViolations,
    required this.overCapFrames,
    required this.invalidPoolRequests,
    required this.maxFrameSpawns,
    required this.maxActiveEnemies,
  }) : phaseSpawnCounts = Map.unmodifiable(phaseSpawnCounts),
       phaseEliteCounts = Map.unmodifiable(phaseEliteCounts),
       enemySpawnCounts = Map.unmodifiable(enemySpawnCounts);

  final int seed;
  final int durationSeconds;
  final Map<CombatRhythmPhaseId, int> phaseSpawnCounts;
  final Map<CombatRhythmPhaseId, int> phaseEliteCounts;
  final Map<EnemyId, int> enemySpawnCounts;
  final int bossRequests;
  final int capViolations;
  final int overCapFrames;
  final int invalidPoolRequests;
  final int maxFrameSpawns;
  final int maxActiveEnemies;

  int get totalSpawns =>
      phaseSpawnCounts.values.fold(0, (sum, count) => sum + count);

  String get fingerprint {
    final phases = CombatRhythmPhaseId.values
        .map(
          (phase) =>
              '${phase.name}:${phaseSpawnCounts[phase]}:'
              '${phaseEliteCounts[phase]}',
        )
        .join('|');
    final enemies = enemyDefinitions
        .where((enemy) => !enemy.isBoss)
        .map((enemy) => '${enemy.id}:${enemySpawnCounts[enemy.id] ?? 0}')
        .join('|');
    return '$phases#$enemies#$maxActiveEnemies#$overCapFrames';
  }

  Map<String, Object> toJson() => {
    'seed': seed,
    'durationSeconds': durationSeconds,
    'phaseSpawnCounts': {
      for (final entry in phaseSpawnCounts.entries) entry.key.name: entry.value,
    },
    'phaseEliteCounts': {
      for (final entry in phaseEliteCounts.entries) entry.key.name: entry.value,
    },
    'enemySpawnCounts': enemySpawnCounts,
    'bossRequests': bossRequests,
    'capViolations': capViolations,
    'overCapFrames': overCapFrames,
    'invalidPoolRequests': invalidPoolRequests,
    'maxFrameSpawns': maxFrameSpawns,
    'maxActiveEnemies': maxActiveEnemies,
    'totalSpawns': totalSpawns,
    'fingerprint': fingerprint,
  };
}

class _ActiveSpawn {
  const _ActiveSpawn({required this.expiresAt});

  final double expiresAt;
}
