import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';
import 'package:pixel_survivor/game/content/stage_visual_spec.dart';
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
    expect(streamer.loadedCoordinates, contains(const WorldChunkCoordinate(2, 5)));
    expect(streamer.loadedCoordinates, isNot(contains(const WorldChunkCoordinate(0, 0))));
  });
}
