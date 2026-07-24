import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import '../content/stage_visual_spec.dart';
import '../world/world_chunk_coordinate.dart';

/// Presentation-only static stage renderer. All batch contents are assembled
/// once while loading and are never changed during a run.
class StageTileBatchComponent extends Component {
  StageTileBatchComponent({required this.layout, required this.images})
    : super(priority: stagePriority);

  static const stagePriority = -100;

  final StageLayout layout;
  final Map<String, Image> images;
  final List<SpriteBatch> _batches = <SpriteBatch>[];

  int _placementBuildCount = 0;
  int _batchBuildCount = 0;

  String get stageId => layout.spec.stageId;
  WorldChunkCoordinate? get coordinate => layout.coordinate;
  Rect get bounds => layout.bounds;
  int get placementBuildCount => _placementBuildCount;
  int get batchBuildCount => _batchBuildCount;
  int get placementCount =>
      layout.tiles.length + layout.decorations.length + layout.props.length;
  bool get ownsCollision => false;

  /// Exact source-cell mapping for the fixed 4x2 stage atlases.
  static Rect sourceRectFor({
    required StageAtlasKind kind,
    required int variant,
    required double cellSize,
  }) {
    final row = switch (kind) {
      StageAtlasKind.tile => 0,
      StageAtlasKind.decal => 1,
      StageAtlasKind.prop => variant ~/ 4,
    };
    return Rect.fromLTWH(
      (variant % 4) * cellSize,
      row * cellSize,
      cellSize,
      cellSize,
    );
  }

  @override
  Future<void> onLoad() async {
    _placementBuildCount += 1;
    final placementsByAsset = <String, List<_BatchEntry>>{};
    _addPlacements(
      placementsByAsset,
      layout.spec.tileAssetKey,
      layout.tiles.map(_batchEntryForTile),
    );
    final decalKey = layout.spec.decalAssetKey;
    if (decalKey != null) {
      _addPlacements(
        placementsByAsset,
        decalKey,
        layout.decorations.map(_batchEntryForDecoration),
      );
    }
    final propKey = layout.spec.propAssetKey;
    if (propKey != null) {
      _addPlacements(
        placementsByAsset,
        propKey,
        layout.props.map(_batchEntryForDecoration),
      );
    }
    for (final entry in placementsByAsset.entries) {
      _addBatch(entry.key, entry.value);
    }
  }

  void _addPlacements(
    Map<String, List<_BatchEntry>> placementsByAsset,
    String assetKey,
    Iterable<_BatchEntry> placements,
  ) {
    placementsByAsset
        .putIfAbsent(assetKey, () => <_BatchEntry>[])
        .addAll(placements);
  }

  _BatchEntry _batchEntryForTile(StageTilePlacement placement) => _BatchEntry(
    position: placement.position,
    size: placement.size,
    variant: placement.variant,
    kind: StageAtlasKind.tile,
  );

  _BatchEntry _batchEntryForDecoration(StageDecorationPlacement placement) =>
      _BatchEntry(
        position: placement.position,
        size: placement.size,
        variant: placement.variant,
        kind: placement.kind == StageDecorationKind.decal
            ? StageAtlasKind.decal
            : StageAtlasKind.prop,
      );

  void _addBatch(String assetKey, Iterable<_BatchEntry> placements) {
    final image = images[assetKey];
    if (image == null) return;
    final batch = SpriteBatch(image);
    for (final placement in placements) {
      if (!bounds.contains(placement.position + const Offset(0.1, 0.1))) {
        continue;
      }
      batch.add(
        source: sourceRectFor(
          kind: placement.kind,
          variant: placement.variant,
          cellSize: placement.size,
        ),
        offset: Vector2(placement.position.dx, placement.position.dy),
      );
    }
    if (batch.isEmpty) return;
    _batches.add(batch);
    _batchBuildCount += 1;
  }

  @override
  void render(Canvas canvas) {
    for (final batch in _batches) {
      batch.render(canvas);
    }
  }
}

enum StageAtlasKind { tile, decal, prop }

class _BatchEntry {
  const _BatchEntry({
    required this.position,
    required this.size,
    required this.variant,
    required this.kind,
  });

  final Offset position;
  final double size;
  final int variant;
  final StageAtlasKind kind;
}
