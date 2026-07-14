import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/art_style_guide.dart';
import 'package:pixel_survivor/game/content/asset_catalog.dart';

void main() {
  test('palette colors are unique opaque ARGB values', () {
    expect(JoseonArtStyle.palette, hasLength(11));
    expect(JoseonArtStyle.palette.values.toSet(), hasLength(11));
    expect(
      JoseonArtStyle.palette.values.every((color) => color >> 24 == 0xff),
      isTrue,
    );
  });

  test('native sprite sizes and integer display scales are fixed', () {
    expect(JoseonArtStyle.pickupSize, 16);
    expect(JoseonArtStyle.swarmSize, 24);
    expect(JoseonArtStyle.standardSize, 32);
    expect(JoseonArtStyle.bossSize, 64);
    expect(JoseonArtStyle.integerScales, [1, 2, 3, 4]);
  });

  test('every catalog asset uses an approved native-size suffix', () {
    final paths = <String>[
      ...AssetCatalog.characters.values,
      ...AssetCatalog.monsters.values,
      ...AssetCatalog.weapons.values,
      ...AssetCatalog.augments.values,
      ...AssetCatalog.effects.values,
      ...AssetCatalog.stages.values,
      ...AssetCatalog.player.values,
    ];

    expect(paths, isNotEmpty);
    expect(paths.every(JoseonArtStyle.hasApprovedSizeSuffix), isTrue);
  });

  test('silhouette rules keep gameplay classes distinct', () {
    expect(JoseonArtStyle.silhouettes.keys.toSet(), {
      'player',
      'swarm',
      'chaser',
      'tank',
      'spirit',
      'boss',
    });
    for (final rule in JoseonArtStyle.silhouettes.values) {
      expect(rule.occupancyMin, greaterThanOrEqualTo(0.45));
      expect(rule.occupancyMax, lessThanOrEqualTo(0.9));
      expect(rule.readabilityCue, isNotEmpty);
    }
  });

  test('player animation sheet is a 4x4 RGBA grid of 32px frames', () {
    final bytes = File(
      'assets/images/player/rookie_constable_player_32.png',
    ).readAsBytesSync();
    int readUint32(int offset) =>
        (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];

    expect(readUint32(16), 128);
    expect(readUint32(20), 128);
    expect(bytes[25], 6, reason: 'PNG must use RGBA color type');
  });

  test('normal enemy sheets are 4x4 RGBA grids at approved frame sizes', () {
    final expectedCells = <String, int>{
      'assets/images/monsters/plague_rat_swarm_24.png': 24,
      'assets/images/monsters/bandit_32.png': 32,
      'assets/images/monsters/dokkaebi_32.png': 32,
      'assets/images/monsters/vengeful_spirit_32.png': 32,
    };

    for (final entry in expectedCells.entries) {
      final bytes = File(entry.key).readAsBytesSync();
      int readUint32(int offset) =>
          (bytes[offset] << 24) |
          (bytes[offset + 1] << 16) |
          (bytes[offset + 2] << 8) |
          bytes[offset + 3];

      expect(readUint32(16), entry.value * 4, reason: entry.key);
      expect(readUint32(20), entry.value * 4, reason: entry.key);
      expect(bytes[25], 6, reason: '${entry.key} must use RGBA color type');
    }
  });

  test('boss sheet is a 4x4 RGBA grid of 64px frames', () {
    final bytes = File(
      'assets/images/monsters/fallen_general_64.png',
    ).readAsBytesSync();
    int readUint32(int offset) =>
        (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];

    expect(readUint32(16), 256);
    expect(readUint32(20), 256);
    expect(bytes[25], 6, reason: 'boss PNG must use RGBA color type');
  });
}
