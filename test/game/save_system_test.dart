import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/augment_definitions.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('defaults include the starting character, weapons, and augments', () {
    final save = SaveState.defaults();
    final startingAugmentIds = augmentDefinitions
        .where((augment) => augment.startsUnlocked)
        .map((augment) => augment.id)
        .toSet();

    expect(save.unlockedCharacterIds, contains(rookieConstable));
    expect(save.unlockedWeaponIds, containsAll([hwandoSlash, gakgungShot]));
    expect(save.unlockedAugmentIds, containsAll(startingAugmentIds));
  });

  test('toJson and fromJson preserve core save fields', () {
    final original = SaveState.defaults().copyWith(
      unlockedCharacterIds: {rookieConstable, exorcistDosa},
      unlockedWeaponIds: {hwandoSlash, gakgungShot, talismanThrow},
      unlockedAugmentIds: {martialTraining, rapidReload},
      completedGoalIds: {'survive_3_minutes'},
      totalKills: 321,
      bestSurvivalSeconds: 240,
      levelReachedInRun: 12,
      bossDefeats: 2,
      unlockedWeaponCount: 4,
      lowHealthWinCount: 1,
    );

    final restored = SaveState.fromJson(original.toJson());

    expect(restored.unlockedCharacterIds, original.unlockedCharacterIds);
    expect(restored.unlockedWeaponIds, original.unlockedWeaponIds);
    expect(
      restored.unlockedAugmentIds,
      containsAll(original.unlockedAugmentIds),
    );
    expect(restored.completedGoalIds, original.completedGoalIds);
    expect(restored.totalKills, original.totalKills);
    expect(restored.bestSurvivalSeconds, original.bestSurvivalSeconds);
    expect(restored.levelReachedInRun, original.levelReachedInRun);
    expect(restored.bossDefeats, original.bossDefeats);
    expect(restored.unlockedWeaponCount, original.unlockedWeaponCount);
    expect(restored.lowHealthWinCount, original.lowHealthWinCount);
  });

  test('fromJson merges missing unlock fields with defaults', () {
    final restored = SaveState.fromJson({
      'unlockedCharacterIds': [exorcistDosa],
      'totalKills': 12,
    });

    expect(
      restored.unlockedCharacterIds,
      containsAll([rookieConstable, exorcistDosa]),
    );
    expect(restored.unlockedWeaponIds, containsAll([hwandoSlash, gakgungShot]));
    expect(restored.unlockedAugmentIds, contains(martialTraining));
    expect(restored.totalKills, 12);
  });

  test('save system loads defaults when stored json is corrupted', () async {
    SharedPreferences.setMockInitialValues({'save_state': '{bad json'});

    final save = await SaveSystem().load();

    expect(save.unlockedCharacterIds, contains(rookieConstable));
    expect(save.unlockedWeaponIds, containsAll([hwandoSlash, gakgungShot]));
  });

  test(
    'save system saves and loads state through shared preferences',
    () async {
      SharedPreferences.setMockInitialValues({});
      final system = SaveSystem();
      final original = SaveState.defaults().copyWith(
        totalKills: 77,
        bestSurvivalSeconds: 181,
        unlockedWeaponIds: {hwandoSlash, gakgungShot, talismanThrow},
      );

      await system.save(original);
      final loaded = await system.load();

      expect(loaded.totalKills, 77);
      expect(loaded.bestSurvivalSeconds, 181);
      expect(loaded.unlockedWeaponIds, contains(talismanThrow));
    },
  );
}
