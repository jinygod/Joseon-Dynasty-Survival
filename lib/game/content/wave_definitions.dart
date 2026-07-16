import 'dart:math';

import 'enemy_definitions.dart';
import 'ids.dart';
import 'stage_definitions.dart';

class WaveDefinition {
  const WaveDefinition({
    required this.startSecond,
    required this.endSecond,
    required this.enemyWeights,
    required this.eliteWeights,
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
  final Map<EnemyId, int> eliteWeights;
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

const moonlitAbandonedOfficeWaves = <WaveDefinition>[
  WaveDefinition(
    startSecond: 0,
    endSecond: 60,
    enemyWeights: {plagueRatSwarm: 1},
    eliteWeights: {},
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
    eliteWeights: {brokenJangseungSpirit: 1},
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
    eliteWeights: {brokenJangseungSpirit: 1},
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
    eliteWeights: {brokenJangseungSpirit: 1, sorrowfulMaidenGhost: 1},
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
    eliteWeights: {brokenJangseungSpirit: 1, sorrowfulMaidenGhost: 1},
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
    eliteWeights: {brokenJangseungSpirit: 1, sorrowfulMaidenGhost: 1},
    startSpawnsPerSecond: 1.5,
    endSpawnsPerSecond: 2.2,
    groupSize: 4,
    startEliteChance: 0.05,
    endEliteChance: 0.08,
    startMaxActiveEnemies: 48,
    endMaxActiveEnemies: 64,
  ),
];

const waveDefinitions = moonlitAbandonedOfficeWaves;

const plagueMarketWaves = <WaveDefinition>[
  WaveDefinition(
    startSecond: 0,
    endSecond: 60,
    enemyWeights: {plagueRatSwarm: 4, plagueCrow: 1},
    eliteWeights: {},
    startSpawnsPerSecond: 1.15,
    endSpawnsPerSecond: 1.6,
    groupSize: 4,
    startEliteChance: 0,
    endEliteChance: 0.03,
    startMaxActiveEnemies: 36,
    endMaxActiveEnemies: 45,
  ),
  WaveDefinition(
    startSecond: 60,
    endSecond: 120,
    enemyWeights: {plagueRatSwarm: 4, plagueCrow: 3, bandit: 1},
    eliteWeights: {blackHatAssassin: 1},
    startSpawnsPerSecond: 1.6,
    endSpawnsPerSecond: 2.2,
    groupSize: 4,
    startEliteChance: 0.03,
    endEliteChance: 0.06,
    startMaxActiveEnemies: 45,
    endMaxActiveEnemies: 58,
  ),
  WaveDefinition(
    startSecond: 120,
    endSecond: 180,
    enemyWeights: {
      plagueRatSwarm: 3,
      plagueCrow: 3,
      rottenHerbalist: 2,
      graveEmber: 1,
    },
    eliteWeights: {blackHatAssassin: 1},
    startSpawnsPerSecond: 2.2,
    endSpawnsPerSecond: 2.9,
    groupSize: 5,
    startEliteChance: 0.06,
    endEliteChance: 0.09,
    startMaxActiveEnemies: 58,
    endMaxActiveEnemies: 74,
  ),
  WaveDefinition(
    startSecond: 180,
    endSecond: 240,
    enemyWeights: {
      plagueRatSwarm: 2,
      plagueCrow: 3,
      rottenHerbalist: 3,
      graveEmber: 2,
      dokkaebi: 1,
    },
    eliteWeights: {blackHatAssassin: 2, brokenJangseungSpirit: 1},
    startSpawnsPerSecond: 2.9,
    endSpawnsPerSecond: 3.7,
    groupSize: 5,
    startEliteChance: 0.09,
    endEliteChance: 0.14,
    startMaxActiveEnemies: 74,
    endMaxActiveEnemies: 88,
  ),
  WaveDefinition(
    startSecond: 240,
    endSecond: 270,
    enemyWeights: {
      plagueCrow: 3,
      rottenHerbalist: 3,
      graveEmber: 2,
      dokkaebi: 2,
    },
    eliteWeights: {
      blackHatAssassin: 2,
      brokenJangseungSpirit: 1,
      sorrowfulMaidenGhost: 1,
    },
    startSpawnsPerSecond: 3.7,
    endSpawnsPerSecond: 4.4,
    groupSize: 6,
    startEliteChance: 0.14,
    endEliteChance: 0.19,
    startMaxActiveEnemies: 88,
    endMaxActiveEnemies: 102,
  ),
  WaveDefinition(
    startSecond: 270,
    endSecond: 330,
    enemyWeights: {plagueCrow: 2, rottenHerbalist: 3, graveEmber: 2},
    eliteWeights: {blackHatAssassin: 1, brokenJangseungSpirit: 1},
    startSpawnsPerSecond: 1.8,
    endSpawnsPerSecond: 2.5,
    groupSize: 4,
    startEliteChance: 0.07,
    endEliteChance: 0.11,
    startMaxActiveEnemies: 54,
    endMaxActiveEnemies: 72,
  ),
];

const stageWaveDefinitions = <String, List<WaveDefinition>>{
  moonlitAbandonedOffice: moonlitAbandonedOfficeWaves,
  plagueMarket: plagueMarketWaves,
};

List<WaveDefinition> waveDefinitionsForStage(String stageId) =>
    stageWaveDefinitions[stageId] ?? waveDefinitions;

WaveDefinition waveDefinitionForSecond(
  int second, {
  List<WaveDefinition> definitions = waveDefinitions,
}) {
  final elapsedSecond = second < 0 ? 0 : second;
  return definitions.firstWhere(
    (definition) =>
        elapsedSecond >= definition.startSecond &&
        elapsedSecond < definition.endSecond,
    orElse: () => definitions.last,
  );
}

WavePressure wavePressureForSecond(
  double elapsedSeconds, {
  List<WaveDefinition> definitions = waveDefinitions,
}) {
  final safeSecond = elapsedSeconds.isFinite ? max(0.0, elapsedSeconds) : 0.0;
  final definition = waveDefinitionForSecond(
    safeSecond.floor(),
    definitions: definitions,
  );
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

List<String> validateWaveContent() {
  final errors = <String>[];
  for (final stageEntry in stageWaveDefinitions.entries) {
    final definitions = stageEntry.value;
    if (definitions.isEmpty || definitions.first.startSecond != 0) {
      errors.add('Invalid wave start: ${stageEntry.key}');
    }
    for (var index = 0; index < definitions.length; index += 1) {
      final wave = definitions[index];
      if (wave.endSecond <= wave.startSecond ||
          (index > 0 && definitions[index - 1].endSecond != wave.startSecond)) {
        errors.add('Invalid wave range: ${stageEntry.key}:$index');
      }
      void validatePool(Map<EnemyId, int> pool, EnemyRank expectedRank) {
        for (final entry in pool.entries) {
          final definition = enemyDefinitionFor(entry.key);
          if (definition == null) {
            errors.add('Unknown wave enemy: ${entry.key}');
          } else if (definition.rank != expectedRank) {
            errors.add('Wrong wave rank: ${entry.key}');
          }
          if (entry.value < 1) errors.add('Invalid wave weight: ${entry.key}');
        }
      }

      validatePool(wave.enemyWeights, EnemyRank.normal);
      validatePool(wave.eliteWeights, EnemyRank.elite);
    }
  }
  return errors;
}

double _lerp(double start, double end, double progress) =>
    start + ((end - start) * progress);
