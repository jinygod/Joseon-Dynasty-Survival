import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
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
  test('missing enemy visual contracts are exactly the eight planned IDs', () {
    expect(missingEightVisualContracts.keys.toSet(), ids);
    expect(
      missingEightVisualContracts,
      isA<Map<String, SpriteAtlasContract>>(),
    );
  });

  test('rights ledger binds each generated source to one reviewed runtime', () {
    final lines = File('docs/assets/asset-rights-ledger.csv').readAsLinesSync();
    final headers = lines.first.split(',');
    const expectedHeaders = [
      'asset_id',
      'runtime_path',
      'category',
      'acquisition_method',
      'creator_or_vendor',
      'provider_product_model',
      'created_or_purchased_at',
      'source_url',
      'terms_or_license_name',
      'terms_checked_at',
      'evidence_path',
      'source_file_sha256',
      'prompt_path',
      'input_rights_confirmed',
      'human_edits',
      'similarity_reviewed',
      'trademark_reviewed',
      'credit_required',
      'credit_text',
      'status',
      'reviewer',
      'reviewed_at',
      'notes',
    ];
    expect(headers, expectedHeaders);
    final rows = lines
        .skip(1)
        .map((line) => line.split(','))
        .where((columns) => ids.contains(columns.first))
        .toList();
    expect(rows, hasLength(8));
    for (final id in ids) {
      final columns = rows.singleWhere((columns) => columns.first == id);
      expect(columns, hasLength(headers.length), reason: id);
      final row = Map<String, String>.fromIterables(headers, columns);
      final sourcePath = 'art_source/generated/enemies/${id}_source.png';
      final runtimePath = 'assets/images/enemies/${id}_128.png';
      final sourceHash = sha256
          .convert(File(sourcePath).readAsBytesSync())
          .toString()
          .toUpperCase();
      final runtimeHash = sha256
          .convert(File(runtimePath).readAsBytesSync())
          .toString()
          .toUpperCase();
      expect(row['runtime_path'], runtimePath);
      expect(row['evidence_path'], sourcePath);
      expect(row['source_file_sha256'], sourceHash);
      expect(
        row['provider_product_model'],
        contains('OpenAI built-in image generation'),
      );
      expect(row['status'], 'review');
      expect(row['notes'], contains('runtime-sha256=$runtimeHash'));
      expect(row['notes'], contains('runtime owner=EnemySpriteSheet'));
      expect(row['notes'], contains('runtime status=temporary'));
      expect(row['notes'], contains('runtime use=enemy animation 4x4 128px'));
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
