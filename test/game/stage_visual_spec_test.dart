import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';
import 'package:pixel_survivor/game/content/stage_visual_spec.dart';
import 'package:pixel_survivor/game/world/world_chunk_coordinate.dart';

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

  test('same seed and coordinate produce identical chunk placements', () {
    const worldBounds = Rect.fromLTWH(0, 0, 2048, 5120);
    final first = StageLayout.buildChunk(
      spec,
      seed: 3107,
      coordinate: const WorldChunkCoordinate(2, 5),
      chunkSize: 512,
      worldBounds: worldBounds,
    );
    final second = StageLayout.buildChunk(
      spec,
      seed: 3107,
      coordinate: const WorldChunkCoordinate(2, 5),
      chunkSize: 512,
      worldBounds: worldBounds,
    );

    expect(first.tiles, second.tiles);
    expect(first.props, second.props);
    expect(first.tiles, hasLength(16));
    expect(first.bounds, const Rect.fromLTWH(1024, 2560, 512, 512));
  });

  test('boundary chunks have more props than center chunks', () {
    const worldBounds = Rect.fromLTWH(0, 0, 2048, 5120);
    final edge = StageLayout.buildChunk(
      spec,
      seed: 3107,
      coordinate: const WorldChunkCoordinate(0, 5),
      chunkSize: 512,
      worldBounds: worldBounds,
    );
    final center = StageLayout.buildChunk(
      spec,
      seed: 3107,
      coordinate: const WorldChunkCoordinate(2, 5),
      chunkSize: 512,
      worldBounds: worldBounds,
    );

    expect(edge.props.length, greaterThan(center.props.length));
    for (final placement in edge.tiles) {
      expect(
        edge.bounds.contains(placement.position + const Offset(1, 1)),
        isTrue,
      );
      expect(worldBounds.overlaps(placement.bounds), isTrue);
    }
    for (final placement in edge.props) {
      expect(
        edge.bounds.contains(placement.position + const Offset(1, 1)),
        isTrue,
      );
      expect(worldBounds.overlaps(placement.bounds), isTrue);
    }
  });

  test('center keeps sparse decals and base variants are reproducible', () {
    const worldBounds = Rect.fromLTWH(0, 0, 2048, 5120);
    final first = StageLayout.buildChunk(
      spec,
      seed: 104729,
      coordinate: const WorldChunkCoordinate(1, 2),
      chunkSize: 1024,
      worldBounds: worldBounds,
    );
    final second = StageLayout.buildChunk(
      spec,
      seed: 104729,
      coordinate: const WorldChunkCoordinate(1, 2),
      chunkSize: 1024,
      worldBounds: worldBounds,
    );
    final center = first.tiles.where((tile) {
      final tileCenter = tile.position + const Offset(64, 64);
      return tileCenter.dx > first.bounds.left + spec.edgeBand &&
          tileCenter.dx < first.bounds.right - spec.edgeBand &&
          tileCenter.dy > first.bounds.top + spec.edgeBand &&
          tileCenter.dy < first.bounds.bottom - spec.edgeBand;
    });
    final centerPositions = center.map((tile) => tile.position).toSet();
    final centerDecals = first.decorations.where(
      (decal) => centerPositions.contains(decal.position),
    );

    expect(first, isNot(same(second)));
    expect(first.tiles, second.tiles);
    expect(first.decorations, second.decorations);
    expect(centerDecals.length / center.length, lessThan(.08));
    expect(first.tiles.map((tile) => tile.variant).toSet(), hasLength(4));
  });

  test('chunk base variants avoid a repeating checkerboard', () {
    const worldBounds = Rect.fromLTWH(0, 0, 2048, 5120);
    final layout = StageLayout.buildChunk(
      spec,
      seed: 104729,
      coordinate: const WorldChunkCoordinate(1, 2),
      chunkSize: 1024,
      worldBounds: worldBounds,
    );
    final variants = {
      for (final tile in layout.tiles) tile.position: tile.variant,
    };

    final firstFour = [
      for (var x = 1024.0; x < 1536.0; x += 128) variants[Offset(x, 2048)],
    ];
    final nextFour = [
      for (var x = 1536.0; x < 2048.0; x += 128) variants[Offset(x, 2048)],
    ];

    expect(firstFour, isNot(nextFour));
  });

  test('chunk building rejects non-positive or non-finite chunk sizes', () {
    const worldBounds = Rect.fromLTWH(0, 0, 2048, 5120);

    expect(
      () => StageLayout.buildChunk(
        spec,
        seed: 3107,
        coordinate: const WorldChunkCoordinate(0, 0),
        chunkSize: 0,
        worldBounds: worldBounds,
      ),
      throwsArgumentError,
    );
    expect(
      () => StageLayout.buildChunk(
        spec,
        seed: 3107,
        coordinate: const WorldChunkCoordinate(0, 0),
        chunkSize: double.infinity,
        worldBounds: worldBounds,
      ),
      throwsArgumentError,
    );
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
    expect(moonlit.tileAssetKey, 'tiles/moonlit_office_tiles_128.png');
    expect(moonlit.propAssetKey, 'props/moonlit_office_props_128.png');
    expect(plague.tileAssetKey, 'tiles/plague_market_tiles_128.png');
    expect(plague.propAssetKey, 'props/plague_market_props_128.png');
    expect(moonlit.tileVariants, 4);
    expect(moonlit.decalVariants, 4);
    expect(moonlit.propVariants, 8);
    expect(plague.tileVariants, 4);
    expect(plague.decalVariants, 4);
    expect(plague.propVariants, 8);
  });

  test(
    'authored decoration variant ranges are reachable across fixed seeds',
    () {
      final spec = stageVisualSpecFor(moonlitAbandonedOffice);
      final decals = <int>{};
      final props = <int>{};
      for (var seed = 0; seed < 512; seed++) {
        final layout = StageLayout.build(spec, seed: seed, bounds: bounds);
        decals.addAll(layout.decorations.map((placement) => placement.variant));
        props.addAll(layout.props.map((placement) => placement.variant));
      }
      expect(decals, {0, 1, 2, 3});
      expect(props, {0, 1, 2, 3, 4, 5, 6, 7});
    },
  );

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
