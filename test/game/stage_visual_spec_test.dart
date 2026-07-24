import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/stage_backdrop_component.dart';
import 'package:pixel_survivor/game/components/stage_tile_batch_component.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';
import 'package:pixel_survivor/game/content/stage_visual_spec.dart';
import 'package:pixel_survivor/game/world/finite_world_layout.dart';
import 'package:pixel_survivor/game/world/world_chunk_coordinate.dart';
import 'package:pixel_survivor/game/world/world_runtime_config.dart';

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
    final world = FiniteWorldLayout.generate(
      stageId: plagueMarket,
      seed: 3107,
      config: WorldRuntimeConfig.standard,
    );
    final landmarkPositions = world.landmarkAnchors
        .map((anchor) => anchor.position)
        .toList(growable: false);
    final first = StageLayout.buildChunk(
      spec,
      seed: 3107,
      coordinate: const WorldChunkCoordinate(1, 1),
      chunkSize: 512,
      worldBounds: world.worldBounds,
      landmarkPositions: landmarkPositions,
    );
    final second = StageLayout.buildChunk(
      spec,
      seed: 3107,
      coordinate: const WorldChunkCoordinate(1, 1),
      chunkSize: 512,
      worldBounds: world.worldBounds,
      landmarkPositions: landmarkPositions,
    );
    final interiorLayouts = [
      for (var y = 1; y < WorldRuntimeConfig.standard.chunkRows - 1; y += 1)
        for (
          var x = 1;
          x < WorldRuntimeConfig.standard.chunkColumns - 1;
          x += 1
        )
          StageLayout.buildChunk(
            spec,
            seed: 3107,
            coordinate: WorldChunkCoordinate(x, y),
            chunkSize: 512,
            worldBounds: world.worldBounds,
            landmarkPositions: landmarkPositions,
          ),
    ];
    final interiorTileCount = interiorLayouts.fold<int>(
      0,
      (count, layout) => count + layout.tiles.length,
    );
    final interiorDecalCount = interiorLayouts.fold<int>(
      0,
      (count, layout) => count + layout.decorations.length,
    );

    expect(first, isNot(same(second)));
    expect(first.tiles, second.tiles);
    expect(first.decorations, second.decorations);
    expect(interiorDecalCount / interiorTileCount, lessThan(.08));
    expect(first.tiles.map((tile) => tile.variant).toSet(), hasLength(4));
  });

  test(
    'interior chunk borders are not edge-biased and landmarks add decals',
    () {
      final world = FiniteWorldLayout.generate(
        stageId: plagueMarket,
        seed: 3107,
        config: WorldRuntimeConfig.standard,
      );
      final landmark = world.landmarkAnchors.first;
      final withLandmark = StageLayout.buildChunk(
        spec,
        seed: 3107,
        coordinate: landmark.coordinate,
        chunkSize: 512,
        worldBounds: world.worldBounds,
        landmarkPositions: [landmark.position],
      );
      final ordinary = StageLayout.buildChunk(
        spec,
        seed: 3107,
        coordinate: landmark.coordinate,
        chunkSize: 512,
        worldBounds: world.worldBounds,
      );

      expect(
        ordinary.decorations.length / ordinary.tiles.length,
        lessThan(.08),
      );
      expect(
        withLandmark.decorations.length,
        greaterThan(ordinary.decorations.length),
      );
      expect(
        withLandmark.decorations.any(
          (decal) =>
              (decal.position + const Offset(64, 64) - landmark.position)
                  .distance <=
              96,
        ),
        isTrue,
      );
    },
  );

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

    final row = [
      for (var x = 1024.0; x < 2048.0; x += 128) variants[Offset(x, 2048)],
    ];

    expect(row.take(4), isNot(row.skip(4).take(4)));
    expect(row[0], isNot(row[2]));
    expect(row[1], isNot(row[3]));
  });

  test('adjacent chunks keep integer, contiguous edges at .90 projection', () {
    const worldBounds = Rect.fromLTWH(0, 0, 2048, 5120);
    final left = StageLayout.buildChunk(
      spec,
      seed: 3107,
      coordinate: const WorldChunkCoordinate(1, 1),
      chunkSize: 512,
      worldBounds: worldBounds,
    );
    final right = StageLayout.buildChunk(
      spec,
      seed: 3107,
      coordinate: const WorldChunkCoordinate(2, 1),
      chunkSize: 512,
      worldBounds: worldBounds,
    );
    final leftEdge = left.tiles.map((tile) => tile.bounds.right).reduce(max);
    final rightEdge = right.tiles.map((tile) => tile.bounds.left).reduce(min);

    expect(
      left.tiles.every((tile) => tile.position.dx == tile.position.dx.round()),
      isTrue,
    );
    expect(
      right.tiles.every((tile) => tile.position.dy == tile.position.dy.round()),
      isTrue,
    );
    expect(leftEdge, rightEdge);
    expect(leftEdge * .90, rightEdge * .90);

    final source = StageTileBatchComponent.sourceRectFor(
      kind: StageAtlasKind.tile,
      variant: 3,
      cellSize: 127.6,
    );
    final crop = StageBackdropComponent(
      viewportSize: Vector2(390, 844),
    ).groundImageSourceRectFor(const Size(1024, 1824));
    expect(source.left, source.left.roundToDouble());
    expect(source.width, source.width.roundToDouble());
    expect(crop.left, crop.left.roundToDouble());
    expect(crop.right, crop.right.roundToDouble());
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
