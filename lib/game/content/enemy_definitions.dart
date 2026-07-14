import 'ids.dart';

const plagueRatSwarm = 'plague_rat_swarm';
const bandit = 'bandit';
const dokkaebi = 'dokkaebi';
const vengefulSpirit = 'vengeful_spirit';
const fallenGeneral = 'fallen_general';

const enemyDefinitions = <EnemyDefinition>[
  EnemyDefinition(
    id: plagueRatSwarm,
    name: '역병 쥐떼',
    maxHealth: 8,
    moveSpeed: 55,
    damage: 6,
    experience: 1,
    behaviorType: EnemyBehaviorType.swarm,
  ),
  EnemyDefinition(
    id: bandit,
    name: '산적',
    maxHealth: 18,
    moveSpeed: 60,
    damage: 8,
    experience: 1,
  ),
  EnemyDefinition(
    id: dokkaebi,
    name: '도깨비',
    maxHealth: 38,
    moveSpeed: 36,
    damage: 13,
    experience: 3,
    behaviorType: EnemyBehaviorType.tank,
  ),
  EnemyDefinition(
    id: vengefulSpirit,
    name: '원혼',
    maxHealth: 22,
    moveSpeed: 45,
    damage: 10,
    experience: 2,
    behaviorType: EnemyBehaviorType.dash,
  ),
  EnemyDefinition(
    id: fallenGeneral,
    name: '타락한 관군 대장',
    maxHealth: 700,
    moveSpeed: 26,
    damage: 20,
    experience: 20,
    behaviorType: EnemyBehaviorType.tank,
    isBoss: true,
  ),
];
