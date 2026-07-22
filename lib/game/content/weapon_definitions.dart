import 'ids.dart';

const hwandoSlash = 'hwando_slash';
const gakgungShot = 'gakgung_shot';
const talismanThrow = 'talisman_throw';
const thunderCrashBomb = 'thunder_crash_bomb';
const jangseungWard = 'jangseung_ward';
const singijeonVolley = 'singijeon_volley';
const frostFlask = 'frost_flask';
const windThunderFan = 'wind_thunder_fan';
const matchlockCannon = 'matchlock_cannon';
const shamanBells = 'shaman_bells';
const dokkaebiChain = 'dokkaebi_chain';
const hawkSummon = 'hawk_summon';

const weaponDefinitions = <WeaponDefinition>[
  WeaponDefinition(
    id: hwandoSlash,
    name: '환도 베기',
    element: ElementType.physical,
    maxLevel: 6,
    startsUnlocked: true,
  ),
  WeaponDefinition(
    id: gakgungShot,
    name: '각궁 사격',
    element: ElementType.physical,
    maxLevel: 6,
    startsUnlocked: true,
  ),
  WeaponDefinition(
    id: talismanThrow,
    name: '부적 투척',
    element: ElementType.magic,
    maxLevel: 6,
    startsUnlocked: true,
  ),
  WeaponDefinition(
    id: thunderCrashBomb,
    name: '벽력진천뢰',
    element: ElementType.fire,
    maxLevel: 6,
    startsUnlocked: true,
  ),
  WeaponDefinition(
    id: jangseungWard,
    name: '장승 결계',
    element: ElementType.magic,
    maxLevel: 6,
    startsUnlocked: true,
  ),
  WeaponDefinition(
    id: singijeonVolley,
    name: '신기전 일제사격',
    element: ElementType.fire,
    maxLevel: 6,
    startsUnlocked: true,
  ),
  WeaponDefinition(
    id: frostFlask,
    name: '서리 호리병',
    element: ElementType.ice,
    maxLevel: 6,
    startsUnlocked: true,
  ),
  WeaponDefinition(
    id: windThunderFan,
    name: '풍뢰 부채',
    element: ElementType.lightning,
    maxLevel: 6,
    startsUnlocked: true,
  ),
  WeaponDefinition(
    id: matchlockCannon,
    name: '조총·화포',
    element: ElementType.fire,
    maxLevel: 6,
    startsUnlocked: true,
  ),
  WeaponDefinition(
    id: shamanBells,
    name: '무당 방울',
    element: ElementType.magic,
    maxLevel: 6,
    startsUnlocked: true,
  ),
  WeaponDefinition(
    id: dokkaebiChain,
    name: '도깨비 쇠사슬',
    element: ElementType.physical,
    maxLevel: 6,
    startsUnlocked: true,
  ),
  WeaponDefinition(
    id: hawkSummon,
    name: '매 부름',
    element: ElementType.physical,
    maxLevel: 6,
    startsUnlocked: true,
  ),
];
