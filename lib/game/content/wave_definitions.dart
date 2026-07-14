import 'enemy_definitions.dart';
import 'ids.dart';

class WaveDefinition {
  const WaveDefinition({
    required this.startSecond,
    required this.endSecond,
    required this.enemyWeights,
    required this.spawnsPerSecond,
    required this.groupSize,
    required this.eliteChance,
    required this.maxActiveEnemies,
  });

  final int startSecond;
  final int endSecond;
  final Map<EnemyId, int> enemyWeights;
  final double spawnsPerSecond;
  final int groupSize;
  final double eliteChance;
  final int maxActiveEnemies;
}

const waveDefinitions = <WaveDefinition>[
  WaveDefinition(
    startSecond: 0,
    endSecond: 60,
    enemyWeights: {plagueRatSwarm: 1},
    spawnsPerSecond: 0.65,
    groupSize: 2,
    eliteChance: 0,
    maxActiveEnemies: 24,
  ),
  WaveDefinition(
    startSecond: 60,
    endSecond: 120,
    enemyWeights: {plagueRatSwarm: 3, bandit: 2},
    spawnsPerSecond: 0.90,
    groupSize: 2,
    eliteChance: 0.02,
    maxActiveEnemies: 32,
  ),
  WaveDefinition(
    startSecond: 120,
    endSecond: 180,
    enemyWeights: {plagueRatSwarm: 3, bandit: 3, vengefulSpirit: 2},
    spawnsPerSecond: 1.15,
    groupSize: 3,
    eliteChance: 0.04,
    maxActiveEnemies: 42,
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
    spawnsPerSecond: 1.45,
    groupSize: 3,
    eliteChance: 0.07,
    maxActiveEnemies: 54,
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
    spawnsPerSecond: 1.80,
    groupSize: 4,
    eliteChance: 0.10,
    maxActiveEnemies: 64,
  ),
  WaveDefinition(
    startSecond: 270,
    endSecond: 330,
    enemyWeights: {bandit: 2, vengefulSpirit: 2},
    spawnsPerSecond: 0.45,
    groupSize: 2,
    eliteChance: 0.03,
    maxActiveEnemies: 28,
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
