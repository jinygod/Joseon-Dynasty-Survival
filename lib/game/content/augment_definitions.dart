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
const ironArmorTraining = 'iron_armor_training';
const scholarInsight = 'scholar_insight';
const bloodOath = 'blood_oath';
const ghostStep = 'ghost_step';

const augmentDefinitions = <AugmentDefinition>[
  AugmentDefinition(
    id: martialTraining,
    name: '무예 단련',
    maxLevel: 5,
    startsUnlocked: true,
    category: AugmentCategory.attack,
    effects: [
      AugmentEffect(stat: AugmentStat.weaponDamage, valuePerLevel: 0.12),
    ],
  ),
  AugmentDefinition(
    id: rapidReload,
    name: '빠른 장전',
    maxLevel: 5,
    startsUnlocked: false,
    category: AugmentCategory.attack,
    effects: [
      AugmentEffect(stat: AugmentStat.attackSpeed, valuePerLevel: 0.10),
    ],
  ),
  AugmentDefinition(
    id: hawkEye,
    name: '매의 눈',
    maxLevel: 5,
    startsUnlocked: true,
    category: AugmentCategory.attack,
    effects: [
      AugmentEffect(stat: AugmentStat.criticalChance, valuePerLevel: 0.05),
    ],
  ),
  AugmentDefinition(
    id: powderMastery,
    name: '화약 조제',
    maxLevel: 5,
    startsUnlocked: false,
    category: AugmentCategory.attack,
    effects: [AugmentEffect(stat: AugmentStat.weaponSize, valuePerLevel: 0.10)],
  ),
  AugmentDefinition(
    id: goblinFire,
    name: '도깨비불',
    maxLevel: 5,
    startsUnlocked: false,
    category: AugmentCategory.attack,
    effects: [AugmentEffect(stat: AugmentStat.fireDamage, valuePerLevel: 0.15)],
  ),
  AugmentDefinition(
    id: innerBreath,
    name: '내공 호흡',
    maxLevel: 5,
    startsUnlocked: true,
    category: AugmentCategory.survival,
    effects: [
      AugmentEffect(
        stat: AugmentStat.maxHealth,
        valuePerLevel: 10,
        application: AugmentEffectApplication.onAcquire,
      ),
      AugmentEffect(
        stat: AugmentStat.healing,
        valuePerLevel: 10,
        application: AugmentEffectApplication.onAcquire,
      ),
    ],
  ),
  AugmentDefinition(
    id: herbalTonic,
    name: '약초 주머니',
    maxLevel: 5,
    startsUnlocked: true,
    category: AugmentCategory.survival,
    effects: [
      AugmentEffect(
        stat: AugmentStat.healing,
        valuePerLevel: 12,
        application: AugmentEffectApplication.onAcquire,
      ),
    ],
  ),
  AugmentDefinition(
    id: ironArmorTraining,
    name: '철갑 수련',
    maxLevel: 5,
    startsUnlocked: true,
    category: AugmentCategory.survival,
    effects: [
      AugmentEffect(
        stat: AugmentStat.incomingContactDamage,
        valuePerLevel: -0.06,
      ),
    ],
  ),
  AugmentDefinition(
    id: lastStand,
    name: '최후의 저항',
    maxLevel: 3,
    startsUnlocked: false,
    category: AugmentCategory.survival,
    effects: [
      AugmentEffect(
        stat: AugmentStat.incomingContactDamage,
        valuePerLevel: -0.10,
        condition: AugmentCondition.healthAtOrBelow35,
      ),
      AugmentEffect(
        stat: AugmentStat.weaponDamage,
        valuePerLevel: 0.20,
        condition: AugmentCondition.healthAtOrBelow35,
      ),
    ],
  ),
  AugmentDefinition(
    id: quickStep,
    name: '빠른 발놀림',
    maxLevel: 5,
    startsUnlocked: true,
    category: AugmentCategory.movementAcquisition,
    effects: [AugmentEffect(stat: AugmentStat.moveSpeed, valuePerLevel: 0.08)],
  ),
  AugmentDefinition(
    id: jangseungBlessing,
    name: '장승의 가호',
    maxLevel: 5,
    startsUnlocked: true,
    category: AugmentCategory.movementAcquisition,
    effects: [AugmentEffect(stat: AugmentStat.pickupRadius, valuePerLevel: 16)],
  ),
  AugmentDefinition(
    id: scholarInsight,
    name: '선비의 통찰',
    maxLevel: 5,
    startsUnlocked: true,
    category: AugmentCategory.movementAcquisition,
    effects: [
      AugmentEffect(stat: AugmentStat.experienceGain, valuePerLevel: 0.10),
    ],
  ),
  AugmentDefinition(
    id: ritualShortcut,
    name: '의식 단축',
    maxLevel: 1,
    startsUnlocked: false,
    category: AugmentCategory.movementAcquisition,
    effects: [
      AugmentEffect(
        stat: AugmentStat.experienceRequirement,
        valuePerLevel: -0.15,
      ),
    ],
  ),
  AugmentDefinition(
    id: heavyStrike,
    name: '강력한 일격',
    maxLevel: 5,
    startsUnlocked: false,
    category: AugmentCategory.riskReward,
    effects: [
      AugmentEffect(stat: AugmentStat.weaponDamage, valuePerLevel: 0.18),
      AugmentEffect(
        stat: AugmentStat.attackSpeed,
        valuePerLevel: -0.08,
        isPenalty: true,
      ),
    ],
  ),
  AugmentDefinition(
    id: bloodOath,
    name: '피의 맹세',
    maxLevel: 3,
    startsUnlocked: true,
    category: AugmentCategory.riskReward,
    effects: [
      AugmentEffect(stat: AugmentStat.weaponDamage, valuePerLevel: 0.20),
      AugmentEffect(
        stat: AugmentStat.incomingContactDamage,
        valuePerLevel: 0.10,
        isPenalty: true,
      ),
    ],
  ),
  AugmentDefinition(
    id: ghostStep,
    name: '귀신걸음',
    maxLevel: 3,
    startsUnlocked: true,
    category: AugmentCategory.riskReward,
    effects: [
      AugmentEffect(stat: AugmentStat.moveSpeed, valuePerLevel: 0.15),
      AugmentEffect(
        stat: AugmentStat.pickupRadius,
        valuePerLevel: -12,
        isPenalty: true,
      ),
    ],
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

AugmentDefinition? augmentDefinitionFor(AugmentId id) {
  for (final definition in augmentDefinitions) {
    if (definition.id == id) return definition;
  }
  return null;
}
