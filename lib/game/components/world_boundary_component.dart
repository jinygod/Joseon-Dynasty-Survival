import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

import '../content/stage_visual_spec.dart';
import '../world/finite_world_layout.dart';
import '../world/world_chunk_coordinate.dart';
import 'stage_tile_batch_component.dart';

/// Chunk-local, purely decorative edge dressing for a finite world.
class WorldBoundaryComponent extends Component {
  WorldBoundaryComponent({
    required this.layout,
    required this.coordinate,
    required this.spec,
    required this.images,
  }) : super(priority: StageTileBatchComponent.stagePriority + 1);

  final FiniteWorldLayout layout;
  final WorldChunkCoordinate coordinate;
  final StageVisualSpec spec;
  final Map<String, Image> images;
  SpriteBatch? _batch;
  int _batchBuildCount = 0;

  List<WorldLayoutAnchor> get anchors => List.unmodifiable(
    layout.boundaryDecorationAnchors
        .where((anchor) => anchor.coordinate == coordinate),
  );
  int get anchorCount => anchors.length;
  int get placementCount => anchorCount;
  int get batchBuildCount => _batchBuildCount;
  bool get ownsCollision => false;

  @override
  Future<void> onLoad() async {
    final key = spec.propAssetKey;
    final image = key == null ? null : images[key];
    if (image == null || anchors.isEmpty) return;
    final batch = SpriteBatch(image);
    for (var index = 0; index < anchors.length; index += 1) {
      final anchor = anchors[index];
      final variant = (anchor.layoutSeed + index) % spec.propVariants;
      final position = anchor.position - Offset(spec.tileSize / 2, spec.tileSize / 2);
      batch.add(
        source: StageTileBatchComponent.sourceRectFor(
          kind: StageAtlasKind.prop,
          variant: variant,
          cellSize: spec.tileSize,
        ),
        offset: Vector2(position.dx, position.dy),
      );
    }
    if (!batch.isEmpty) {
      _batch = batch;
      _batchBuildCount = 1;
    }
  }

  @override
  void render(Canvas canvas) => _batch?.render(canvas);
}
