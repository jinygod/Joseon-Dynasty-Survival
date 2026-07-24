import 'dart:collection';
import 'dart:ui';

import 'package:flame/components.dart';

import '../components/stage_tile_batch_component.dart';
import '../components/world_boundary_component.dart';
import '../content/stage_visual_spec.dart';
import 'finite_world_layout.dart';
import 'world_chunk_coordinate.dart';

/// Owns the bounded set of stage presentation chunks around the camera zone.
class StageChunkStreamer extends Component {
  StageChunkStreamer({
    required this.layout,
    required this.spec,
    required this.seed,
    required this.images,
    required this.chunkSize,
  }) : super(priority: StageTileBatchComponent.stagePriority);

  final FiniteWorldLayout layout;
  final StageVisualSpec spec;
  final int seed;
  final Map<String, Image> images;
  final double chunkSize;
  final Map<WorldChunkCoordinate, _StageChunkBundle> _loaded = {};
  final Set<WorldChunkCoordinate> _retiring = <WorldChunkCoordinate>{};

  Set<WorldChunkCoordinate> get loadedCoordinates => UnmodifiableSetView(
    _loaded.keys.where((coordinate) => !_retiring.contains(coordinate)).toSet(),
  );
  int get loadedCount => loadedCoordinates.length;
  int get mountedBundleCount => children.whereType<_StageChunkBundle>().length;

  void updateStreaming(Rect baseZone) {
    final desiredZone = baseZone
        .inflate(chunkSize)
        .intersect(layout.worldBounds);
    final desired = layout.chunks
        .where((chunk) => chunk.bounds.overlaps(desiredZone))
        .map((chunk) => chunk.coordinate)
        .toSet();
    for (final chunk in layout.chunks.where(
      (item) => desired.contains(item.coordinate),
    )) {
      final existing = _loaded[chunk.coordinate];
      if (existing != null) {
        _retiring.remove(chunk.coordinate);
        continue;
      }
      late final _StageChunkBundle bundle;
      bundle = _StageChunkBundle(
        onRemoved: () {
          if (identical(_loaded[chunk.coordinate], bundle)) {
            _loaded.remove(chunk.coordinate);
            _retiring.remove(chunk.coordinate);
          }
        },
      );
      bundle.add(
        StageTileBatchComponent(
          layout: StageLayout.buildChunk(
            spec,
            seed: seed,
            coordinate: chunk.coordinate,
            chunkSize: chunkSize,
            worldBounds: layout.worldBounds,
          ),
          images: images,
        ),
      );
      if (chunk.isBoundary) {
        bundle.add(
          WorldBoundaryComponent(
            layout: layout,
            coordinate: chunk.coordinate,
            spec: spec,
            images: images,
          ),
        );
      }
      _loaded[chunk.coordinate] = bundle;
      add(bundle);
    }
    for (final coordinate
        in _loaded.keys.where((key) => !desired.contains(key)).toList()) {
      _retiring.add(coordinate);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    for (final coordinate in _retiring.toList()) {
      final component = _loaded[coordinate];
      _retiring.remove(coordinate);
      if (component == null) continue;
      component.removeFromParent();
      if (component.parent == null &&
          identical(_loaded[coordinate], component)) {
        _loaded.remove(coordinate);
      }
    }
  }
}

class _StageChunkBundle extends Component {
  _StageChunkBundle({required this.onRemoved});

  final void Function() onRemoved;

  @override
  void onRemove() {
    onRemoved();
    super.onRemove();
  }
}
