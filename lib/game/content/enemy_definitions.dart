import 'ids.dart';
import 'enemy_behavior_definitions.dart';

const plagueRatSwarm = 'plague_rat_swarm';
const bandit = 'bandit';
const dokkaebi = 'dokkaebi';
const sakkatSpecter = 'sakkat_specter';
const vengefulSpirit = 'vengeful_spirit';
const plagueCrow = 'plague_crow';
const spearBandit = 'spear_bandit';
const rottenHerbalist = 'rotten_herbalist';
const graveEmber = 'grave_ember';
const blackHatAssassin = 'black_hat_assassin';
const brokenJangseungSpirit = 'broken_jangseung_spirit';
const sorrowfulMaidenGhost = 'sorrowful_maiden_ghost';
const fallenGeneral = 'fallen_general';

const enemyDefinitions = <EnemyDefinition>[
  EnemyDefinition(
    id: plagueRatSwarm,
    name: '역병 쥐떼',
    maxHealth: 8,
    moveSpeed: 55,
    damage: 6,
    experience: 1,
    faction: EnemyFaction.plague,
    rank: EnemyRank.normal,
    behaviorProfileId: 'swarm',
    behaviorType: EnemyBehaviorType.swarm,
  ),
  EnemyDefinition(
    id: bandit,
    name: '산적',
    maxHealth: 18,
    moveSpeed: 60,
    damage: 8,
    experience: 1,
    faction: EnemyFaction.bandit,
    rank: EnemyRank.normal,
    behaviorProfileId: 'chase',
  ),
  EnemyDefinition(
    id: dokkaebi,
    name: '도깨비',
    maxHealth: 38,
    moveSpeed: 36,
    damage: 13,
    experience: 3,
    faction: EnemyFaction.anomaly,
    rank: EnemyRank.normal,
    behaviorProfileId: 'tank',
    behaviorType: EnemyBehaviorType.tank,
  ),
  EnemyDefinition(
    id: sakkatSpecter,
    name: '삿갓 망령',
    maxHealth: 25,
    moveSpeed: 42,
    damage: 9,
    experience: 3,
    faction: EnemyFaction.spirit,
    rank: EnemyRank.normal,
    behaviorProfileId: 'sakkat_ranged',
  ),
  EnemyDefinition(
    id: vengefulSpirit,
    name: '원혼',
    maxHealth: 22,
    moveSpeed: 45,
    damage: 10,
    experience: 2,
    faction: EnemyFaction.spirit,
    rank: EnemyRank.normal,
    behaviorProfileId: 'dash',
    behaviorType: EnemyBehaviorType.dash,
  ),
  EnemyDefinition(
    id: plagueCrow,
    name: '역병 까마귀',
    maxHealth: 16,
    moveSpeed: 58,
    damage: 8,
    experience: 2,
    faction: EnemyFaction.plague,
    rank: EnemyRank.normal,
    behaviorProfileId: 'crow_dive',
  ),
  EnemyDefinition(
    id: spearBandit,
    name: '창 든 산적',
    maxHealth: 26,
    moveSpeed: 48,
    damage: 11,
    experience: 2,
    faction: EnemyFaction.bandit,
    rank: EnemyRank.normal,
    behaviorProfileId: 'spear_thrust',
  ),
  EnemyDefinition(
    id: rottenHerbalist,
    name: '부패한 약초꾼',
    maxHealth: 24,
    moveSpeed: 38,
    damage: 7,
    experience: 3,
    faction: EnemyFaction.plague,
    rank: EnemyRank.normal,
    behaviorProfileId: 'poison_death_zone',
  ),
  EnemyDefinition(
    id: graveEmber,
    name: '무덤 불씨',
    maxHealth: 18,
    moveSpeed: 42,
    damage: 6,
    experience: 2,
    faction: EnemyFaction.spirit,
    rank: EnemyRank.normal,
    behaviorProfileId: 'grave_haste_aura',
  ),
  EnemyDefinition(
    id: blackHatAssassin,
    name: '검은 삿갓 자객',
    maxHealth: 160,
    moveSpeed: 65,
    damage: 16,
    experience: 12,
    faction: EnemyFaction.bandit,
    rank: EnemyRank.elite,
    behaviorProfileId: 'assassin_double_dash',
  ),
  EnemyDefinition(
    id: brokenJangseungSpirit,
    name: '깨진 장승령',
    maxHealth: 280,
    moveSpeed: 28,
    damage: 18,
    experience: 4,
    faction: EnemyFaction.anomaly,
    rank: EnemyRank.elite,
    behaviorProfileId: 'jangseung_shockwave',
    behaviorType: EnemyBehaviorType.tank,
  ),
  EnemyDefinition(
    id: sorrowfulMaidenGhost,
    name: '한 맺힌 처녀귀',
    maxHealth: 210,
    moveSpeed: 34,
    damage: 14,
    experience: 4,
    faction: EnemyFaction.spirit,
    rank: EnemyRank.elite,
    behaviorProfileId: 'maiden_scream',
  ),
  EnemyDefinition(
    id: fallenGeneral,
    name: '타락한 관군 대장',
    maxHealth: 900,
    moveSpeed: 26,
    damage: 20,
    experience: 20,
    faction: EnemyFaction.anomaly,
    rank: EnemyRank.boss,
    behaviorProfileId: 'tank',
    behaviorType: EnemyBehaviorType.tank,
  ),
];

EnemyDefinition? enemyDefinitionFor(EnemyId id) {
  for (final definition in enemyDefinitions) {
    if (definition.id == id) return definition;
  }
  return null;
}

List<String> validateEnemyContent([
  Iterable<EnemyDefinition> definitions = enemyDefinitions,
]) {
  final errors = <String>[];
  final ids = <EnemyId>{};
  final names = <String>{};
  for (final enemy in definitions) {
    if (!ids.add(enemy.id)) errors.add('Duplicate enemy id: ${enemy.id}');
    if (!names.add(enemy.name)) {
      errors.add('Duplicate enemy name: ${enemy.name}');
    }
    if (!enemy.maxHealth.isFinite || enemy.maxHealth <= 0) {
      errors.add('Invalid health: ${enemy.id}');
    }
    if (!enemy.moveSpeed.isFinite || enemy.moveSpeed < 0) {
      errors.add('Invalid speed: ${enemy.id}');
    }
    if (!enemy.damage.isFinite || enemy.damage < 0) {
      errors.add('Invalid damage: ${enemy.id}');
    }
    if (enemy.experience < 0) errors.add('Invalid experience: ${enemy.id}');
    if (!enemyBehaviorProfiles.containsKey(enemy.behaviorProfileId)) {
      errors.add('Missing behavior profile: ${enemy.behaviorProfileId}');
    }
  }
  return errors;
}
