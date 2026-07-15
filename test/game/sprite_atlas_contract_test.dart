import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/asset_catalog.dart';
import 'package:pixel_survivor/game/content/sprite_atlas_contract.dart';

void main() {
  test('replaceable atlases are temporary and registered in AssetCatalog', () {
    expect(ReplaceableArtCatalog.atlases, hasLength(8));

    for (final contract in ReplaceableArtCatalog.atlases) {
      expect(contract.status, ArtAssetStatus.temporary, reason: contract.id);
      expect(
        AssetCatalog.allPaths,
        contains(contract.runtimePath),
        reason: contract.id,
      );
      expect(
        contract.assetKey,
        contract.runtimePath.replaceFirst('assets/', ''),
        reason: contract.id,
      );
    }
  });

  test('atlas geometry exposes exact pixel dimensions', () {
    final player = ReplaceableArtCatalog.byId('rookie_constable_player');
    final combat = ReplaceableArtCatalog.byId('combat_effects_atlas');

    expect((player.pixelWidth, player.pixelHeight), (128, 128));
    expect((combat.pixelWidth, combat.pixelHeight), (256, 320));
    expect(player.frameIndex(column: 3, row: 3), 15);
    expect(combat.frameIndex(column: 3, row: 4), 19);
  });

  test('frame lookup rejects coordinates outside the atlas contract', () {
    final contract = ReplaceableArtCatalog.byId('rookie_constable_player');

    expect(
      () => contract.frameIndex(column: contract.columns, row: 0),
      throwsRangeError,
    );
    expect(() => contract.frameIndex(column: 0, row: -1), throwsRangeError);
  });

  test('every replaceable atlas matches its PNG contract', () {
    for (final contract in ReplaceableArtCatalog.atlases) {
      final file = File(contract.runtimePath);
      expect(file.existsSync(), isTrue, reason: contract.id);
      expect(
        contract.validatePngHeader(file.readAsBytesSync()),
        isEmpty,
        reason: contract.id,
      );
    }
  });

  test('PNG validation reports malformed files without throwing', () {
    final errors = ReplaceableArtCatalog.atlases.first.validatePngHeader(
      Uint8List.fromList([1, 2, 3]),
    );

    expect(errors, contains('invalid PNG signature'));
  });
}
