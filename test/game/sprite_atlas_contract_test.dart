import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/asset_catalog.dart';
import 'package:pixel_survivor/game/content/sprite_atlas_contract.dart';

void main() {
  test(
    'legacy replaceable atlases are temporary and registered in AssetCatalog',
    () {
      final legacyContracts = ReplaceableArtCatalog.atlases.where(
        (contract) =>
            !ReplaceableArtCatalog.representativeAtlasIds.contains(contract.id),
      );

      for (final contract in legacyContracts) {
        expect(
          File(contract.runtimePath).existsSync(),
          isTrue,
          reason: contract.id,
        );
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
    },
  );

  test('atlas geometry exposes exact pixel dimensions', () {
    final player = ReplaceableArtCatalog.byId('exorcist_swordswoman_player');
    final combat = ReplaceableArtCatalog.byId('combat_effects_atlas');

    expect((player.pixelWidth, player.pixelHeight), (64, 64));
    expect((combat.pixelWidth, combat.pixelHeight), (256, 320));
    expect(player.frameIndex(column: 0, row: 0), 0);
    expect(combat.frameIndex(column: 3, row: 4), 19);
  });

  test('representative balanced casual atlases reserve 512px RGBA grids', () {
    expect(ReplaceableArtCatalog.representativeAtlasIds, {
      'exorcist_dosa_balanced_casual',
      'plague_rat_swarm_balanced_casual',
      'vengeful_spirit_balanced_casual',
      'sakkat_specter_balanced_casual',
      'dokkaebi_balanced_casual',
      'bandit_balanced_casual',
    });

    for (final id in ReplaceableArtCatalog.representativeAtlasIds) {
      final atlas = ReplaceableArtCatalog.byId(id);
      expect(atlas.frameWidth, 128, reason: id);
      expect(atlas.frameHeight, 128, reason: id);
      expect(atlas.columns, 4, reason: id);
      expect(atlas.rows, 4, reason: id);
      expect(atlas.pixelWidth, 512, reason: id);
      expect(atlas.pixelHeight, 512, reason: id);
      expect(atlas.requiresTransparency, isTrue, reason: id);
      expect(atlas.status, ArtAssetStatus.temporary, reason: id);
    }

    final temporarilyUnbundledIds = ReplaceableArtCatalog.atlases
        .where(
          (atlas) =>
              atlas.status == ArtAssetStatus.temporary &&
              !File(atlas.runtimePath).existsSync(),
        )
        .map((atlas) => atlas.id)
        .toSet();
    expect(temporarilyUnbundledIds, isEmpty);

    for (final id in ReplaceableArtCatalog.representativeAtlasIds) {
      final atlas = ReplaceableArtCatalog.byId(id);
      expect(File(atlas.runtimePath).existsSync(), isTrue, reason: id);
      expect(
        atlas.validatePngHeader(File(atlas.runtimePath).readAsBytesSync()),
        isEmpty,
        reason: id,
      );
      expect(AssetCatalog.allPaths, contains(atlas.runtimePath), reason: id);
    }
  });

  test('frame lookup rejects coordinates outside the atlas contract', () {
    final contract = ReplaceableArtCatalog.byId('exorcist_swordswoman_player');

    expect(
      () => contract.frameIndex(column: contract.columns, row: 0),
      throwsRangeError,
    );
    expect(() => contract.frameIndex(column: 0, row: -1), throwsRangeError);
  });

  test('every legacy replaceable atlas matches its PNG contract', () {
    for (final contract in ReplaceableArtCatalog.atlases.where(
      (contract) =>
          !ReplaceableArtCatalog.representativeAtlasIds.contains(contract.id),
    )) {
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
