import 'ids.dart';
import 'weapon_definitions.dart';

const rookieConstable = 'rookie_constable';
const exorcistDosa = 'exorcist_dosa';

const characterDefinitions = <CharacterDefinition>[
  CharacterDefinition(
    id: rookieConstable,
    name: 'Rookie Constable',
    maxHealth: 105,
    moveSpeed: 125,
    damageMultiplier: 1,
    startingWeaponId: hwandoSlash,
  ),
  CharacterDefinition(
    id: exorcistDosa,
    name: 'Exorcist Dosa',
    maxHealth: 85,
    moveSpeed: 115,
    damageMultiplier: 1.12,
    startingWeaponId: talismanThrow,
  ),
];
