import 'ids.dart';
import 'weapon_definitions.dart';

const rookieConstable = 'rookie_constable';
const exorcistDosa = 'exorcist_dosa';

const characterDefinitions = <CharacterDefinition>[
  CharacterDefinition(
    id: rookieConstable,
    name: '신참 포졸',
    maxHealth: 105,
    moveSpeed: 125,
    damageMultiplier: 1,
    startingWeaponId: hwandoSlash,
  ),
  CharacterDefinition(
    id: exorcistDosa,
    name: '퇴마 도사',
    maxHealth: 85,
    moveSpeed: 115,
    damageMultiplier: 1.12,
    startingWeaponId: talismanThrow,
  ),
];
