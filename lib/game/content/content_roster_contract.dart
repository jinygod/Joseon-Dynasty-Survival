import 'augment_definitions.dart';
import 'boss_definitions.dart';
import 'character_definitions.dart';
import 'enemy_definitions.dart';
import 'stage_definitions.dart';
import 'weapon_definitions.dart';

abstract final class ContentRosterContract {
  static const characterIds = {rookieConstable, exorcistDosa, mountainHunter};

  static const weaponIds = {
    hwandoSlash,
    gakgungShot,
    talismanThrow,
    thunderCrashBomb,
    jangseungWard,
    singijeonVolley,
    frostFlask,
    windThunderFan,
  };

  static const augmentIds = {
    martialTraining,
    quickStep,
    innerBreath,
    jangseungBlessing,
    hawkEye,
    herbalTonic,
    rapidReload,
    goblinFire,
    powderMastery,
    lastStand,
    ritualShortcut,
    heavyStrike,
    ironArmorTraining,
    scholarInsight,
    bloodOath,
    ghostStep,
  };

  static const enemyIds = {
    plagueRatSwarm,
    bandit,
    dokkaebi,
    vengefulSpirit,
    plagueCrow,
    spearBandit,
    rottenHerbalist,
    graveEmber,
    blackHatAssassin,
    brokenJangseungSpirit,
    sorrowfulMaidenGhost,
    fallenGeneral,
  };

  static const stageIds = {moonlitAbandonedOffice, plagueMarket};
  static const bossIds = {fallenGeneral, plagueMagistrate, maskedExecutioner};

  static const unlockGoalIds = {
    'survive_3_minutes',
    'defeat_300_enemies',
    'reach_level_10',
    'defeat_fallen_general',
    'survive_5_minutes',
    'unlock_three_weapons',
    'defeat_500_enemies',
    'low_health_win',
    'defeat_two_bosses',
    'unlock_six_weapons',
    'reach_level_5',
    'defeat_50_elites',
    'reach_level_15',
    'defeat_three_bosses',
    'win_first_run',
  };

  static const stageBossIds = <String, Set<String>>{
    moonlitAbandonedOffice: {fallenGeneral, maskedExecutioner},
    plagueMarket: {plagueMagistrate},
  };
}
