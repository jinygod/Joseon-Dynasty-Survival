import 'ids.dart';
import 'weapon_definitions.dart';

const rookieConstable = 'rookie_constable';
const exorcistDosa = 'exorcist_dosa';
const mountainHunter = 'mountain_hunter';

class CharacterUnlockPresentation {
  const CharacterUnlockPresentation({
    required this.condition,
    this.unlockGoalId,
  });

  final String condition;
  final String? unlockGoalId;
}

const characterUnlockPresentation = <String, CharacterUnlockPresentation>{
  rookieConstable: CharacterUnlockPresentation(condition: '기본 해금'),
  exorcistDosa: CharacterUnlockPresentation(
    condition: '보스 1회 격파 시 해금',
    unlockGoalId: 'defeat_fallen_general',
  ),
  mountainHunter: CharacterUnlockPresentation(
    condition: '보스 3회 격파 시 해금',
    unlockGoalId: 'defeat_three_bosses',
  ),
};

const characterDefinitions = <CharacterDefinition>[
  CharacterDefinition(
    id: rookieConstable,
    name: '신참 포졸',
    maxHealth: 105,
    moveSpeed: 125,
    damageMultiplier: 1,
    startingWeaponId: hwandoSlash,
    passive: CharacterPassive.patrolGrit,
    passiveName: '순라의 끈기',
    passiveDescription: '접촉 피해 -12%',
  ),
  CharacterDefinition(
    id: exorcistDosa,
    name: '퇴마 도사',
    maxHealth: 85,
    moveSpeed: 115,
    damageMultiplier: 1,
    startingWeaponId: talismanThrow,
    passive: CharacterPassive.exorcismScript,
    passiveName: '퇴마 서법',
    passiveDescription: '마법 무기 피해 +15%',
  ),
  CharacterDefinition(
    id: mountainHunter,
    name: '산길 사냥꾼',
    maxHealth: 90,
    moveSpeed: 140,
    damageMultiplier: 1,
    startingWeaponId: gakgungShot,
    passive: CharacterPassive.hawkEye,
    passiveName: '매의 눈',
    passiveDescription: '치명타 확률 +10%p',
  ),
];
