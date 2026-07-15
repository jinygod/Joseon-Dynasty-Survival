import 'dart:math';

import 'enemy_definitions.dart';
import 'ids.dart';

class WaveDefinition {
  const WaveDefinition({
    required this.startSecond,
    required this.endSecond,
    required this.enemyWeights,
    required this.startSpawnsPerSecond,
    required this.endSpawnsPerSecond,
    required this.groupSize,
    required this.startEliteChance,
    required this.endEliteChance,
    required this.startMaxActiveEnemies,
    required this.endMaxActiveEnemies,
  });

  final int startSecond;
  final int endSecond;
  final Map<EnemyId, int> enemyWeights;
  final double startSpawnsPerSecond;
  final double endSpawnsPerSecond;
  final int groupSize;
  final double startEliteChance;
  final double endEliteChance;
  final int startMaxActiveEnemies;
  final int endMaxActiveEnemies;
}

class WavePressure {
  const WavePressure({
    required this.definition,
    required this.spawnsPerSecond,
    required this.eliteChance,
    required this.maxActiveEnemies,
  });

  final WaveDefinition definition;
  final double spawnsPerSecond;
  final double eliteChance;
  final int maxActiveEnemies;
}

const waveDefinitions = <WaveDefinition>[
  WaveDefinition(
    startSecond: 0,
    endSecond: 60,
    enemyWeights: {plagueRatSwarm: 1},
    startSpawnsPerSecond: 1.0,
    endSpawnsPerSecond: 1.4,
    groupSize: 3,
    startEliteChance: 0,
    endEliteChance: 0.02,
    startMaxActiveEnemies: 32,
    endMaxActiveEnemies: 40,
  ),
  WaveDefinition(
    startSecond: 60,
    endSecond: 120,
    enemyWeights: {plagueRatSwarm: 3, bandit: 2},
    startSpawnsPerSecond: 1.4,
    endSpawnsPerSecond: 1.9,
    groupSize: 3,
    startEliteChance: 0.02,
    endEliteChance: 0.04,
    startMaxActiveEnemies: 40,
    endMaxActiveEnemies: 52,
  ),
  WaveDefinition(
    startSecond: 120,
    endSecond: 180,
    enemyWeights: {plagueRatSwarm: 3, bandit: 3, vengefulSpirit: 2},
    startSpawnsPerSecond: 1.9,
    endSpawnsPerSecond: 2.5,
    groupSize: 4,
    startEliteChance: 0.04,
    endEliteChance: 0.07,
    startMaxActiveEnemies: 52,
    endMaxActiveEnemies: 66,
  ),
  WaveDefinition(
    startSecond: 180,
    endSecond: 240,
    enemyWeights: {
      plagueRatSwarm: 2,
      bandit: 3,
      vengefulSpirit: 2,
      dokkaebi: 1,
    },
    startSpawnsPerSecond: 2.5,
    endSpawnsPerSecond: 3.2,
    groupSize: 5,
    startEliteChance: 0.07,
    endEliteChance: 0.11,
    startMaxActiveEnemies: 66,
    endMaxActiveEnemies: 80,
  ),
  WaveDefinition(
    startSecond: 240,
    endSecond: 270,
    enemyWeights: {
      plagueRatSwarm: 2,
      bandit: 2,
      vengefulSpirit: 2,
      dokkaebi: 2,
    },
    startSpawnsPerSecond: 3.2,
    endSpawnsPerSecond: 4.0,
    groupSize: 6,
    startEliteChance: 0.11,
    endEliteChance: 0.15,
    startMaxActiveEnemies: 80,
    endMaxActiveEnemies: 92,
  ),
  WaveDefinition(
    startSecond: 270,
    endSecond: 330,
    enemyWeights: {bandit: 2, vengefulSpirit: 2},
    startSpawnsPerSecond: 1.5,
    endSpawnsPerSecond: 2.2,
    groupSize: 4,
    startEliteChance: 0.05,
    endEliteChance: 0.08,
    startMaxActiveEnemies: 48,
    endMaxActiveEnemies: 64,
  ),
];

WaveDefinition waveDefinitionForSecond(int second) {
  final elapsedSecond = second < 0 ? 0 : second;
  return waveDefinitions.firstWhere(
    (definition) =>
        elapsedSecond >= definition.startSecond &&
        elapsedSecond < definition.endSecond,
    orElse: () => waveDefinitions.last,
  );
}

WavePressure wavePressureForSecond(double elapsedSeconds) {
  final safeSecond = elapsedSeconds.isFinite ? max(0.0, elapsedSeconds) : 0.0;
  final definition = waveDefinitionForSecond(safeSecond.floor());
  final duration = definition.endSecond - definition.startSecond;
  final progress = duration <= 0
      ? 1.0
      : ((safeSecond - definition.startSecond) / duration)
            .clamp(0, 1)
            .toDouble();

  return WavePressure(
    definition: definition,
    spawnsPerSecond: _lerp(
      definition.startSpawnsPerSecond,
      definition.endSpawnsPerSecond,
      progress,
    ),
    eliteChance: _lerp(
      definition.startEliteChance,
      definition.endEliteChance,
      progress,
    ),
    maxActiveEnemies: _lerp(
      definition.startMaxActiveEnemies.toDouble(),
      definition.endMaxActiveEnemies.toDouble(),
      progress,
    ).round(),
  );
}

double _lerp(double start, double end, double progress) =>
    start + ((end - start) * progress);
