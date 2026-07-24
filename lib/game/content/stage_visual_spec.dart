import 'dart:collection';
import 'dart:math';
import 'dart:ui';

import 'stage_definitions.dart';
import '../world/world_chunk_coordinate.dart';

/// One low-contrast base-tile source and its deterministic presentation turn.
class StageBaseTileVisual {
  const StageBaseTileVisual({required this.sourceCell, this.quarterTurns = 0})
    : assert(sourceCell >= 0 && sourceCell < 4),
      assert(quarterTurns >= 0 && quarterTurns < 4);

  final int sourceCell;
  final int quarterTurns;
}

/// Static art choices for one stage. The salt is a permanent, explicit part of
/// the stage contract so layouts never depend on a runtime string hash.
class StageVisualSpec {
  const StageVisualSpec({
    required this.stageId,
    required this.seedSalt,
    required this.tileAssetKey,
    this.decalAssetKey,
    this.propAssetKey,
    this.tileVariants = 4,
    this.baseTileVisuals = const <StageBaseTileVisual>[
      StageBaseTileVisual(sourceCell: 0),
      StageBaseTileVisual(sourceCell: 1),
      StageBaseTileVisual(sourceCell: 2),
      StageBaseTileVisual(sourceCell: 3),
    ],
    this.decalVariants = 4,
    this.propVariants = 8,
    this.atlasColumns = 4,
    this.tileSize = 128,
    this.edgeBand = 128,
  }) : assert(tileVariants >= 2 && tileVariants <= 4),
       assert(decalVariants >= 1 && decalVariants <= 4),
       assert(propVariants >= 1 && propVariants <= 8),
       assert(atlasColumns == 4),
       assert(tileSize > 0),
       assert(edgeBand >= 0);

  final String stageId;
  final int seedSalt;
  final String tileAssetKey;
  final String? decalAssetKey;
  final String? propAssetKey;
  final int tileVariants;
  final List<StageBaseTileVisual> baseTileVisuals;
  final int decalVariants;
  final int propVariants;
  final int atlasColumns;
  final double tileSize;
  final double edgeBand;

  StageBaseTileVisual baseTileVisualFor(int variant) =>
      baseTileVisuals[variant % baseTileVisuals.length];
}

const stageVisualSpecs = <String, StageVisualSpec>{
  moonlitAbandonedOffice: StageVisualSpec(
    stageId: moonlitAbandonedOffice,
    seedSalt: 0x4D4F4F4E,
    tileAssetKey: 'tiles/moonlit_office_tiles_128.png',
    decalAssetKey: 'tiles/moonlit_office_tiles_128.png',
    propAssetKey: 'props/moonlit_office_props_128.png',
    tileVariants: 4,
    baseTileVisuals: <StageBaseTileVisual>[
      StageBaseTileVisual(sourceCell: 2),
      StageBaseTileVisual(sourceCell: 3),
      StageBaseTileVisual(sourceCell: 2, quarterTurns: 1),
      StageBaseTileVisual(sourceCell: 3, quarterTurns: 3),
    ],
    decalVariants: 4,
    propVariants: 8,
  ),
  plagueMarket: StageVisualSpec(
    stageId: plagueMarket,
    seedSalt: 0x504C4147,
    tileAssetKey: 'tiles/plague_market_tiles_128.png',
    decalAssetKey: 'tiles/plague_market_tiles_128.png',
    propAssetKey: 'props/plague_market_props_128.png',
    tileVariants: 4,
    decalVariants: 4,
    propVariants: 8,
  ),
};

StageVisualSpec stageVisualSpecFor(String stageId) =>
    stageVisualSpecs[stageId] ?? stageVisualSpecs[moonlitAbandonedOffice]!;

class StageTilePlacement {
  const StageTilePlacement({
    required this.position,
    required this.size,
    required this.variant,
  });

  final Offset position;
  final double size;
  final int variant;

  Rect get bounds => Rect.fromLTWH(position.dx, position.dy, size, size);

  @override
  bool operator ==(Object other) =>
      other is StageTilePlacement &&
      other.position == position &&
      other.size == size &&
      other.variant == variant;

  @override
  int get hashCode => Object.hash(position, size, variant);
}

enum StageDecorationKind { decal, prop }

class StageDecorationPlacement {
  const StageDecorationPlacement({
    required this.kind,
    required this.position,
    required this.size,
    required this.variant,
  });

  final StageDecorationKind kind;
  final Offset position;
  final double size;
  final int variant;

  Rect get bounds => Rect.fromLTWH(position.dx, position.dy, size, size);

  @override
  bool operator ==(Object other) =>
      other is StageDecorationPlacement &&
      other.kind == kind &&
      other.position == position &&
      other.size == size &&
      other.variant == variant;

  @override
  int get hashCode => Object.hash(kind, position, size, variant);
}

/// A deterministic, presentation-only arrangement of the static stage art.
class StageLayout {
  StageLayout._({
    required this.spec,
    required this.bounds,
    this.coordinate,
    required List<StageTilePlacement> tiles,
    required List<StageDecorationPlacement> decorations,
    required List<StageDecorationPlacement> props,
  }) : tiles = UnmodifiableListView(tiles),
       decorations = UnmodifiableListView(decorations),
       props = UnmodifiableListView(props);

  final StageVisualSpec spec;
  final Rect bounds;
  final WorldChunkCoordinate? coordinate;
  final UnmodifiableListView<StageTilePlacement> tiles;
  final UnmodifiableListView<StageDecorationPlacement> decorations;
  final UnmodifiableListView<StageDecorationPlacement> props;

  static StageLayout build(
    StageVisualSpec spec, {
    required int seed,
    required Rect bounds,
  }) {
    final random = Random(seed ^ spec.seedSalt);
    final tiles = <StageTilePlacement>[];
    final decals = <StageDecorationPlacement>[];
    final props = <StageDecorationPlacement>[];
    final size = spec.tileSize;
    final left = (bounds.left / size).floor() * size;
    final top = (bounds.top / size).floor() * size;

    for (var y = top; y < bounds.bottom; y += size) {
      for (var x = left; x < bounds.right; x += size) {
        final position = _pixelOffset(x, y);
        tiles.add(
          StageTilePlacement(
            position: position,
            size: size,
            variant: _baseVariantFor(
              seed: seed,
              salt: spec.seedSalt,
              cellX: (x / size).round(),
              cellY: (y / size).round(),
              variantCount: spec.tileVariants,
            ),
          ),
        );
        if (spec.decalAssetKey != null &&
            _shouldPlaceDecal(
              choice: _chunkMix(
                seed,
                spec.seedSalt,
                (x / size).round(),
                (y / size).round(),
              ),
              position: position,
              tileSize: size,
              worldBounds: bounds,
              edgeBand: spec.edgeBand,
              landmarkPositions: const <Offset>[],
            )) {
          decals.add(
            StageDecorationPlacement(
              kind: StageDecorationKind.decal,
              position: position,
              size: size,
              variant: random.nextInt(spec.decalVariants),
            ),
          );
        }
      }
    }

    if (spec.decalAssetKey != null && decals.isEmpty && tiles.isNotEmpty) {
      final tile = tiles[random.nextInt(tiles.length)];
      decals.add(
        StageDecorationPlacement(
          kind: StageDecorationKind.decal,
          position: tile.position,
          size: size,
          variant: random.nextInt(spec.decalVariants),
        ),
      );
    }

    if (spec.propAssetKey != null && tiles.isNotEmpty) {
      final edgeTiles = tiles
          .where((tile) {
            final center = tile.position + Offset(size / 2, size / 2);
            return center.dx <= bounds.left + spec.edgeBand ||
                center.dx >= bounds.right - spec.edgeBand ||
                center.dy <= bounds.top + spec.edgeBand ||
                center.dy >= bounds.bottom - spec.edgeBand;
          })
          .toList(growable: false);
      if (edgeTiles.isNotEmpty) {
        final tile = edgeTiles[random.nextInt(edgeTiles.length)];
        props.add(
          StageDecorationPlacement(
            kind: StageDecorationKind.prop,
            position: tile.position,
            size: size,
            variant: random.nextInt(spec.propVariants),
          ),
        );
      }
    }

    return StageLayout._(
      spec: spec,
      bounds: bounds,
      tiles: tiles,
      decorations: decals,
      props: props,
    );
  }

  /// Builds the static art for exactly one world-aligned chunk.  The random
  /// choices use explicit integer mixing so they remain stable across runs.
  static StageLayout buildChunk(
    StageVisualSpec spec, {
    required int seed,
    required WorldChunkCoordinate coordinate,
    required double chunkSize,
    required Rect worldBounds,
    List<Offset> landmarkPositions = const <Offset>[],
  }) {
    if (!chunkSize.isFinite || chunkSize <= 0) {
      throw ArgumentError.value(
        chunkSize,
        'chunkSize',
        'must be finite and positive',
      );
    }
    final requested = Rect.fromLTWH(
      coordinate.x * chunkSize,
      coordinate.y * chunkSize,
      chunkSize,
      chunkSize,
    );
    final bounds = requested.intersect(worldBounds);
    final tiles = <StageTilePlacement>[];
    final decals = <StageDecorationPlacement>[];
    final props = <StageDecorationPlacement>[];
    if (bounds.isEmpty) {
      return StageLayout._(
        spec: spec,
        bounds: bounds,
        coordinate: coordinate,
        tiles: tiles,
        decorations: decals,
        props: props,
      );
    }
    final tileSize = spec.tileSize;
    final left = (bounds.left / tileSize).ceil() * tileSize;
    final top = (bounds.top / tileSize).ceil() * tileSize;
    final isBoundary =
        requested.left <= worldBounds.left ||
        requested.top <= worldBounds.top ||
        requested.right >= worldBounds.right ||
        requested.bottom >= worldBounds.bottom;
    for (var y = top; y + tileSize <= bounds.bottom; y += tileSize) {
      for (var x = left; x + tileSize <= bounds.right; x += tileSize) {
        final cellX = (x / tileSize).round();
        final cellY = (y / tileSize).round();
        final choice = _chunkMix(seed, spec.seedSalt, cellX, cellY);
        final tileVariant = _baseVariantFor(
          seed: seed,
          salt: spec.seedSalt,
          cellX: cellX,
          cellY: cellY,
          variantCount: spec.tileVariants,
        );
        final position = _pixelOffset(x, y);
        tiles.add(
          StageTilePlacement(
            position: position,
            size: tileSize,
            variant: tileVariant,
          ),
        );
        if (spec.decalAssetKey != null &&
            _shouldPlaceDecal(
              choice: choice,
              position: position,
              tileSize: tileSize,
              worldBounds: worldBounds,
              edgeBand: spec.edgeBand,
              landmarkPositions: landmarkPositions,
            )) {
          decals.add(
            StageDecorationPlacement(
              kind: StageDecorationKind.decal,
              position: position,
              size: tileSize,
              variant: (choice ~/ 7) % spec.decalVariants,
            ),
          );
        }
        if (spec.propAssetKey != null &&
            isBoundary &&
            _isBoundaryCell(position, tileSize, requested, worldBounds) &&
            choice % 2 == 0) {
          props.add(
            StageDecorationPlacement(
              kind: StageDecorationKind.prop,
              position: position,
              size: tileSize,
              variant: (choice ~/ 11) % spec.propVariants,
            ),
          );
        }
      }
    }
    if (spec.propAssetKey != null && isBoundary && props.isEmpty) {
      final edgeTiles = tiles.where(
        (tile) =>
            _isBoundaryCell(tile.position, tile.size, requested, worldBounds),
      );
      if (edgeTiles.isNotEmpty) {
        final tile = edgeTiles.first;
        props.add(
          StageDecorationPlacement(
            kind: StageDecorationKind.prop,
            position: tile.position,
            size: tile.size,
            variant:
                _chunkMix(seed, spec.seedSalt, coordinate.x, coordinate.y) %
                spec.propVariants,
          ),
        );
      }
    }
    return StageLayout._(
      spec: spec,
      bounds: bounds,
      coordinate: coordinate,
      tiles: tiles,
      decorations: decals,
      props: props,
    );
  }
}

Offset _pixelOffset(double x, double y) =>
    Offset(x.roundToDouble(), y.roundToDouble());

int _baseVariantFor({
  required int seed,
  required int salt,
  required int cellX,
  required int cellY,
  required int variantCount,
}) {
  var mixed =
      (seed ^ salt ^ (cellX * 0x1f123bb5) ^ (cellY * 0x5f356495)) & 0xffffffff;
  mixed ^= mixed >> 16;
  mixed = (mixed * 0x7feb352d) & 0xffffffff;
  mixed ^= mixed >> 15;
  mixed = (mixed * 0x846ca68b) & 0xffffffff;
  mixed ^= mixed >> 16;
  return (mixed & 0x7fffffff) % variantCount;
}

bool _shouldPlaceDecal({
  required int choice,
  required Offset position,
  required double tileSize,
  required Rect worldBounds,
  required double edgeBand,
  required List<Offset> landmarkPositions,
}) {
  final center = position + Offset(tileSize / 2, tileSize / 2);
  final isEdge =
      center.dx <= worldBounds.left + edgeBand ||
      center.dx >= worldBounds.right - edgeBand ||
      center.dy <= worldBounds.top + edgeBand ||
      center.dy >= worldBounds.bottom - edgeBand;
  // A small world-space band around authored landmarks adds local detail
  // without classifying arbitrary chunk borders as stage edges.
  final isNearLandmark = landmarkPositions.any(
    (landmark) => (center - landmark).distance <= tileSize * .75,
  );
  if (isNearLandmark) return true;
  if (isEdge) return choice % 5 == 0;
  return choice % 64 == 0;
}

bool _isBoundaryCell(Offset position, double size, Rect chunk, Rect world) {
  final center = position + Offset(size / 2, size / 2);
  return (chunk.left <= world.left && center.dx <= chunk.left + size) ||
      (chunk.top <= world.top && center.dy <= chunk.top + size) ||
      (chunk.right >= world.right && center.dx >= chunk.right - size) ||
      (chunk.bottom >= world.bottom && center.dy >= chunk.bottom - size);
}

int _chunkMix(int seed, int salt, int x, int y) {
  var value = (seed ^ salt ^ 0x9e3779b9) & 0xffffffff;
  for (final part in [x, y, 0x43484b34]) {
    value = (value ^ part) & 0xffffffff;
    value = (value * 0x85ebca6b) & 0xffffffff;
    value ^= value >> 16;
  }
  return value & 0x7fffffff;
}
