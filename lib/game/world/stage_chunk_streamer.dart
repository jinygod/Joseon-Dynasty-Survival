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
  });

  final FiniteWorldLayout layout;
  final StageVisualSpec spec;
  final int seed;
  final Map<String, Image> images;
  final double chunkSize;
  final Map<WorldChunkCoordinate, Component> _loaded = {};

  Set<WorldChunkCoordinate> get loadedCoordinates =>
      UnmodifiableSetView(_loaded.keys.toSet());
  int get loadedCount => _loaded.length;

  void updateStreaming(Rect baseZone) {
    final desiredZone = baseZone.inflate(chunkSize).intersect(layout.worldBounds);
    final desired = layout.chunks
        .where((chunk) => chunk.bounds.overlaps(desiredZone))
        .map((chunk) => chunk.coordinate)
        .toSet();
    for (final coordinate in _loaded.keys.where((key) => !desired.contains(key)).toList()) {
      final component = _loaded.remove(coordinate)!;
      component.removeFromParent();
    }
    for (final chunk in layout.chunks.where((item) => desired.contains(item.coordinate))) {
      if (_loaded.containsKey(chunk.coordinate)) continue;
      final bundle = _StageChunkBundle();
      bundle.add(StageTileBatchComponent(
        layout: StageLayout.buildChunk(
          spec,
          seed: seed,
          coordinate: chunk.coordinate,
          chunkSize: chunkSize,
          worldBounds: layout.worldBounds,
        ),
        images: images,
      ));
      if (chunk.isBoundary) {
        bundle.add(WorldBoundaryComponent(
          layout: layout,
          coordinate: chunk.coordinate,
          spec: spec,
          images: images,
        ));
      }
      _loaded[chunk.coordinate] = bundle;
      add(bundle);
    }
  }
}

class _StageChunkBundle extends Component {}
