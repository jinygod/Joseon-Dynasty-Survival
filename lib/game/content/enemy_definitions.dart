import 'ids.dart';

const slime = 'slime';
const bat = 'bat';
const armoredHusk = 'armored_husk';
const spitter = 'spitter';
const graveGolem = 'grave_golem';

const enemyDefinitions = <EnemyDefinition>[
  EnemyDefinition(
    id: slime,
    name: 'Slime',
    maxHealth: 12,
    moveSpeed: 45,
    damage: 8,
    experience: 1,
  ),
  EnemyDefinition(
    id: bat,
    name: 'Bat',
    maxHealth: 8,
    moveSpeed: 85,
    damage: 6,
    experience: 1,
  ),
  EnemyDefinition(
    id: armoredHusk,
    name: 'Armored Husk',
    maxHealth: 35,
    moveSpeed: 32,
    damage: 12,
    experience: 3,
  ),
  EnemyDefinition(
    id: spitter,
    name: 'Spitter',
    maxHealth: 20,
    moveSpeed: 38,
    damage: 10,
    experience: 2,
  ),
  EnemyDefinition(
    id: graveGolem,
    name: 'Grave Golem',
    maxHealth: 650,
    moveSpeed: 28,
    damage: 18,
    experience: 20,
    isBoss: true,
  ),
];
