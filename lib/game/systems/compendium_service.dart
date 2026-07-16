import '../content/augment_definitions.dart';
import '../content/character_definitions.dart';
import '../content/ids.dart';
import '../content/unlock_definitions.dart';
import '../content/weapon_definitions.dart';
import '../models/compendium_entry.dart';
import 'progression_system.dart';
import 'save_system.dart';

class CompendiumService {
  const CompendiumService({this.progression = const ProgressionSystem()});

  final ProgressionSystem progression;

  List<CompendiumEntry> entries(SaveState state) {
    final goalsByReward = {for (final goal in unlockGoals) goal.rewardId: goal};
    return List.unmodifiable([
      for (final definition in characterDefinitions)
        _entry(
          state: state,
          section: CompendiumSection.character,
          id: definition.id,
          name: definition.name,
          detail:
              '${definition.passiveName} · ${definition.passiveDescription}',
          isUnlocked: state.unlockedCharacterIds.contains(definition.id),
          goal: goalsByReward[definition.id],
        ),
      for (final definition in weaponDefinitions)
        _entry(
          state: state,
          section: CompendiumSection.weapon,
          id: definition.id,
          name: definition.name,
          detail: '최대 ${definition.maxLevel}레벨',
          isUnlocked: state.unlockedWeaponIds.contains(definition.id),
          goal: goalsByReward[definition.id],
        ),
      for (final definition in augmentDefinitions)
        _entry(
          state: state,
          section: CompendiumSection.augment,
          id: definition.id,
          name: definition.name,
          detail: '최대 ${definition.maxLevel}레벨',
          isUnlocked: state.unlockedAugmentIds.contains(definition.id),
          goal: goalsByReward[definition.id],
        ),
    ]);
  }

  Set<String> unseenUnlockedKeys(SaveState state) => entries(state)
      .where((entry) => entry.isUnlocked && entry.isNew)
      .map((entry) => entry.key)
      .toSet();

  CompendiumEntry _entry({
    required SaveState state,
    required CompendiumSection section,
    required String id,
    required String name,
    required String detail,
    required bool isUnlocked,
    UnlockGoalDefinition? goal,
  }) {
    final key = '${section.name}:$id';
    final current = goal == null
        ? (isUnlocked ? 1 : 0)
        : progression.metricValue(goal.metric, state);
    final target = goal?.threshold ?? 1;
    return CompendiumEntry(
      key: key,
      id: id,
      section: section,
      name: name,
      detail: detail,
      isUnlocked: isUnlocked,
      isNew: isUnlocked && !state.seenCompendiumEntryIds.contains(key),
      unlockCondition: goal == null ? '기본 해금' : _condition(goal),
      currentProgress: current,
      targetProgress: target,
      progressFraction: isUnlocked
          ? 1
          : (current / target).clamp(0, 1).toDouble(),
    );
  }

  String _condition(UnlockGoalDefinition goal) => switch (goal.metric) {
    UnlockMetric.bestSurvivalSeconds => '한 판에서 ${goal.threshold ~/ 60}분 생존',
    UnlockMetric.totalKills => '누적 적 ${goal.threshold}명 처치',
    UnlockMetric.levelReachedInRun => '한 판에서 레벨 ${goal.threshold} 달성',
    UnlockMetric.bossDefeats => '보스 ${goal.threshold}회 격파',
    UnlockMetric.unlockedWeaponCount => '무기 ${goal.threshold}개 해금',
    UnlockMetric.lowHealthWinCount => '체력 30% 미만으로 승리',
    UnlockMetric.totalEliteKills => '누적 정예 ${goal.threshold}명 처치',
    UnlockMetric.victoryCount => '런 ${goal.threshold}회 승리',
  };
}
