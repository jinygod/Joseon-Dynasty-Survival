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
    name: '환도 베기',
    element: ElementType.physical,
    maxLevel: 5,
    startsUnlocked: true,
  ),
  WeaponDefinition(
    id: gakgungShot,
    name: '각궁 사격',
    element: ElementType.physical,
    maxLevel: 5,
    startsUnlocked: true,
  ),
  WeaponDefinition(
    id: talismanThrow,
    name: '부적 투척',
    element: ElementType.magic,
    maxLevel: 5,
    startsUnlocked: false,
  ),
  WeaponDefinition(
    id: thunderCrashBomb,
    name: '벽력진천뢰',
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
