import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/audio/audio_asset_catalog.dart';
import 'package:pixel_survivor/game/audio/audio_cue.dart';
import 'package:pixel_survivor/game/content/asset_catalog.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/content_integrity.dart';
import 'package:pixel_survivor/game/content/ids.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';

void main() {
  test('aggregate report is deterministic and covers bundled contracts', () {
    final images = bundledImagePathsFromDisk();
    final first = validateContentIntegrity(bundledImagePaths: images);
    final second = validateContentIntegrity(bundledImagePaths: images);

    expect(first.issues, second.issues);
    expect(first.isValid, isTrue);
    expect(
      AssetCatalog.characters.keys,
      containsAll(characterDefinitions.map((item) => item.id)),
    );
    expect(
      AssetCatalog.weapons.keys,
      containsAll(weaponDefinitions.map((item) => item.id)),
    );
    expect(AudioAssetCatalog.assets.keys.toSet(), AudioCue.values.toSet());
  });

  test('malformed injected catalog reports duplicates and bad references', () {
    const duplicateCharacter = CharacterDefinition(
      id: rookieConstable,
      name: 'Duplicate',
      maxHealth: 1,
      moveSpeed: 1,
      damageMultiplier: 1,
      startingWeaponId: 'missing_weapon',
    );

    final report = validateContentIntegrity(
      characters: const [duplicateCharacter, duplicateCharacter],
      expectedCounts: const ContentRosterCounts(
        characters: 2,
        weapons: 8,
        weaponLevels: 40,
        augments: 16,
        normalEnemies: 8,
        eliteEnemies: 3,
        stages: 2,
        bosses: 3,
        unlockGoals: 15,
      ),
      bundledImagePaths: bundledImagePathsFromDisk(),
    );

    expect(report.issues, contains('Duplicate character id: $rookieConstable'));
    expect(
      report.issues,
      contains('Unknown starting weapon: $rookieConstable/missing_weapon'),
    );
  });

  test('audio paths agree with their declared channels', () {
    final report = validateContentIntegrity(
      bundledImagePaths: bundledImagePathsFromDisk(),
    );
    expect(
      report.issues.where((issue) => issue.startsWith('Invalid audio')),
      isEmpty,
    );

    for (final entry in AudioAssetCatalog.assets.entries) {
      final prefix = switch (AudioCueCatalog.channelFor(entry.key)) {
        AudioChannel.music => 'audio/music/',
        AudioChannel.sfx => 'audio/sfx/',
        AudioChannel.ui => 'audio/ui/',
      };
      expect(entry.value.path, startsWith(prefix), reason: entry.key.name);
      expect(File('assets/${entry.value.path}').existsSync(), isTrue);
    }
  });
}

Set<String> bundledImagePathsFromDisk() => Directory('assets/images')
    .listSync(recursive: true)
    .whereType<File>()
    .map((file) => file.path.replaceAll('\\', '/'))
    .toSet();
