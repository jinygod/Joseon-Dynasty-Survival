import 'dart:math';

import '../content/ids.dart';
import '../content/unlock_definitions.dart';
import '../models/run_result.dart';
import '../models/run_outcome.dart';
import 'save_system.dart';

class ProgressionSystem {
  const ProgressionSystem();

  SaveState applyRunResult(SaveState save, RunResult result) {
    final updated = save.copyWith(
      bestSurvivalSeconds: max(
        save.bestSurvivalSeconds,
        result.survivalSeconds,
      ),
      totalKills: save.totalKills + result.kills,
      levelReachedInRun: max(save.levelReachedInRun, result.level),
      bossDefeats: save.bossDefeats + (result.bossDefeated ? 1 : 0),
      lowHealthWinCount:
          save.lowHealthWinCount + (result.wonWithLowHealth ? 1 : 0),
      totalEliteKills: save.totalEliteKills + result.eliteKills,
      victoryCount:
          save.victoryCount + (result.outcome == RunOutcome.victory ? 1 : 0),
    );

    return evaluate(updated);
  }

  SaveState evaluate(SaveState save) {
    final unlockedCharacterIds = Set<String>.of(save.unlockedCharacterIds);
    final unlockedWeaponIds = Set<String>.of(save.unlockedWeaponIds);
    final unlockedAugmentIds = Set<String>.of(save.unlockedAugmentIds);
    final unlockedStageIds = Set<String>.of(save.unlockedStageIds);
    final completedGoalIds = Set<String>.of(save.completedGoalIds);

    for (final goal in unlockGoals) {
      final isAchieved =
          completedGoalIds.contains(goal.id) ||
          metricValue(goal.metric, save, unlockedWeaponIds) >= goal.threshold;

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

      final stageId = goal.unlocksStageId;
      if (stageId != null) {
        unlockedStageIds.add(stageId);
      }
    }

    return save.copyWith(
      unlockedCharacterIds: unlockedCharacterIds,
      unlockedWeaponIds: unlockedWeaponIds,
      unlockedAugmentIds: unlockedAugmentIds,
      unlockedStageIds: unlockedStageIds,
      completedGoalIds: completedGoalIds,
      unlockedWeaponCount: max(
        save.unlockedWeaponCount,
        unlockedWeaponIds.length,
      ),
    );
  }

  int metricValue(
    UnlockMetric metric,
    SaveState save, [
    Set<String>? currentUnlockedWeaponIds,
  ]) {
    final weaponIds = currentUnlockedWeaponIds ?? save.unlockedWeaponIds;
    return switch (metric) {
      UnlockMetric.bestSurvivalSeconds => save.bestSurvivalSeconds,
      UnlockMetric.totalKills => save.totalKills,
      UnlockMetric.levelReachedInRun => save.levelReachedInRun,
      UnlockMetric.bossDefeats => save.bossDefeats,
      UnlockMetric.unlockedWeaponCount => max(
        save.unlockedWeaponCount,
        weaponIds.length,
      ),
      UnlockMetric.lowHealthWinCount => save.lowHealthWinCount,
      UnlockMetric.totalEliteKills => save.totalEliteKills,
      UnlockMetric.victoryCount => save.victoryCount,
    };
  }
}

class ProgressionUnlocks {
  const ProgressionUnlocks({
    this.characterIds = const [],
    this.weaponIds = const [],
    this.augmentIds = const [],
    this.stageIds = const [],
  });

  factory ProgressionUnlocks.diff(SaveState before, SaveState after) {
    return ProgressionUnlocks(
      characterIds: _newIds(
        before.unlockedCharacterIds,
        after.unlockedCharacterIds,
      ),
      weaponIds: _newIds(before.unlockedWeaponIds, after.unlockedWeaponIds),
      augmentIds: _newIds(before.unlockedAugmentIds, after.unlockedAugmentIds),
      stageIds: _newIds(before.unlockedStageIds, after.unlockedStageIds),
    );
  }

  final List<String> characterIds;
  final List<String> weaponIds;
  final List<String> augmentIds;
  final List<String> stageIds;

  bool get isEmpty =>
      characterIds.isEmpty &&
      weaponIds.isEmpty &&
      augmentIds.isEmpty &&
      stageIds.isEmpty;

  static List<String> _newIds(Set<String> before, Set<String> after) {
    return (after.difference(before).toList()..sort());
  }
}
