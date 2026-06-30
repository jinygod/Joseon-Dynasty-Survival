import 'ids.dart';

const hwandoSlash = 'hwando_slash';
const gakgungShot = 'gakgung_shot';
const talismanThrow = 'talisman_throw';
const thunderCrashBomb = 'thunder_crash_bomb';
const jangseungWard = 'jangseung_ward';
const singijeonVolley = 'singijeon_volley';

const weaponDefinitions = <WeaponDefinition>[
  WeaponDefinition(
    id: hwandoSlash,
    name: 'Hwando Slash',
    element: ElementType.physical,
    maxLevel: 5,
    startsUnlocked: true,
  ),
  WeaponDefinition(
    id: gakgungShot,
    name: 'Gakgung Shot',
    element: ElementType.physical,
    maxLevel: 5,
    startsUnlocked: true,
  ),
  WeaponDefinition(
    id: talismanThrow,
    name: 'Talisman Throw',
    element: ElementType.magic,
    maxLevel: 5,
    startsUnlocked: false,
  ),
  WeaponDefinition(
    id: thunderCrashBomb,
    name: 'Thunder Crash Bomb',
    element: ElementType.fire,
    maxLevel: 5,
    startsUnlocked: false,
  ),
  WeaponDefinition(
    id: jangseungWard,
    name: 'Jangseung Ward',
    element: ElementType.magic,
    maxLevel: 5,
    startsUnlocked: false,
  ),
  WeaponDefinition(
    id: singijeonVolley,
    name: 'Singijeon Volley',
    element: ElementType.fire,
    maxLevel: 5,
    startsUnlocked: false,
  ),
];
