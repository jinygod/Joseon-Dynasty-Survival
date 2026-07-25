import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/asset_catalog.dart';
import 'package:pixel_survivor/game/content/sprite_atlas_contract.dart';

void main() {
  test('replaceable atlases declare review status and AssetCatalog path', () {
    expect(ReplaceableArtCatalog.atlases.length, greaterThanOrEqualTo(16));

    final runtimeAtlases = ReplaceableArtCatalog.atlases.where(
      (contract) => !missingEightVisualContracts.containsKey(contract.id),
    );
    for (final contract in runtimeAtlases) {
      final isApprovedReleaseAsset =
          contract.id.startsWith('hwando_release_') ||
          const {
            'singijeon_128',
            'matchlock_shot_128',
            'hawk_flight_128',
            'projectile_contact_128',
          }.contains(contract.id);
      expect(
        contract.status,
        isApprovedReleaseAsset
            ? ArtAssetStatus.approved
            : ArtAssetStatus.temporary,
        reason: contract.id,
      );
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
    final player = ReplaceableArtCatalog.byId('exorcist_swordswoman_player');
    final combat = ReplaceableArtCatalog.byId('combat_effects_atlas');

    expect((player.pixelWidth, player.pixelHeight), (64, 64));
    expect((combat.pixelWidth, combat.pixelHeight), (256, 320));
    expect(player.frameIndex(column: 0, row: 0), 0);
    expect(combat.frameIndex(column: 3, row: 4), 19);
  });

  test('frame lookup rejects coordinates outside the atlas contract', () {
    final contract = ReplaceableArtCatalog.byId('exorcist_swordswoman_player');

    expect(
      () => contract.frameIndex(column: contract.columns, row: 0),
      throwsRangeError,
    );
    expect(() => contract.frameIndex(column: 0, row: -1), throwsRangeError);
  });

  test('every replaceable atlas matches its PNG contract', () {
    final runtimeAtlases = ReplaceableArtCatalog.atlases.where(
      (contract) => !missingEightVisualContracts.containsKey(contract.id),
    );
    for (final contract in runtimeAtlases) {
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
