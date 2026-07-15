import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/augment_definitions.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/models/meta_progress.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('save state writes the current schema version', () {
    final state = SaveState.defaults();

    expect(SaveState.currentSchemaVersion, 2);
    expect(state.schemaVersion, SaveState.currentSchemaVersion);
    expect(state.toJson()['schemaVersion'], SaveState.currentSchemaVersion);
  });

  test('versionless alpha save migrates to schema two', () {
    final restored = SaveState.fromJson({
      'unlockedCharacterIds': [rookieConstable, exorcistDosa],
      'unlockedWeaponIds': [hwandoSlash, gakgungShot, talismanThrow],
      'unlockedAugmentIds': [martialTraining, rapidReload],
      'completedGoalIds': ['survive_3_minutes'],
      'totalKills': 321,
      'bestSurvivalSeconds': 240,
      'levelReachedInRun': 12,
      'bossDefeats': 2,
      'unlockedWeaponCount': 4,
      'lowHealthWinCount': 1,
    });

    expect(restored.schemaVersion, SaveState.currentSchemaVersion);
    expect(restored.totalKills, 321);
    expect(restored.bestSurvivalSeconds, 240);
    expect(restored.unlockedCharacterIds, contains(exorcistDosa));
    expect(restored.unlockedWeaponIds, contains(talismanThrow));
    expect(restored.unlockedAugmentIds, contains(rapidReload));
    expect(restored.completedGoalIds, contains('survive_3_minutes'));
  });

  test(
    'schema one migration preserves progress and initializes meta state',
    () {
      final restored = SaveState.fromJson({
        'schemaVersion': 1,
        'unlockedCharacterIds': [rookieConstable, exorcistDosa],
        'totalKills': 91,
        'bestSurvivalSeconds': 240,
      });

      expect(restored.schemaVersion, 2);
      expect(restored.unlockedCharacterIds, contains(exorcistDosa));
      expect(restored.totalKills, 91);
      expect(restored.wallet, Wallet.empty);
      expect(restored.trainingProgress, TrainingProgress.empty);
      expect(restored.shopProgress, ShopProgress.empty);
      expect(restored.selectedCharacterId, rookieConstable);
      expect(restored.selectedStageId, moonlitAbandonedOffice);
    },
  );

  test('schema two sanitizes damaged meta fields and selections', () {
    final restored = SaveState.fromJson({
      'schemaVersion': 2,
      'wallet': {'coin': -20, 'spiritJade': 'bad'},
      'trainingProgress': {
        'commonRanks': {'unknown': 9},
        'characterRanks': {
          'unknown': {'node': 1},
        },
        'activeCoreTraitIds': {'unknown': 'trait'},
      },
      'shopProgress': {
        'purchasedItemIds': ['manual.rookie_constable', 7],
      },
      'selectedCharacterId': 'missing',
      'selectedStageId': 'missing',
    });

    expect(restored.wallet, Wallet.empty);
    expect(restored.trainingProgress, TrainingProgress.empty);
    expect(restored.shopProgress.purchasedItemIds, {'manual.rookie_constable'});
    expect(restored.selectedCharacterId, rookieConstable);
    expect(restored.selectedStageId, moonlitAbandonedOffice);
    expect(restored.claimedRewardIds, isEmpty);
  });

  test('claimed reward ids round trip without a schema bump', () {
    final original = SaveState.defaults().copyWith(
      claimedRewardIds: {'first_boss_spirit_jade', 'drop-1'},
    );

    final restored = SaveState.fromJson(original.toJson());

    expect(restored.schemaVersion, 2);
    expect(restored.claimedRewardIds, original.claimedRewardIds);
  });

  group('unsupported save schemas', () {
    test('future schema returns defaults', () {
      final restored = SaveState.fromJson({
        'schemaVersion': SaveState.currentSchemaVersion + 1,
        'totalKills': 999,
        'unlockedCharacterIds': [exorcistDosa],
      });

      expect(restored.schemaVersion, SaveState.currentSchemaVersion);
      expect(restored.totalKills, 0);
      expect(restored.unlockedCharacterIds, {
        rookieConstable,
        exorcistDosa,
        mountainHunter,
      });
    });

    test('negative schema returns defaults', () {
      final restored = SaveState.fromJson({
        'schemaVersion': -1,
        'totalKills': 999,
      });

      expect(restored.totalKills, 0);
    });

    test('non-integer schema returns defaults', () {
      final restored = SaveState.fromJson({
        'schemaVersion': '1',
        'totalKills': 999,
      });

      expect(restored.totalKills, 0);
    });
  });

  test('save system loads defaults for unsupported stored schema', () async {
    SharedPreferences.setMockInitialValues({
      'save_state': '{"schemaVersion":3,"totalKills":999}',
    });

    final save = await SaveSystem().load();

    expect(save.schemaVersion, SaveState.currentSchemaVersion);
    expect(save.totalKills, 0);
    expect(save.unlockedCharacterIds, {
      rookieConstable,
      exorcistDosa,
      mountainHunter,
    });
  });

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

    expect(restored.unlockedCharacterIds, {
      rookieConstable,
      exorcistDosa,
      mountainHunter,
    });
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
