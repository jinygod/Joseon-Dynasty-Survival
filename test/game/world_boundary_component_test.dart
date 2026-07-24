import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/world_boundary_component.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';
import 'package:pixel_survivor/game/content/stage_visual_spec.dart';
import 'package:pixel_survivor/game/world/finite_world_layout.dart';
import 'package:pixel_survivor/game/world/world_chunk_coordinate.dart';
import 'package:pixel_survivor/game/world/world_runtime_config.dart';

void main() {
  Future<ui.Image> image() async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawRect(
      const ui.Rect.fromLTWH(0, 0, 512, 256),
      ui.Paint()..color = const ui.Color(0xffffffff),
    );
    final picture = recorder.endRecording();
    final result = await picture.toImage(512, 256);
    picture.dispose();
    return result;
  }

  test('boundary chunk renders four clamped props without collision', () async {
    final config = WorldRuntimeConfig.standard;
    final layout = FiniteWorldLayout.generate(
      stageId: plagueMarket,
      seed: 3107,
      config: config,
    );
    final props = await image();
    addTearDown(props.dispose);
    final component = WorldBoundaryComponent(
      layout: layout,
      coordinate: const WorldChunkCoordinate(0, 0),
      spec: stageVisualSpecFor(plagueMarket),
      images: {'props/plague_market_props_128.png': props},
    );

    await component.onLoad();

    expect(component.anchorCount, 4);
    expect(component.placementCount, 4);
    expect(component.batchBuildCount, 1);
    expect(component.placementBounds, hasLength(4));
    for (final bounds in component.placementBounds) {
      expect(layout.worldBounds.contains(bounds.topLeft), isTrue);
      expect(
        layout.worldBounds.contains(
          bounds.bottomRight - const ui.Offset(.1, .1),
        ),
        isTrue,
      );
      expect(
        layout.chunkBounds[const WorldChunkCoordinate(0, 0)]!.contains(
          bounds.topLeft,
        ),
        isTrue,
      );
      expect(
        layout.chunkBounds[const WorldChunkCoordinate(0, 0)]!.contains(
          bounds.bottomRight - const ui.Offset(.1, .1),
        ),
        isTrue,
      );
    }
    expect(component.ownsCollision, isFalse);
  });
}
