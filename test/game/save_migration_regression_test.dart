import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/game_settings.dart';
import 'package:pixel_survivor/app/game_settings_repository.dart';
import 'package:pixel_survivor/game/content/augment_definitions.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/models/meta_progress.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'versionless fixture preserves original fields and migrates defaults',
    () {
      final restored = SaveState.fromJson({
        'unlockedCharacterIds': [rookieConstable, exorcistDosa],
        'unlockedWeaponIds': [hwandoSlash, talismanThrow],
        'unlockedAugmentIds': [martialTraining, rapidReload],
        'completedGoalIds': ['survive_3_minutes'],
        'totalKills': 101,
        'bestSurvivalSeconds': 180,
        'levelReachedInRun': 11,
        'bossDefeats': 1,
        'unlockedWeaponCount': 2,
        'lowHealthWinCount': 1,
      });

      _expectOriginalFields(restored, kills: 101, survival: 180);
      _expectPostV1Defaults(restored);
    },
  );

  test('v1 fixture preserves original fields and migrates later defaults', () {
    final restored = SaveState.fromJson({
      'schemaVersion': 1,
      'unlockedCharacterIds': [rookieConstable, exorcistDosa],
      'unlockedWeaponIds': [hwandoSlash, talismanThrow],
      'unlockedAugmentIds': [martialTraining, rapidReload],
      'completedGoalIds': ['survive_3_minutes'],
      'totalKills': 202,
      'bestSurvivalSeconds': 210,
      'levelReachedInRun': 13,
      'bossDefeats': 2,
      'unlockedWeaponCount': 2,
      'lowHealthWinCount': 1,
    });

    _expectOriginalFields(restored, kills: 202, survival: 210);
    _expectPostV1Defaults(restored);
  });

  test('v2 fixture preserves meta progress and selected legacy stage', () {
    final restored = SaveState.fromJson({
      'schemaVersion': 2,
      'unlockedCharacterIds': [rookieConstable, exorcistDosa],
      'unlockedWeaponIds': [hwandoSlash, talismanThrow],
      'unlockedAugmentIds': [martialTraining, rapidReload],
      'completedGoalIds': ['survive_3_minutes'],
      'claimedRewardIds': ['survive_3_minutes'],
      'wallet': {'coin': 77, 'spiritJade': 4},
      'trainingProgress': {
        'commonRanks': {'common.max_health': 2},
        'characterRanks': <String, Object?>{},
        'activeCoreTraitIds': <String, Object?>{},
      },
      'shopProgress': {
        'purchasedItemIds': ['manual.exorcist_dosa'],
      },
      'selectedCharacterId': exorcistDosa,
      'selectedStageId': plagueMarket,
      'totalKills': 303,
      'bestSurvivalSeconds': 240,
      'levelReachedInRun': 15,
      'bossDefeats': 3,
      'unlockedWeaponCount': 2,
      'lowHealthWinCount': 2,
    });

    _expectOriginalFields(restored, kills: 303, survival: 240);
    expect(restored.claimedRewardIds, contains('survive_3_minutes'));
    expect(restored.wallet, const Wallet(coin: 77, spiritJade: 4));
    expect(restored.trainingProgress.commonRanks['common.max_health'], 2);
    expect(
      restored.shopProgress.purchasedItemIds,
      contains('manual.exorcist_dosa'),
    );
    expect(restored.selectedCharacterId, exorcistDosa);
    expect(restored.selectedStageId, plagueMarket);
    expect(restored.unlockedStageIds, contains(plagueMarket));
    expect(restored.totalEliteKills, 0);
    expect(restored.victoryCount, 0);
    expect(restored.characterVictoryCounts, isEmpty);
    expect(restored.seenCompendiumEntryIds, isEmpty);
  });

  test('v3 fixture preserves every current-era progress field', () {
    final restored = SaveState.fromJson({
      'schemaVersion': 3,
      'unlockedCharacterIds': [rookieConstable, exorcistDosa],
      'unlockedWeaponIds': [hwandoSlash, talismanThrow],
      'unlockedAugmentIds': [martialTraining, rapidReload],
      'unlockedStageIds': [moonlitAbandonedOffice, plagueMarket],
      'completedGoalIds': ['survive_3_minutes'],
      'claimedRewardIds': ['survive_3_minutes'],
      'wallet': {'coin': 88, 'spiritJade': 5},
      'trainingProgress': <String, Object?>{},
      'shopProgress': <String, Object?>{},
      'selectedCharacterId': exorcistDosa,
      'selectedStageId': plagueMarket,
      'totalKills': 404,
      'bestSurvivalSeconds': 270,
      'levelReachedInRun': 17,
      'bossDefeats': 4,
      'unlockedWeaponCount': 2,
      'lowHealthWinCount': 3,
      'totalEliteKills': 12,
      'victoryCount': 6,
      'characterVictoryCounts': {exorcistDosa: 2},
      'seenCompendiumEntryIds': [
        'character:$rookieConstable',
        'weapon:$hwandoSlash',
      ],
    });

    _expectOriginalFields(restored, kills: 404, survival: 270);
    expect(restored.wallet, const Wallet(coin: 88, spiritJade: 5));
    expect(restored.selectedCharacterId, exorcistDosa);
    expect(restored.selectedStageId, plagueMarket);
    expect(restored.unlockedStageIds, contains(plagueMarket));
    expect(restored.totalEliteKills, 12);
    expect(restored.victoryCount, 6);
    expect(restored.characterVictoryCounts[exorcistDosa], 2);
    expect(
      restored.seenCompendiumEntryIds,
      containsAll(['character:$rookieConstable', 'weapon:$hwandoSlash']),
    );
  });

  test(
    'legacy and unified settings survive alongside migrated saves',
    () async {
      SharedPreferences.setMockInitialValues({
        GameSettingsRepository.legacyMusicVolumeKey: 0.3,
        GameSettingsRepository.legacySfxVolumeKey: 0.4,
        GameSettingsRepository.legacyVibrationEnabledKey: false,
      });
      var preferences = await SharedPreferences.getInstance();
      var settings = await GameSettingsRepository(
        preferences: preferences,
      ).load();
      expect(settings.musicVolume, 0.3);
      expect(settings.sfxVolume, 0.4);
      expect(settings.vibrationEnabled, isFalse);

      SharedPreferences.setMockInitialValues({
        GameSettingsRepository.settingsKey: jsonEncode({
          'version': 1,
          'musicVolume': 0.6,
          'sfxVolume': 0.5,
          'vibrationEnabled': true,
          'screenShakeEnabled': false,
          'damageNumbersEnabled': false,
          'uiScale': 'large',
        }),
      });
      preferences = await SharedPreferences.getInstance();
      settings = await GameSettingsRepository(preferences: preferences).load();
      expect(settings.uiScale, UiScale.large);
      expect(settings.screenShakeEnabled, isFalse);
      expect(settings.damageNumbersEnabled, isFalse);
    },
  );
}

void _expectOriginalFields(
  SaveState restored, {
  required int kills,
  required int survival,
}) {
  expect(restored.schemaVersion, SaveState.currentSchemaVersion);
  expect(restored.unlockedCharacterIds, contains(exorcistDosa));
  expect(restored.unlockedWeaponIds, contains(talismanThrow));
  expect(restored.unlockedAugmentIds, contains(rapidReload));
  expect(restored.completedGoalIds, contains('survive_3_minutes'));
  expect(restored.totalKills, kills);
  expect(restored.bestSurvivalSeconds, survival);
}

void _expectPostV1Defaults(SaveState restored) {
  expect(restored.claimedRewardIds, isEmpty);
  expect(restored.wallet, Wallet.empty);
  expect(restored.trainingProgress, TrainingProgress.empty);
  expect(restored.shopProgress, ShopProgress.empty);
  expect(restored.selectedCharacterId, rookieConstable);
  expect(restored.selectedStageId, moonlitAbandonedOffice);
  expect(restored.unlockedStageIds, {moonlitAbandonedOffice});
  expect(restored.totalEliteKills, 0);
  expect(restored.victoryCount, 0);
  expect(restored.characterVictoryCounts, isEmpty);
  expect(restored.seenCompendiumEntryIds, isEmpty);
}
