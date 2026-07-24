import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';
import 'package:pixel_survivor/game/content/unlock_definitions.dart';

void main() {
  test('moonlit stage reward presentation matches its configured stage reward', () {
    final goal = unlockGoals.singleWhere(
      (item) => item.unlocksStageId == plagueMarket,
    );
    final moonlit = stageDefinitionFor(moonlitAbandonedOffice);

    expect(goal.id, 'win_first_run');
    expect(moonlit.majorRewardLabel, '역병 장터 해금');
  });

  test('stage presentation explicitly marks unavailable historical records', () {
    for (final stage in stageDefinitions) {
      expect(StageDefinition.bestRecordUnavailableLabel, '최고 기록 미집계');
      expect(StageDefinition.clearStatusUnavailableLabel, '클리어 상태 미집계');
      expect(stage.majorRewardLabel, isNotEmpty);
    }
  });
}
