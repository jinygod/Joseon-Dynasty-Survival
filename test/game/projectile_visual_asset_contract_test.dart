import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/asset_catalog.dart';
import 'package:pixel_survivor/game/content/sprite_atlas_contract.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sheets = <String, ({int columns, int rows})>{
    'assets/images/projectiles/player/singijeon_128.png': (columns: 4, rows: 1),
    'assets/images/projectiles/player/matchlock_shot_128.png': (
      columns: 4,
      rows: 1,
    ),
    'assets/images/projectiles/player/hawk_flight_128.png': (
      columns: 4,
      rows: 1,
    ),
    'assets/images/vfx/player/projectile_contact_128.png': (
      columns: 6,
      rows: 1,
    ),
  };

  test('release projectile sheets have approved runtime contracts', () {
    for (final entry in sheets.entries) {
      final contract = ReplaceableArtCatalog.atlases.singleWhere(
        (candidate) => candidate.runtimePath == entry.key,
      );
      expect(contract.status, ArtAssetStatus.approved, reason: entry.key);
      expect(contract.frameWidth, 128, reason: entry.key);
      expect(contract.frameHeight, 128, reason: entry.key);
      expect(contract.columns, entry.value.columns, reason: entry.key);
      expect(contract.rows, entry.value.rows, reason: entry.key);
      expect(AssetCatalog.allPaths, contains(entry.key), reason: entry.key);
    }
  });

  for (final entry in sheets.entries) {
    test('${entry.key} is readable RGBA art with clear cell corners', () async {
      final file = File(entry.key);
      expect(file.existsSync(), isTrue, reason: entry.key);

      final codec = await ui.instantiateImageCodec(await file.readAsBytes());
      final image = (await codec.getNextFrame()).image;
      expect(image.width, 128 * entry.value.columns, reason: entry.key);
      expect(image.height, 128 * entry.value.rows, reason: entry.key);

      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      expect(data, isNotNull);
      final rgba = data!.buffer.asUint8List();

      for (var column = 0; column < entry.value.columns; column += 1) {
        final left = column * 128;
        final cornerAlpha = <int>[
          _alphaAt(rgba, image.width, left, 0),
          _alphaAt(rgba, image.width, left + 127, 0),
          _alphaAt(rgba, image.width, left, 127),
          _alphaAt(rgba, image.width, left + 127, 127),
        ];
        expect(cornerAlpha, everyElement(0), reason: '${entry.key}#$column');
        expect(
          _opaquePixelCount(rgba, image.width, left),
          greaterThan(24),
          reason: '${entry.key}#$column',
        );
      }
    });
  }

  test(
    'Singijeon cells contain no long opaque rectangular frame edge',
    () async {
      final file = File('assets/images/projectiles/player/singijeon_128.png');
      final codec = await ui.instantiateImageCodec(await file.readAsBytes());
      final image = (await codec.getNextFrame()).image;
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final rgba = data!.buffer.asUint8List();

      for (var column = 0; column < 4; column += 1) {
        expect(
          _longestVerticalOpaqueRun(rgba, image.width, column * 128),
          lessThan(48),
          reason: 'opaque box edge in Singijeon frame $column',
        );
      }
    },
  );
}

int _alphaAt(List<int> rgba, int imageWidth, int x, int y) {
  return rgba[(y * imageWidth + x) * 4 + 3];
}

int _opaquePixelCount(List<int> rgba, int imageWidth, int cellLeft) {
  var count = 0;
  for (var y = 0; y < 128; y += 1) {
    for (var x = 0; x < 128; x += 1) {
      if (_alphaAt(rgba, imageWidth, cellLeft + x, y) > 32) {
        count += 1;
      }
    }
  }
  return count;
}

int _longestVerticalOpaqueRun(List<int> rgba, int imageWidth, int cellLeft) {
  var longest = 0;
  for (var x = 0; x < 128; x += 1) {
    var current = 0;
    for (var y = 0; y < 128; y += 1) {
      if (_alphaAt(rgba, imageWidth, cellLeft + x, y) > 64) {
        current += 1;
        if (current > longest) longest = current;
      } else {
        current = 0;
      }
    }
  }
  return longest;
}
