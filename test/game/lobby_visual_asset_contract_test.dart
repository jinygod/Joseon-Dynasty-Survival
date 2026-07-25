import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/asset_catalog.dart';

void main() {
  test('release lobby catalog owns every required raster asset', () {
    expect(AssetCatalog.lobbyScene.keys, {
      'night_palace_landscape',
      'character_shadow',
    });
    expect(AssetCatalog.lobbyCharacters.keys, {
      'rookie_constable',
      'exorcist_dosa',
      'mountain_hunter',
    });
    expect(
      AssetCatalog.lobbyFrames.keys,
      containsAll({
        'profile',
        'resource',
        'side_command',
        'stage_plaque',
        'deploy',
        'quick_action',
        'primary_navigation',
        'feature_notice',
      }),
    );
    expect(
      AssetCatalog.lobbyIcons.keys,
      containsAll({
        'coin',
        'spirit_jade',
        'settings',
        'shop',
        'mission',
        'pass',
        'package',
        'mail',
        'compendium',
        'records',
        'character',
        'combat',
        'challenge',
        'growth',
        'weapon',
        'relic',
        'companion',
        'crafting',
      }),
    );
  });

  test(
    'release lobby raster assets exist with PNG dimensions and rights rows',
    () {
      final ledgerRows = File(
        'docs/assets/asset-rights-ledger.csv',
      ).readAsLinesSync();
      final runtimePathIndex = ledgerRows.first
          .split(',')
          .indexOf('runtime_path');
      final paths = <String>{
        ...AssetCatalog.lobbyScene.values,
        ...AssetCatalog.lobbyCharacters.values,
        ...AssetCatalog.lobbyFrames.values,
        ...AssetCatalog.lobbyIcons.values,
      };

      for (final path in paths) {
        expect(path, startsWith('assets/images/'));
        expect(path, endsWith('.png'));

        final file = File(path);
        expect(
          file.existsSync(),
          isTrue,
          reason: 'Missing lobby raster: $path',
        );

        final bytes = file.readAsBytesSync();
        expect(bytes.length, greaterThanOrEqualTo(24), reason: path);
        expect(bytes.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
        expect(_readUint32(bytes, 16), greaterThan(0), reason: path);
        expect(_readUint32(bytes, 20), greaterThan(0), reason: path);

        final matchingRows = ledgerRows
            .skip(1)
            .where((row) => row.split(',')[runtimePathIndex] == path);
        expect(matchingRows, hasLength(1), reason: 'Missing rights row: $path');
      }
    },
  );
}

int _readUint32(List<int> bytes, int offset) =>
    (bytes[offset] << 24) |
    (bytes[offset + 1] << 16) |
    (bytes[offset + 2] << 8) |
    bytes[offset + 3];
