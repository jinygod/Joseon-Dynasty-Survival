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
  for (final schema in <int?>[null, 1, 2, 3]) {
    test(
      'schema ${schema ?? 'versionless'} preserves available player data',
      () {
        final payload = <String, dynamic>{
          if (schema != null) 'schemaVersion': schema,
          'unlockedCharacterIds': [rookieConstable, exorcistDosa],
          'unlockedWeaponIds': [hwandoSlash, talismanThrow],
          'unlockedAugmentIds': [martialTraining, rapidReload],
          'unlockedStageIds': [moonlitAbandonedOffice, plagueMarket],
          'completedGoalIds': ['survive_3_minutes'],
          'wallet': {'coin': 77, 'spiritJade': 4},
          'selectedCharacterId': exorcistDosa,
          'selectedStageId': plagueMarket,
          'totalKills': 321,
          'bestSurvivalSeconds': 240,
          'characterVictoryCounts': {exorcistDosa: 2},
          'seenCompendiumEntryIds': ['character:$rookieConstable'],
        };

        final restored = SaveState.fromJson(payload);

        expect(restored.unlockedCharacterIds, contains(exorcistDosa));
        expect(restored.unlockedWeaponIds, contains(talismanThrow));
        expect(restored.unlockedAugmentIds, contains(rapidReload));
        expect(restored.unlockedStageIds, contains(plagueMarket));
        expect(restored.wallet, const Wallet(coin: 77, spiritJade: 4));
        expect(restored.selectedCharacterId, exorcistDosa);
        expect(restored.selectedStageId, plagueMarket);
        expect(restored.totalKills, 321);
        expect(restored.bestSurvivalSeconds, 240);
        expect(restored.characterVictoryCounts[exorcistDosa], 2);
        expect(
          restored.seenCompendiumEntryIds,
          contains('character:$rookieConstable'),
        );
      },
    );
  }

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
