import 'dart:collection';
import 'dart:math';
import 'dart:ui';

import 'stage_definitions.dart';

/// Static art choices for one stage. The salt is a permanent, explicit part of
/// the stage contract so layouts never depend on a runtime string hash.
class StageVisualSpec {
  const StageVisualSpec({
    required this.stageId,
    required this.seedSalt,
    required this.tileAssetKey,
    this.decalAssetKey,
    this.propAssetKey,
    this.tileVariants = 2,
    this.tileSize = 128,
    this.edgeBand = 128,
  }) : assert(tileVariants >= 2 && tileVariants <= 4),
       assert(tileSize > 0),
       assert(edgeBand >= 0);

  final String stageId;
  final int seedSalt;
  final String tileAssetKey;
  final String? decalAssetKey;
  final String? propAssetKey;
  final int tileVariants;
  final double tileSize;
  final double edgeBand;
}

const stageVisualSpecs = <String, StageVisualSpec>{
  moonlitAbandonedOffice: StageVisualSpec(
    stageId: moonlitAbandonedOffice,
    seedSalt: 0x4D4F4F4E,
    tileAssetKey: 'stages/moonlit_office_tiles_128.png',
    decalAssetKey: 'stages/moonlit_office_tiles_128.png',
    propAssetKey: 'stages/moonlit_office_props_128.png',
  ),
  plagueMarket: StageVisualSpec(
    stageId: plagueMarket,
    seedSalt: 0x504C4147,
    tileAssetKey: 'stages/plague_market_tiles_128.png',
    decalAssetKey: 'stages/plague_market_tiles_128.png',
    propAssetKey: 'stages/plague_market_props_128.png',
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
    required List<StageTilePlacement> tiles,
    required List<StageDecorationPlacement> decorations,
    required List<StageDecorationPlacement> props,
  }) : tiles = UnmodifiableListView(tiles),
       decorations = UnmodifiableListView(decorations),
       props = UnmodifiableListView(props);

  final StageVisualSpec spec;
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
        final position = Offset(x, y);
        tiles.add(
          StageTilePlacement(
            position: position,
            size: size,
            variant: random.nextInt(spec.tileVariants),
          ),
        );
        if (spec.decalAssetKey != null && random.nextDouble() < .18) {
          decals.add(
            StageDecorationPlacement(
              kind: StageDecorationKind.decal,
              position: position,
              size: size,
              variant: random.nextInt(spec.tileVariants),
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
          variant: random.nextInt(spec.tileVariants),
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
            variant: random.nextInt(spec.tileVariants),
          ),
        );
      }
    }

    return StageLayout._(
      spec: spec,
      tiles: tiles,
      decorations: decals,
      props: props,
    );
  }
}
