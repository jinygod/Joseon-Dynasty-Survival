import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/sprite_atlas_contract.dart';

void main() {
  const ids = <String>{
    'sakkat_specter',
    'plague_crow',
    'spear_bandit',
    'rotten_herbalist',
    'grave_ember',
    'black_hat_assassin',
    'broken_jangseung_spirit',
    'sorrowful_maiden_ghost',
  };

  test('missing enemy visual contracts are exactly the eight planned IDs', () {
    expect(missingEightVisualContracts.keys.toSet(), ids);
    expect(missingEightVisualContracts, isA<Map<String, SpriteAtlasContract>>());
  });

  test('missing enemy contracts lock their immutable atlas geometry and paths', () {
    final contracts = missingEightVisualContracts.values.toList();
    expect(contracts.map((contract) => contract.id).toSet(), ids);
    expect(contracts.map((contract) => contract.runtimePath).toSet(), hasLength(8));

    for (final contract in contracts) {
      expect(contract.runtimePath, 'assets/images/enemies/${contract.id}_128.png');
      expect((contract.frameWidth, contract.frameHeight), (128, 128));
      expect((contract.columns, contract.rows), (4, 4));
      expect((contract.pixelWidth, contract.pixelHeight), (512, 512));
      expect(contract.requiresTransparency, isTrue);
      expect(contract.status, ArtAssetStatus.temporary);
    }
  });

  test('missing enemy contracts are included once and resolve from the catalog', () {
    for (final entry in missingEightVisualContracts.entries) {
      final included = ReplaceableArtCatalog.atlases
          .where((contract) => contract.id == entry.key)
          .toList();
      expect(included, [entry.value]);
      expect(ReplaceableArtCatalog.byId(entry.key), entry.value);
    }
  });

  test('missing enemy runtime PNGs remain intentionally absent during contract phase', () {
    for (final contract in missingEightVisualContracts.values) {
      expect(File(contract.runtimePath).existsSync(), isFalse, reason: contract.id);
    }
  });

  test('enemy production brief locks shared animation and individual exclusions', () {
    final brief = File('docs/assets/prompts/missing-eight-enemy-sheets.md')
        .readAsStringSync()
        .toLowerCase();
    for (final id in ids) {
      expect(brief, contains(id));
    }
    for (final required in [
      'frames 0-3: move',
      'frames 4-7: attack',
      'frames 8-9: hit',
      'frames 10-15: death',
      'transparent background',
      'three-quarter-right',
      'foot/hover anchor',
      'persistent hazards',
      'telegraphs',
      'shockwaves',
      'scream zones',
      'not vengeful spirit',
      'not rat/humanoid',
      'not knife bandit',
      'no baked poison pool',
      'not dokkaebi/humanoid',
      'not bandit/general',
      'no full shockwave baked in',
      'not vengeful-spirit hair/sakkat',
    ]) {
      expect(brief, contains(required));
    }
    expect(brief, isNot(contains('placeholder')));
  });
}
