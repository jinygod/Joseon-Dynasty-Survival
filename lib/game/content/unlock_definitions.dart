import 'augment_definitions.dart';
import 'character_definitions.dart';
import 'ids.dart';
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
    unlocksAugmentId: rapidReload,
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
];
