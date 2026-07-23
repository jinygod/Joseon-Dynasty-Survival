import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/asset_catalog.dart';
import 'package:pixel_survivor/game/content/attack_visual_registry.dart';
import 'package:pixel_survivor/game/content/sprite_atlas_contract.dart';

const requiredPlayerVisualIds = <String>[
  'sealing_slash',
  'wind_thunder_fan',
  'singijeon_volley',
  'jangseung_ward',
  'frost_flask',
  'talisman_attachment',
  'talisman_transfer',
  'talisman_explosion',
  'talisman_small_ward',
  'talisman_master_ward',
];

void main() {
  test('all player combat IDs have non-missing visual specs', () {
    for (final id in requiredPlayerVisualIds) {
      final spec = AttackVisualRegistry.byId(id);
      expect(spec.status, isNot(AttackVisualStatus.missing), reason: id);
      expect(spec.layers, isNotEmpty, reason: id);
    }
  });

  test('player visual sheets have atlas, catalog, and RGBA coverage', () {
    for (final id in requiredPlayerVisualIds) {
      final spec = AttackVisualRegistry.byId(id);
      for (final layer in spec.layers) {
        final runtimePath = 'assets/images/${layer.assetKey}';
        final contract = ReplaceableArtCatalog.atlases.singleWhere(
          (contract) => contract.runtimePath == runtimePath,
        );

        expect(AssetCatalog.allPaths, contains(runtimePath), reason: id);
        expect(contract.frameWidth, 128, reason: id);
        expect(contract.frameHeight, 128, reason: id);
        expect(contract.columns, layer.frameCount, reason: id);
        expect(contract.rows, 1, reason: id);
        expect(
          contract.validatePngHeader(File(runtimePath).readAsBytesSync()),
          isEmpty,
          reason: id,
        );
      }
    }
  });
}
