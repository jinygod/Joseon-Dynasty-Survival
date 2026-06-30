import 'ids.dart';
import 'weapon_definitions.dart';

const apprenticeWanderer = 'apprentice_wanderer';
const ironPilgrim = 'iron_pilgrim';

const characterDefinitions = <CharacterDefinition>[
  CharacterDefinition(
    id: apprenticeWanderer,
    name: 'Apprentice Wanderer',
    maxHealth: 100,
    moveSpeed: 130,
    damageMultiplier: 1,
    startingWeaponId: magicBolt,
  ),
  CharacterDefinition(
    id: ironPilgrim,
    name: 'Iron Pilgrim',
    maxHealth: 140,
    moveSpeed: 105,
    damageMultiplier: 0.95,
    startingWeaponId: bladeArc,
  ),
];
