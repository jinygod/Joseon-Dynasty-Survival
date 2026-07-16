import 'augment_definitions.dart';
import 'character_definitions.dart';
import 'ids.dart';
import 'stage_definitions.dart';
import 'weapon_definitions.dart';

const unlockGoals = <UnlockGoalDefinition>[
  UnlockGoalDefinition(
    id: 'survive_3_minutes',
    description: 'Survive for 3 minutes once.',
    metric: UnlockMetric.bestSurvivalSeconds,
    threshold: 180,
    unlocksWeaponId: talismanThrow,
  ),
  UnlockGoalDefinition(
    id: 'defeat_300_enemies',
    description: 'Defeat 300 enemies total.',
    metric: UnlockMetric.totalKills,
    threshold: 300,
    unlocksWeaponId: thunderCrashBomb,
  ),
  UnlockGoalDefinition(
    id: 'reach_level_10',
    description: 'Reach level 10 in one run.',
    metric: UnlockMetric.levelReachedInRun,
    threshold: 10,
    unlocksWeaponId: jangseungWard,
  ),
  UnlockGoalDefinition(
    id: 'defeat_fallen_general',
    description: 'Defeat the Fallen General once.',
    metric: UnlockMetric.bossDefeats,
    threshold: 1,
    unlocksCharacterId: exorcistDosa,
  ),
  UnlockGoalDefinition(
    id: 'survive_5_minutes',
    description: 'Survive for 5 minutes once.',
    metric: UnlockMetric.bestSurvivalSeconds,
    threshold: 300,
    unlocksAugmentId: goblinFire,
  ),
  UnlockGoalDefinition(
    id: 'unlock_three_weapons',
    description: 'Unlock three weapons.',
    metric: UnlockMetric.unlockedWeaponCount,
    threshold: 3,
    unlocksAugmentId: powderMastery,
  ),
  UnlockGoalDefinition(
    id: 'defeat_500_enemies',
    description: 'Defeat 500 enemies total.',
    metric: UnlockMetric.totalKills,
    threshold: 500,
    unlocksWeaponId: singijeonVolley,
  ),
  UnlockGoalDefinition(
    id: 'low_health_win',
    description: 'Win a run with less than 30 percent health remaining.',
    metric: UnlockMetric.lowHealthWinCount,
    threshold: 1,
    unlocksAugmentId: lastStand,
  ),
  UnlockGoalDefinition(
    id: 'defeat_two_bosses',
    description: 'Defeat two bosses total.',
    metric: UnlockMetric.bossDefeats,
    threshold: 2,
    unlocksWeaponId: frostFlask,
  ),
  UnlockGoalDefinition(
    id: 'unlock_six_weapons',
    description: 'Unlock six weapons.',
    metric: UnlockMetric.unlockedWeaponCount,
    threshold: 6,
    unlocksWeaponId: windThunderFan,
  ),
  UnlockGoalDefinition(
    id: 'reach_level_5',
    description: 'Reach level 5 in one run.',
    metric: UnlockMetric.levelReachedInRun,
    threshold: 5,
    unlocksAugmentId: rapidReload,
  ),
  UnlockGoalDefinition(
    id: 'defeat_50_elites',
    description: 'Defeat 50 elite enemies total.',
    metric: UnlockMetric.totalEliteKills,
    threshold: 50,
    unlocksAugmentId: ritualShortcut,
  ),
  UnlockGoalDefinition(
    id: 'reach_level_15',
    description: 'Reach level 15 in one run.',
    metric: UnlockMetric.levelReachedInRun,
    threshold: 15,
    unlocksAugmentId: heavyStrike,
  ),
  UnlockGoalDefinition(
    id: 'defeat_three_bosses',
    description: 'Defeat three bosses total.',
    metric: UnlockMetric.bossDefeats,
    threshold: 3,
    unlocksCharacterId: mountainHunter,
  ),
  UnlockGoalDefinition(
    id: 'win_first_run',
    description: 'Win a run.',
    metric: UnlockMetric.victoryCount,
    threshold: 1,
    unlocksStageId: plagueMarket,
  ),
];
