import 'ids.dart';

const hwandoSlash = 'hwando_slash';
const gakgungShot = 'gakgung_shot';
const talismanThrow = 'talisman_throw';
const thunderCrashBomb = 'thunder_crash_bomb';
const jangseungWard = 'jangseung_ward';
const singijeonVolley = 'singijeon_volley';
const frostFlask = 'frost_flask';
const windThunderFan = 'wind_thunder_fan';

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
    name: '장승 결계',
    element: ElementType.magic,
    maxLevel: 5,
    startsUnlocked: false,
  ),
  WeaponDefinition(
    id: singijeonVolley,
    name: '신기전 일제사격',
    element: ElementType.fire,
    maxLevel: 5,
    startsUnlocked: false,
  ),
  WeaponDefinition(
    id: frostFlask,
    name: '서리 호리병',
    element: ElementType.ice,
    maxLevel: 5,
    startsUnlocked: false,
  ),
  WeaponDefinition(
    id: windThunderFan,
    name: '풍뢰 부채',
    element: ElementType.lightning,
    maxLevel: 5,
    startsUnlocked: false,
  ),
];
