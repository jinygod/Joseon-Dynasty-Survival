import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/world_boundary_component.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';
import 'package:pixel_survivor/game/content/stage_visual_spec.dart';
import 'package:pixel_survivor/game/world/finite_world_layout.dart';
import 'package:pixel_survivor/game/world/world_chunk_coordinate.dart';
import 'package:pixel_survivor/game/world/world_runtime_config.dart';

void main() {
  test('boundary chunk consumes its four anchors without collision', () async {
    final config = WorldRuntimeConfig.standard;
    final layout = FiniteWorldLayout.generate(
      stageId: plagueMarket,
      seed: 3107,
      config: config,
    );
    final component = WorldBoundaryComponent(
      layout: layout,
      coordinate: const WorldChunkCoordinate(0, 0),
      spec: stageVisualSpecFor(plagueMarket),
      images: const {},
    );

    await component.onLoad();

    expect(component.anchorCount, 4);
    expect(component.placementCount, 4);
    expect(component.batchBuildCount, 0);
    expect(component.ownsCollision, isFalse);
  });
}
