import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import '../content/stage_visual_spec.dart';

/// Presentation-only static stage renderer. All batch contents are assembled
/// once while loading and are never changed during a run.
class StageTileBatchComponent extends Component {
  StageTileBatchComponent({required this.layout, required this.images});

  final StageLayout layout;
  final Map<String, Image> images;
  final List<SpriteBatch> _batches = <SpriteBatch>[];

  int _placementBuildCount = 0;
  int _batchBuildCount = 0;

  String get stageId => layout.spec.stageId;
  int get placementBuildCount => _placementBuildCount;
  int get batchBuildCount => _batchBuildCount;
  bool get ownsCollision => false;

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
  );

  _BatchEntry _batchEntryForDecoration(StageDecorationPlacement placement) =>
      _BatchEntry(
        position: placement.position,
        size: placement.size,
        variant: placement.variant,
      );

  void _addBatch(String assetKey, Iterable<_BatchEntry> placements) {
    final image = images[assetKey];
    if (image == null) return;
    final batch = SpriteBatch(image);
    for (final placement in placements) {
      batch.add(
        source: Rect.fromLTWH(
          placement.variant * placement.size,
          0,
          placement.size,
          placement.size,
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

class _BatchEntry {
  const _BatchEntry({
    required this.position,
    required this.size,
    required this.variant,
  });

  final Offset position;
  final double size;
  final int variant;
}
