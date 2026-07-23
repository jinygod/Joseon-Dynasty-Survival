import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/content/asset_catalog.dart';
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
  const hashes = <String, (String, String)>{
    'sakkat_specter': (
      '45AA45512102B67C9E6682AAC4DA250950ACDF3A30727596F1DFF76BFB09517B',
      '5604F6B3EABAE514234A3891E715588E33DC1ABF5F891710482DB50EBA2BEF34',
    ),
    'plague_crow': (
      '0FA5596D40F2DF708A783891E4E4484A6BB8E0986CF600DC1A066742C74AEC80',
      '4F78D7EBC0E440E739B735F3798D2BFD05E89243FD8F583F5630362BD34D215A',
    ),
    'spear_bandit': (
      '7A77A188CA25D99DEB0B58EFCA6E230A5D97887C23BBF5581004D3B4C950ABB5',
      '06C04864BDC8E7CAE7375756558E6DAA09A6952ACC0153A694D2308647312122',
    ),
    'rotten_herbalist': (
      '5D44394EA69B0B58738A2DD41190A27BBCD50E6040F89182FE325DF247FA597C',
      '41BB47D809A5F67706E405B121BD9E01328F53CC31C32DDCAB6B08114939C047',
    ),
    'grave_ember': (
      'B15FC618E95E5EADA126EF0A768D7EA9728DA9137DAC6DB9854A8D08A413704D',
      'EDCA3B7592B5FE8845F2D3B35CB284BB5FC3C86A9E1B862BDC9C71BE0DE5FDDA',
    ),
    'black_hat_assassin': (
      '1121A178D1DE650AA3A9CA54942AA83A4449C1BF67BC492D87981E46BCAFF435',
      'C642642511C65EBC3A8124D020AA5BCB3F80E45410363623F12E5C861E04BDC3',
    ),
    'broken_jangseung_spirit': (
      '933467A779DED0C535B4BD3044B6515EE959E262FFD08075762F30EBDFC5D52C',
      '92B057F8A2B69E256956607355362E98B20BBD6A35E9368B69BC27B105EE96D2',
    ),
    'sorrowful_maiden_ghost': (
      '43DB700A55DE3C45B584A9CBEED8F181FC645858EC51E93EA1DFE26E1F245398',
      '50AB409550310283B6025EEFD90563C9637D314B02431EDAF27F29AA28BDEA36',
    ),
  };

  test('missing enemy visual contracts are exactly the eight planned IDs', () {
    expect(missingEightVisualContracts.keys.toSet(), ids);
    expect(
      missingEightVisualContracts,
      isA<Map<String, SpriteAtlasContract>>(),
    );
  });

  test('rights ledger binds each generated source to one reviewed runtime', () {
    final rows = File('docs/assets/asset-rights-ledger.csv')
        .readAsLinesSync()
        .skip(1)
        .where((row) => ids.contains(row.split(',').first))
        .toList();
    expect(rows, hasLength(8));
    for (final id in ids) {
      final row = rows.singleWhere((row) => row.startsWith('$id,'));
      final (sourceHash, runtimeHash) = hashes[id]!;
      expect(row, contains('assets/images/enemies/${id}_128.png'));
      expect(row, contains('art_source/generated/enemies/${id}_source.png'));
      expect(row, contains(sourceHash));
      expect(row, contains('runtime-sha256=$runtimeHash'));
      expect(row, contains('OpenAI built-in image generation'));
      expect(row, contains('runtime owner=EnemySpriteSheet'));
      expect(row, contains('runtime status=temporary'));
      expect(row, contains('runtime use=enemy animation 4x4 128px'));
    }
  });

  test(
    'missing enemy contracts lock their immutable atlas geometry and paths',
    () {
      final contracts = missingEightVisualContracts.values.toList();
      expect(contracts.map((contract) => contract.id).toSet(), ids);
      expect(
        contracts.map((contract) => contract.runtimePath).toSet(),
        hasLength(8),
      );

      for (final contract in contracts) {
        expect(
          contract.runtimePath,
          'assets/images/enemies/${contract.id}_128.png',
        );
        expect((contract.frameWidth, contract.frameHeight), (128, 128));
        expect((contract.columns, contract.rows), (4, 4));
        expect((contract.pixelWidth, contract.pixelHeight), (512, 512));
        expect(contract.requiresTransparency, isTrue);
        expect(contract.status, ArtAssetStatus.temporary);
      }
    },
  );

  test(
    'missing enemy contracts are included once and resolve from the catalog',
    () {
      for (final entry in missingEightVisualContracts.entries) {
        final included = ReplaceableArtCatalog.atlases
            .where((contract) => contract.id == entry.key)
            .toList();
        expect(included, [entry.value]);
        expect(ReplaceableArtCatalog.byId(entry.key), entry.value);
      }
    },
  );

  test(
    'enemy sheets are unique packaged runtime assets with matching specs',
    () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('- assets/images/enemies/'));

      for (final contract in missingEightVisualContracts.values) {
        expect(
          File(contract.runtimePath).existsSync(),
          isTrue,
          reason: contract.id,
        );
        expect(AssetCatalog.monsters[contract.id], contract.runtimePath);
        final spec = EnemySpriteSheet.specs[contract.id]!;
        expect(spec.assetKey, 'enemies/${contract.id}_128.png');
        expect(spec.frameSize, 128);
        expect(
          contract.validatePngHeader(
            File(contract.runtimePath).readAsBytesSync(),
          ),
          isEmpty,
          reason: contract.id,
        );
      }

      expect(
        AssetCatalog.monsters.entries
            .where((entry) => ids.contains(entry.key))
            .map((entry) => entry.value)
            .toSet(),
        missingEightVisualContracts.values
            .map((contract) => contract.runtimePath)
            .toSet(),
      );
    },
  );

  test('enemy runtime PNG headers lock 512px RGBA 4x4 grids', () {
    for (final contract in missingEightVisualContracts.values) {
      final bytes = File(contract.runtimePath).readAsBytesSync();
      int readUint32(int offset) =>
          (bytes[offset] << 24) |
          (bytes[offset + 1] << 16) |
          (bytes[offset + 2] << 8) |
          bytes[offset + 3];

      expect(bytes.sublist(1, 4), [80, 78, 71], reason: contract.id);
      expect(readUint32(16), 512, reason: contract.id);
      expect(readUint32(20), 512, reason: contract.id);
      expect(bytes[25], 6, reason: '${contract.id} must be RGBA');
    }
  });

  test(
    'enemy sheets have isolated padded alpha cells without green chroma',
    () async {
      for (final contract in missingEightVisualContracts.values) {
        final codec = await ui.instantiateImageCodec(
          File(contract.runtimePath).readAsBytesSync(),
        );
        final frame = await codec.getNextFrame();
        final bytes = (await frame.image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final rgba = bytes.buffer.asUint8List();

        int alphaAt(int x, int y) => rgba[(y * 512 + x) * 4 + 3];
        for (var cellY = 0; cellY < 4; cellY++) {
          for (var cellX = 0; cellX < 4; cellX++) {
            final left = cellX * 128;
            final top = cellY * 128;
            var minX = 128;
            var minY = 128;
            var maxX = -1;
            var maxY = -1;
            var greenPixels = 0;
            for (var y = 0; y < 128; y++) {
              for (var x = 0; x < 128; x++) {
                final offset = ((top + y) * 512 + left + x) * 4;
                final alpha = rgba[offset + 3];
                if (alpha == 0) continue;
                minX = minX < x ? minX : x;
                minY = minY < y ? minY : y;
                maxX = maxX > x ? maxX : x;
                maxY = maxY > y ? maxY : y;
                if (rgba[offset + 1] >= 180 &&
                    rgba[offset + 1] > rgba[offset] * 1.35 &&
                    rgba[offset + 1] > rgba[offset + 2] * 1.35) {
                  greenPixels++;
                }
              }
            }
            final label = '${contract.id} cell ${cellY * 4 + cellX}';
            expect(maxX, greaterThanOrEqualTo(0), reason: label);
            expect(minX, greaterThanOrEqualTo(4), reason: label);
            expect(minY, greaterThanOrEqualTo(4), reason: label);
            expect(maxX, lessThanOrEqualTo(123), reason: label);
            expect(maxY, lessThanOrEqualTo(123), reason: label);
            expect(greenPixels, 0, reason: label);
            for (var edge = 0; edge < 128; edge++) {
              expect(alphaAt(left + edge, top), 0, reason: label);
              expect(alphaAt(left + edge, top + 127), 0, reason: label);
              expect(alphaAt(left, top + edge), 0, reason: label);
              expect(alphaAt(left + 127, top + edge), 0, reason: label);
            }
          }
        }
        frame.image.dispose();
        codec.dispose();
      }
    },
  );

  test(
    'enemy production brief locks shared animation and individual exclusions',
    () {
      final brief = File(
        'docs/assets/prompts/missing-eight-enemy-sheets.md',
      ).readAsStringSync().toLowerCase();
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
    },
  );
}
