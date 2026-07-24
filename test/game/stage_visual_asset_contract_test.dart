import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/asset_catalog.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';
import 'package:pixel_survivor/game/content/stage_visual_spec.dart';

const _stageIds = <String>[moonlitAbandonedOffice, plagueMarket];
const _sourcePaths = <String>[
  'art_source/generated/stages/moonlit_office_tiles_source.png',
  'art_source/generated/stages/moonlit_office_decals_chroma_source.png',
  'art_source/generated/stages/moonlit_office_props_chroma_source.png',
  'art_source/generated/stages/plague_market_tiles_source.png',
  'art_source/generated/stages/plague_market_decals_chroma_source.png',
  'art_source/generated/stages/plague_market_props_chroma_source.png',
];

void main() {
  test('stage visual specs expose exactly the two authored atlas sets', () {
    expect(stageVisualSpecs.keys.toSet(), _stageIds.toSet());

    final tileKeys = <String>{};
    final propKeys = <String>{};
    for (final stageId in _stageIds) {
      final spec = stageVisualSpecFor(stageId);
      expect(spec.tileAssetKey, startsWith('tiles/'));
      expect(spec.decalAssetKey, spec.tileAssetKey);
      expect(spec.propAssetKey, startsWith('props/'));
      expect(spec.tileVariants, 4);
      expect(spec.decalVariants, 4);
      expect(spec.propVariants, 8);
      tileKeys.add(spec.tileAssetKey);
      propKeys.add(spec.propAssetKey!);
    }
    expect(tileKeys, {
      'tiles/moonlit_office_tiles_128.png',
      'tiles/plague_market_tiles_128.png',
    });
    expect(propKeys, {
      'props/moonlit_office_props_128.png',
      'props/plague_market_props_128.png',
    });
  });

  test('stage runtime atlases are exact 128px RGBA grids without chroma', () {
    for (final stageId in _stageIds) {
      final spec = stageVisualSpecFor(stageId);
      for (final key in [spec.tileAssetKey, spec.propAssetKey!]) {
        final png = _PngRgba.read('assets/images/$key');
        expect(png.width, 512, reason: key);
        expect(png.height, 256, reason: key);
        expect(png.colorType, 6, reason: '$key must be RGBA');
        expect(png.width % 128, 0, reason: key);
        expect(png.height % 128, 0, reason: key);
        expect(png.hasBrightGreenRemnant, isFalse, reason: key);
      }
    }
  });

  test('tile bases are opaque and decals have transparent padded cells', () {
    for (final stageId in _stageIds) {
      final png = _PngRgba.read(
        'assets/images/${stageVisualSpecFor(stageId).tileAssetKey}',
      );
      for (var index = 0; index < 4; index++) {
        expect(
          png.cell(index).isFullyOpaque,
          isTrue,
          reason: '$stageId base $index',
        );
      }
      for (var index = 4; index < 8; index++) {
        final cell = png.cell(index);
        expect(
          cell.hasTransparentBackground,
          isTrue,
          reason: '$stageId decal $index',
        );
        expect(cell.hasVisibleContent, isTrue, reason: '$stageId decal $index');
        expect(
          cell.hasAtLeastPadding(4),
          isTrue,
          reason: '$stageId decal $index',
        );
      }
    }
  });

  test('all eight prop cells are visible, transparent, and padded', () {
    for (final stageId in _stageIds) {
      final png = _PngRgba.read(
        'assets/images/${stageVisualSpecFor(stageId).propAssetKey}',
      );
      for (var index = 0; index < 8; index++) {
        final cell = png.cell(index);
        expect(
          cell.hasTransparentBackground,
          isTrue,
          reason: '$stageId prop $index',
        );
        expect(cell.hasVisibleContent, isTrue, reason: '$stageId prop $index');
        expect(
          cell.hasAtLeastPadding(4),
          isTrue,
          reason: '$stageId prop $index',
        );
      }
    }
  });

  test('catalog and pubspec cover the exact runtime asset paths', () {
    expect(AssetCatalog.stages, {
      moonlitAbandonedOffice:
          'assets/images/tiles/moonlit_office_tiles_128.png',
      plagueMarket: 'assets/images/tiles/plague_market_tiles_128.png',
    });
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('    - assets/images/tiles/'));
    expect(pubspec, contains('    - assets/images/props/'));
  });

  test('stage presentation catalog uses approved explicit missing-art states', () {
    expect(AssetCatalog.stagePresentation, {
      'moonlit_abandoned_office_presentation':
          'assets/images/stages/moonlit_office_card.png',
      'plague_market_presentation':
          'assets/images/stages/plague_market_card.png',
    });
    for (final path in AssetCatalog.stagePresentation.values) {
      expect(
        File(path).existsSync(),
        isFalse,
        reason: '$path intentionally renders the ASSET MISSING debug state',
      );
    }
  });

  test('ledger binds every stage source to its exact runtime record', () {
    final rows = _LedgerRow.readAll('docs/assets/asset-rights-ledger.csv');
    final expected = <String, _StageLedgerExpectation>{
      'moonlit_office_tiles_128': const _StageLedgerExpectation(
        runtimePath: 'assets/images/tiles/moonlit_office_tiles_128.png',
        primarySourcePath:
            'art_source/generated/stages/moonlit_office_tiles_source.png',
        decalSourcePath:
            'art_source/generated/stages/moonlit_office_decals_chroma_source.png',
      ),
      'plague_market_tiles_128': const _StageLedgerExpectation(
        runtimePath: 'assets/images/tiles/plague_market_tiles_128.png',
        primarySourcePath:
            'art_source/generated/stages/plague_market_tiles_source.png',
        decalSourcePath:
            'art_source/generated/stages/plague_market_decals_chroma_source.png',
      ),
      'moonlit_office_props_128': const _StageLedgerExpectation(
        runtimePath: 'assets/images/props/moonlit_office_props_128.png',
        primarySourcePath:
            'art_source/generated/stages/moonlit_office_props_chroma_source.png',
      ),
      'plague_market_props_128': const _StageLedgerExpectation(
        runtimePath: 'assets/images/props/plague_market_props_128.png',
        primarySourcePath:
            'art_source/generated/stages/plague_market_props_chroma_source.png',
      ),
    };
    final stageRows = rows
        .where((row) => expected.containsKey(row['asset_id']))
        .toList(growable: false);
    expect(stageRows, hasLength(4));
    expect(
      stageRows.map((row) => row['asset_id']).toSet(),
      expected.keys.toSet(),
    );

    for (final row in stageRows) {
      final assetId = row['asset_id']!;
      final record = expected[assetId]!;
      expect(row['runtime_path'], record.runtimePath, reason: assetId);
      expect(row['evidence_path'], record.primarySourcePath, reason: assetId);
      expect(row['prompt_path'], record.primarySourcePath, reason: assetId);
      expect(row['source_file_sha256'], _sha256(record.primarySourcePath));
      expect(row['acquisition_method'], 'ai_generated');
      expect(row['creator_or_vendor'], 'OpenAI');
      expect(
        row['provider_product_model'],
        'OpenAI built-in image generation model-id-not-exposed',
      );
      expect(row['created_or_purchased_at'], '2026-07-23');
      expect(row['terms_or_license_name'], 'OpenAI Terms of Use');
      expect(row['human_edits'], contains('128px RGBA normalization'));
      expect(row['status'], 'review');
      expect(row['reviewer'], 'Codex');
      expect(row['reviewed_at'], '2026-07-23');
      expect(row['notes'], contains('runtime owner=StageVisualSpec'));
      expect(row['notes'], contains('runtime status=temporary'));
      expect(
        row['notes'],
        contains('runtime-sha256=${_sha256(record.runtimePath)}'),
      );
      final decalSourcePath = record.decalSourcePath;
      if (decalSourcePath != null) {
        expect(row['notes'], contains('decal source=$decalSourcePath'));
        expect(row['notes'], contains('sha256=${_sha256(decalSourcePath)}'));
      }
    }
    for (final sourcePath in _sourcePaths) {
      final primaryRows = stageRows
          .where((row) => row['evidence_path'] == sourcePath)
          .toList(growable: false);
      final decalRows = stageRows
          .where((row) => row['notes']!.contains('decal source=$sourcePath'))
          .toList(growable: false);
      expect(
        primaryRows.length + decalRows.length,
        1,
        reason:
            'source must be attributed to exactly one stage runtime row: $sourcePath',
      );
    }
  });
}

class _StageLedgerExpectation {
  const _StageLedgerExpectation({
    required this.runtimePath,
    required this.primarySourcePath,
    this.decalSourcePath,
  });

  final String runtimePath;
  final String primarySourcePath;
  final String? decalSourcePath;
}

class _LedgerRow {
  _LedgerRow(this._fields);

  final Map<String, String> _fields;

  String? operator [](String column) => _fields[column];

  static List<_LedgerRow> readAll(String path) {
    final lines = const LineSplitter().convert(File(path).readAsStringSync());
    final columns = lines.first.split(',');
    return [
      for (final line in lines.skip(1))
        _LedgerRow(Map<String, String>.fromIterables(columns, line.split(','))),
    ];
  }
}

String _sha256(String path) => _Sha256.hash(File(path).readAsBytesSync());

abstract final class _Sha256 {
  static const _rounds = <int>[
    0x428a2f98,
    0x71374491,
    0xb5c0fbcf,
    0xe9b5dba5,
    0x3956c25b,
    0x59f111f1,
    0x923f82a4,
    0xab1c5ed5,
    0xd807aa98,
    0x12835b01,
    0x243185be,
    0x550c7dc3,
    0x72be5d74,
    0x80deb1fe,
    0x9bdc06a7,
    0xc19bf174,
    0xe49b69c1,
    0xefbe4786,
    0x0fc19dc6,
    0x240ca1cc,
    0x2de92c6f,
    0x4a7484aa,
    0x5cb0a9dc,
    0x76f988da,
    0x983e5152,
    0xa831c66d,
    0xb00327c8,
    0xbf597fc7,
    0xc6e00bf3,
    0xd5a79147,
    0x06ca6351,
    0x14292967,
    0x27b70a85,
    0x2e1b2138,
    0x4d2c6dfc,
    0x53380d13,
    0x650a7354,
    0x766a0abb,
    0x81c2c92e,
    0x92722c85,
    0xa2bfe8a1,
    0xa81a664b,
    0xc24b8b70,
    0xc76c51a3,
    0xd192e819,
    0xd6990624,
    0xf40e3585,
    0x106aa070,
    0x19a4c116,
    0x1e376c08,
    0x2748774c,
    0x34b0bcb5,
    0x391c0cb3,
    0x4ed8aa4a,
    0x5b9cca4f,
    0x682e6ff3,
    0x748f82ee,
    0x78a5636f,
    0x84c87814,
    0x8cc70208,
    0x90befffa,
    0xa4506ceb,
    0xbef9a3f7,
    0xc67178f2,
  ];

  static String hash(List<int> input) {
    final bytes = <int>[...input, 0x80];
    while ((bytes.length + 8) % 64 != 0) {
      bytes.add(0);
    }
    final bitLength = input.length * 8;
    for (var shift = 56; shift >= 0; shift -= 8) {
      bytes.add((bitLength >> shift) & 0xff);
    }
    var h0 = 0x6a09e667, h1 = 0xbb67ae85, h2 = 0x3c6ef372, h3 = 0xa54ff53a;
    var h4 = 0x510e527f, h5 = 0x9b05688c, h6 = 0x1f83d9ab, h7 = 0x5be0cd19;
    for (var offset = 0; offset < bytes.length; offset += 64) {
      final words = List<int>.filled(64, 0);
      for (var i = 0; i < 16; i++) {
        final start = offset + i * 4;
        words[i] =
            (bytes[start] << 24) |
            (bytes[start + 1] << 16) |
            (bytes[start + 2] << 8) |
            bytes[start + 3];
      }
      for (var i = 16; i < 64; i++) {
        final s0 =
            _rightRotate(words[i - 15], 7) ^
            _rightRotate(words[i - 15], 18) ^
            (words[i - 15] >> 3);
        final s1 =
            _rightRotate(words[i - 2], 17) ^
            _rightRotate(words[i - 2], 19) ^
            (words[i - 2] >> 10);
        words[i] = (words[i - 16] + s0 + words[i - 7] + s1) & 0xffffffff;
      }
      var a = h0, b = h1, c = h2, d = h3, e = h4, f = h5, g = h6, h = h7;
      for (var i = 0; i < 64; i++) {
        final s1 =
            _rightRotate(e, 6) ^ _rightRotate(e, 11) ^ _rightRotate(e, 25);
        final choose = (e & f) ^ (~e & g);
        final temp1 = (h + s1 + choose + _rounds[i] + words[i]) & 0xffffffff;
        final s0 =
            _rightRotate(a, 2) ^ _rightRotate(a, 13) ^ _rightRotate(a, 22);
        final majority = (a & b) ^ (a & c) ^ (b & c);
        final temp2 = (s0 + majority) & 0xffffffff;
        h = g;
        g = f;
        f = e;
        e = (d + temp1) & 0xffffffff;
        d = c;
        c = b;
        b = a;
        a = (temp1 + temp2) & 0xffffffff;
      }
      h0 = (h0 + a) & 0xffffffff;
      h1 = (h1 + b) & 0xffffffff;
      h2 = (h2 + c) & 0xffffffff;
      h3 = (h3 + d) & 0xffffffff;
      h4 = (h4 + e) & 0xffffffff;
      h5 = (h5 + f) & 0xffffffff;
      h6 = (h6 + g) & 0xffffffff;
      h7 = (h7 + h) & 0xffffffff;
    }
    return [h0, h1, h2, h3, h4, h5, h6, h7]
        .map((word) => word.toUnsigned(32).toRadixString(16).padLeft(8, '0'))
        .join()
        .toUpperCase();
  }

  static int _rightRotate(int value, int amount) =>
      ((value.toUnsigned(32) >> amount) | (value << (32 - amount))) &
      0xffffffff;
}

class _PngRgba {
  _PngRgba(this.width, this.height, this.colorType, this.pixels);

  final int width;
  final int height;
  final int colorType;
  final Uint8List pixels;

  factory _PngRgba.read(String path) {
    final bytes = File(path).readAsBytesSync();
    int u32(int offset) =>
        (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
    expect(bytes.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
    expect(utf8.decode(bytes.sublist(12, 16)), 'IHDR');
    final width = u32(16);
    final height = u32(20);
    final colorType = bytes[25];
    expect(bytes[24], 8, reason: '$path must use 8-bit channels');
    expect(colorType, 6, reason: '$path must use RGBA');
    final idat = BytesBuilder();
    for (var offset = 8; offset < bytes.length;) {
      final length = u32(offset);
      final type = utf8.decode(bytes.sublist(offset + 4, offset + 8));
      if (type == 'IDAT') {
        idat.add(bytes.sublist(offset + 8, offset + 8 + length));
      }
      offset += length + 12;
    }
    final raw = ZLibDecoder().convert(idat.toBytes());
    final stride = width * 4;
    final pixels = Uint8List(stride * height);
    var source = 0;
    for (var y = 0; y < height; y++) {
      final filter = raw[source++];
      for (var x = 0; x < stride; x++) {
        final value = raw[source++];
        final left = x < 4 ? 0 : pixels[y * stride + x - 4];
        final up = y == 0 ? 0 : pixels[(y - 1) * stride + x];
        final upLeft = y == 0 || x < 4 ? 0 : pixels[(y - 1) * stride + x - 4];
        pixels[y * stride + x] = switch (filter) {
          0 => value,
          1 => (value + left) & 0xff,
          2 => (value + up) & 0xff,
          3 => (value + ((left + up) >> 1)) & 0xff,
          4 => (value + _paeth(left, up, upLeft)) & 0xff,
          _ => throw StateError('unsupported PNG filter $filter'),
        };
      }
    }
    return _PngRgba(width, height, colorType, pixels);
  }

  bool get hasBrightGreenRemnant {
    for (var i = 0; i < pixels.length; i += 4) {
      final r = pixels[i];
      final g = pixels[i + 1];
      final b = pixels[i + 2];
      final a = pixels[i + 3];
      if (a > 0 && g >= 160 && g >= r * 1.5 && g >= b * 1.5) return true;
    }
    return false;
  }

  _PngCell cell(int index) => _PngCell(this, index % 4 * 128, index ~/ 4 * 128);
}

class _PngCell {
  const _PngCell(this.png, this.left, this.top);

  final _PngRgba png;
  final int left;
  final int top;

  Iterable<int> get _alphas sync* {
    for (var y = top; y < top + 128; y++) {
      for (var x = left; x < left + 128; x++) {
        yield png.pixels[(y * png.width + x) * 4 + 3];
      }
    }
  }

  bool get isFullyOpaque => _alphas.every((alpha) => alpha == 255);
  bool get hasTransparentBackground => _alphas.any((alpha) => alpha == 0);
  bool get hasVisibleContent => _alphas.any((alpha) => alpha > 0);

  bool hasAtLeastPadding(int amount) {
    for (var y = 0; y < 128; y++) {
      for (var x = 0; x < 128; x++) {
        if (x >= amount &&
            x < 128 - amount &&
            y >= amount &&
            y < 128 - amount) {
          continue;
        }
        if (png.pixels[((top + y) * png.width + left + x) * 4 + 3] != 0) {
          return false;
        }
      }
    }
    return true;
  }
}

int _paeth(int left, int up, int upLeft) {
  final estimate = left + up - upLeft;
  final leftDistance = (estimate - left).abs();
  final upDistance = (estimate - up).abs();
  final upLeftDistance = (estimate - upLeft).abs();
  if (leftDistance <= upDistance && leftDistance <= upLeftDistance) return left;
  return upDistance <= upLeftDistance ? up : upLeft;
}
