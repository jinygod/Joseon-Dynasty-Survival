import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/augment_definitions.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/unlock_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';

void main() {
  test('catalog has exactly fifteen unique single-reward goals', () {
    expect(unlockGoals, hasLength(15));
    expect(unlockGoals.map((goal) => goal.id).toSet(), hasLength(15));

    for (final goal in unlockGoals) {
      final rewardCount = [
        goal.unlocksCharacterId,
        goal.unlocksWeaponId,
        goal.unlocksAugmentId,
        goal.unlocksStageId,
      ].where((id) => id != null).length;
      expect(rewardCount, 1, reason: goal.id);
      expect(goal.threshold, greaterThan(0), reason: goal.id);
    }
  });

  test('existing reward fields cover every non-starting roster item once', () {
    final expectedCharacters = characterDefinitions
        .map((definition) => definition.id)
        .where((id) => id != rookieConstable)
        .toSet();
    final expectedWeapons = weaponDefinitions
        .where((definition) => !definition.startsUnlocked)
        .map((definition) => definition.id)
        .toSet();
    final expectedAugments = augmentDefinitions
        .where((definition) => !definition.startsUnlocked)
        .map((definition) => definition.id)
        .toSet();

    expect(
      unlockGoals.map((goal) => goal.unlocksCharacterId).whereType<String>(),
      unorderedEquals(expectedCharacters),
    );
    expect(
      unlockGoals.map((goal) => goal.unlocksWeaponId).whereType<String>(),
      unorderedEquals(expectedWeapons),
    );
    expect(
      unlockGoals.map((goal) => goal.unlocksAugmentId).whereType<String>(),
      unorderedEquals(expectedAugments),
    );
    expect(
      unlockGoals.map((goal) => goal.unlocksStageId).whereType<String>(),
      unorderedEquals([plagueMarket]),
    );
  });
}
