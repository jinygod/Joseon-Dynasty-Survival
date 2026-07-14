import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/augment_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_level_definitions.dart';

void main() {
  test('first stage has four weapons with five complete levels', () {
    const ids = [hwandoSlash, gakgungShot, talismanThrow, thunderCrashBomb];
    for (final id in ids) {
      expect(weaponLevels[id], hasLength(5));
      expect(weaponLevelFor(id, 1).damage, greaterThan(0));
      expect(weaponLevelFor(id, 5).displayEffect, isNotEmpty);
    }
  });

  test('first stage exposes exactly eight functional augments', () {
    expect(firstStageAugmentIds, hasLength(8));
    for (final id in firstStageAugmentIds) {
      final definition = augmentDefinitions.singleWhere(
        (item) => item.id == id,
      );
      expect(definition.effectDescriptionForLevel(1), isNotEmpty);
    }
  });
}
