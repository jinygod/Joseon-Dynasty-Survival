import 'package:flame/game.dart';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';
import 'package:pixel_survivor/game/content/stage_visual_spec.dart';
import 'package:pixel_survivor/game/components/stage_tile_batch_component.dart';
import 'package:pixel_survivor/game/world/finite_world_layout.dart';
import 'package:pixel_survivor/game/world/stage_chunk_streamer.dart';
import 'package:pixel_survivor/game/world/world_chunk_coordinate.dart';
import 'package:pixel_survivor/game/world/world_runtime_config.dart';

void main() {
  test('streams only chunks intersecting the inflated zone', () {
    final config = WorldRuntimeConfig.standard;
    final layout = FiniteWorldLayout.generate(
      stageId: plagueMarket,
      seed: 3107,
      config: config,
    );
    final streamer = StageChunkStreamer(
      layout: layout,
      spec: stageVisualSpecFor(plagueMarket),
      seed: 3107,
      images: const {},
      chunkSize: config.chunkSize,
    );

    streamer.updateStreaming(const Rect.fromLTWH(1024, 2560, 512, 512));

    expect(streamer.loadedCount, 9);
    expect(
      streamer.loadedCoordinates,
      contains(const WorldChunkCoordinate(2, 5)),
    );
    expect(
      streamer.loadedCoordinates,
      isNot(contains(const WorldChunkCoordinate(0, 0))),
    );
  });

  test('streamer renders below combat components', () {
    final streamer = StageChunkStreamer(
      layout: FiniteWorldLayout.generate(
        stageId: plagueMarket,
        seed: 3107,
        config: WorldRuntimeConfig.standard,
      ),
      spec: stageVisualSpecFor(plagueMarket),
      seed: 3107,
      images: const {},
      chunkSize: WorldRuntimeConfig.standard.chunkSize,
    );

    expect(
      streamer.priority,
      lessThanOrEqualTo(StageTileBatchComponent.stagePriority),
    );
  });

  test('streamer forwards real landmark anchors to interior stage layouts', () {
    final config = WorldRuntimeConfig.standard;
    final layout = FiniteWorldLayout.generate(
      stageId: plagueMarket,
      seed: 3107,
      config: config,
    );
    final landmark = layout.landmarkAnchors.first;
    final streamer = StageChunkStreamer(
      layout: layout,
      spec: stageVisualSpecFor(plagueMarket),
      seed: 3107,
      images: const {},
      chunkSize: config.chunkSize,
    );

    streamer.updateStreaming(landmark.position & const Size(1, 1));

    final batch = streamer
        .descendants(includeSelf: false)
        .whereType<StageTileBatchComponent>()
        .singleWhere(
          (component) => component.coordinate == landmark.coordinate,
        );
    expect(batch.layout.decorations, isNotEmpty);
  });

  test(
    'unload then immediate reentry retains one bundle per coordinate',
    () async {
      final config = WorldRuntimeConfig.standard;
      final streamer = StageChunkStreamer(
        layout: FiniteWorldLayout.generate(
          stageId: plagueMarket,
          seed: 3107,
          config: config,
        ),
        spec: stageVisualSpecFor(plagueMarket),
        seed: 3107,
        images: const {},
        chunkSize: config.chunkSize,
      );
      final game = FlameGame();
      game.onGameResize(Vector2(960, 540));
      await game.onLoad();
      await game.add(streamer);
      await game.lifecycleEventsProcessed;

      const firstZone = Rect.fromLTWH(0, 0, 512, 512);
      const secondZone = Rect.fromLTWH(1024, 2560, 512, 512);
      streamer.updateStreaming(firstZone);
      await game.lifecycleEventsProcessed;
      streamer.updateStreaming(secondZone);
      streamer.updateStreaming(secondZone);
      streamer.updateStreaming(firstZone);
      streamer.updateStreaming(firstZone);
      game.update(0);
      await game.lifecycleEventsProcessed;

      expect(streamer.mountedBundleCount, streamer.loadedCount);
      expect(streamer.mountedBundleCount, 4);
    },
  );
}
