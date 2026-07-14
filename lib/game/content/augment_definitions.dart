import 'ids.dart';

const martialTraining = 'martial_training';
const quickStep = 'quick_step';
const innerBreath = 'inner_breath';
const jangseungBlessing = 'jangseung_blessing';
const hawkEye = 'hawk_eye';
const herbalTonic = 'herbal_tonic';
const rapidReload = 'rapid_reload';
const goblinFire = 'goblin_fire';
const powderMastery = 'powder_mastery';
const lastStand = 'last_stand';
const ritualShortcut = 'ritual_shortcut';
const heavyStrike = 'heavy_strike';

const augmentDefinitions = <AugmentDefinition>[
  AugmentDefinition(
    id: martialTraining,
    name: '무예 단련',
    maxLevel: 5,
    startsUnlocked: true,
    effectDescription: '모든 무기 피해 +12%',
  ),
  AugmentDefinition(
    id: quickStep,
    name: '빠른 발놀림',
    maxLevel: 5,
    startsUnlocked: true,
    effectDescription: '이동 속도 +8%',
  ),
  AugmentDefinition(
    id: innerBreath,
    name: '내공 호흡',
    maxLevel: 5,
    startsUnlocked: true,
    effectDescription: '최대 체력 +10, 체력 10 회복',
  ),
  AugmentDefinition(
    id: jangseungBlessing,
    name: '장승의 가호',
    maxLevel: 5,
    startsUnlocked: true,
    effectDescription: '경험치 획득 반경 +16',
  ),
  AugmentDefinition(
    id: hawkEye,
    name: '매의 눈',
    maxLevel: 5,
    startsUnlocked: true,
    effectDescription: '치명타 확률 +5%',
  ),
  AugmentDefinition(
    id: herbalTonic,
    name: '약초 주머니',
    maxLevel: 5,
    startsUnlocked: true,
    effectDescription: '체력 12 회복',
  ),
  AugmentDefinition(
    id: rapidReload,
    name: '빠른 장전',
    maxLevel: 5,
    startsUnlocked: false,
    effectDescription: '공격 재사용 시간 -10%',
  ),
  AugmentDefinition(
    id: goblinFire,
    name: '도깨비불',
    maxLevel: 5,
    startsUnlocked: false,
  ),
  AugmentDefinition(
    id: powderMastery,
    name: '화약 조제',
    maxLevel: 5,
    startsUnlocked: false,
    effectDescription: '폭발 범위와 투사체 크기 +10%',
  ),
  AugmentDefinition(
    id: lastStand,
    name: '최후의 저항',
    maxLevel: 3,
    startsUnlocked: false,
  ),
  AugmentDefinition(
    id: ritualShortcut,
    name: '의식 단축',
    maxLevel: 1,
    startsUnlocked: false,
  ),
  AugmentDefinition(
    id: heavyStrike,
    name: '강력한 일격',
    maxLevel: 5,
    startsUnlocked: false,
  ),
];

const firstStageAugmentIds = <AugmentId>[
  martialTraining,
  quickStep,
  rapidReload,
  innerBreath,
  hawkEye,
  herbalTonic,
  jangseungBlessing,
  powderMastery,
];
