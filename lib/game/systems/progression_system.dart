import 'dart:math';

import '../content/ids.dart';
import '../content/unlock_definitions.dart';
import 'save_system.dart';

class ProgressionSystem {
  const ProgressionSystem();

  SaveState evaluate(SaveState save) {
    final unlockedCharacterIds = Set<String>.of(save.unlockedCharacterIds);
    final unlockedWeaponIds = Set<String>.of(save.unlockedWeaponIds);
    final unlockedAugmentIds = Set<String>.of(save.unlockedAugmentIds);
    final completedGoalIds = Set<String>.of(save.completedGoalIds);

    for (final goal in unlockGoals) {
      final isAchieved =
          completedGoalIds.contains(goal.id) ||
          _metricValue(goal.metric, save, unlockedWeaponIds) >= goal.threshold;

      if (!isAchieved) {
        continue;
      }

      completedGoalIds.add(goal.id);

      final characterId = goal.unlocksCharacterId;
      if (characterId != null) {
        unlockedCharacterIds.add(characterId);
      }

      final weaponId = goal.unlocksWeaponId;
      if (weaponId != null) {
        unlockedWeaponIds.add(weaponId);
      }

      final augmentId = goal.unlocksAugmentId;
      if (augmentId != null) {
        unlockedAugmentIds.add(augmentId);
      }
    }

    return save.copyWith(
      unlockedCharacterIds: unlockedCharacterIds,
      unlockedWeaponIds: unlockedWeaponIds,
      unlockedAugmentIds: unlockedAugmentIds,
      completedGoalIds: completedGoalIds,
      unlockedWeaponCount: max(
        save.unlockedWeaponCount,
        unlockedWeaponIds.length,
      ),
    );
  }

  int _metricValue(
    UnlockMetric metric,
    SaveState save,
    Set<String> currentUnlockedWeaponIds,
  ) {
    return switch (metric) {
      UnlockMetric.bestSurvivalSeconds => save.bestSurvivalSeconds,
      UnlockMetric.totalKills => save.totalKills,
      UnlockMetric.levelReachedInRun => save.levelReachedInRun,
      UnlockMetric.bossDefeats => save.bossDefeats,
      UnlockMetric.unlockedWeaponCount => max(
        save.unlockedWeaponCount,
        currentUnlockedWeaponIds.length,
      ),
      UnlockMetric.lowHealthWinCount => save.lowHealthWinCount,
    };
  }
}
