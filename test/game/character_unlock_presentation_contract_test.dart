import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/ids.dart';
import 'package:pixel_survivor/game/content/unlock_definitions.dart';

void main() {
  test('character unlock presentation matches the configured boss goals', () {
    final byCharacter = {
      for (final goal in unlockGoals)
        if (goal.unlocksCharacterId != null) goal.unlocksCharacterId!: goal,
    };

    for (final characterId in [exorcistDosa, mountainHunter]) {
      final goal = byCharacter[characterId]!;
      final presentation = characterUnlockPresentation[characterId]!;
      expect(presentation.unlockGoalId, goal.id);
      expect(goal.metric, UnlockMetric.bossDefeats);
      expect(presentation.condition, '\uBCF4\uC2A4 ${goal.threshold}\uD68C \uACA9\uD30C \uC2DC \uD574\uAE08');
    }

    final presentation = characterUnlockPresentation[rookieConstable]!;
    expect(presentation.unlockGoalId, isNull);
    expect(presentation.condition, '\uAE30\uBCF8 \uD574\uAE08');
  });
}
