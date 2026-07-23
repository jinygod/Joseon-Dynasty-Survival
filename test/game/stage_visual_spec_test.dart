import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';
import 'package:pixel_survivor/game/content/stage_visual_spec.dart';

void main() {
  const bounds = Rect.fromLTWH(-64, -64, 384, 256);
  const spec = StageVisualSpec(
    stageId: 'test_stage',
    seedSalt: 0x531A6E,
    tileAssetKey: 'tiles.png',
    decalAssetKey: 'decals.png',
    propAssetKey: 'props.png',
  );

  test('same stage and seed produce identical placements', () {
    final a = StageLayout.build(spec, seed: 3107, bounds: bounds);
    final b = StageLayout.build(spec, seed: 3107, bounds: bounds);

    expect(a.tiles, b.tiles);
    expect(a.decorations, b.decorations);
  });

  test('different seeds vary optional placements while retaining coverage', () {
    final a = StageLayout.build(spec, seed: 3107, bounds: bounds);
    final b = StageLayout.build(spec, seed: 3108, bounds: bounds);

    expect(a.tiles, isNot(b.tiles));
    expect(a.tiles, hasLength(12));
    expect(b.tiles, hasLength(12));
    expect(a.decorations, isNot(b.decorations));
  });

  test('tile grid covers the full bounds with every expected cell', () {
    final layout = StageLayout.build(spec, seed: 3107, bounds: bounds);

    final expectedPositions = <Offset>{
      for (final x in [-128.0, 0.0, 128.0, 256.0])
        for (final y in [-128.0, 0.0, 128.0]) Offset(x, y),
    };

    expect(layout.tiles, hasLength(expectedPositions.length));
    expect(
      layout.tiles.map((tile) => tile.position).toSet(),
      expectedPositions,
    );
    expect(
      layout.tiles
          .singleWhere((tile) => tile.position == Offset.zero)
          .bounds
          .contains(const Offset(64, 64)),
      isTrue,
    );
  });

  test(
    'sparse decals and props occupy deterministic non-vacuous placements',
    () {
      final layout = StageLayout.build(spec, seed: 3107, bounds: bounds);

      expect(layout.decorations, isNotEmpty);
      expect(layout.decorations.length, lessThan(layout.tiles.length));
      expect(layout.props, isNotEmpty);
      for (final prop in layout.props) {
        expect(
          prop.position.dx <= bounds.left + spec.edgeBand ||
              prop.position.dx >= bounds.right - spec.edgeBand ||
              prop.position.dy <= bounds.top + spec.edgeBand ||
              prop.position.dy >= bounds.bottom - spec.edgeBand,
          isTrue,
        );
      }
    },
  );

  test('current stages resolve their permanent visual specifications', () {
    final moonlit = stageVisualSpecFor(moonlitAbandonedOffice);
    final plague = stageVisualSpecFor(plagueMarket);

    expect(moonlit.stageId, moonlitAbandonedOffice);
    expect(plague.stageId, plagueMarket);
    expect(moonlit.seedSalt, isNot(plague.seedSalt));
    expect(moonlit.tileVariants, inInclusiveRange(2, 4));
    expect(plague.tileVariants, inInclusiveRange(2, 4));
    expect(moonlit.tileAssetKey, 'stages/moonlit_office_tiles_128.png');
    expect(moonlit.propAssetKey, 'stages/moonlit_office_props_128.png');
    expect(plague.tileAssetKey, 'stages/plague_market_tiles_128.png');
    expect(plague.propAssetKey, 'stages/plague_market_props_128.png');
  });

  test('placement collections are unmodifiable', () {
    final layout = StageLayout.build(spec, seed: 3107, bounds: bounds);

    expect(() => layout.tiles.add(layout.tiles.first), throwsUnsupportedError);
    expect(
      () => layout.decorations.add(layout.decorations.first),
      throwsUnsupportedError,
    );
    expect(() => layout.props.add(layout.props.first), throwsUnsupportedError);
  });
}
