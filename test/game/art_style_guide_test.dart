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
}
