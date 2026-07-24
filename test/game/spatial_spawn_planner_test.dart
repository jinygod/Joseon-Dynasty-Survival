import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/world/spatial_spawn_planner.dart';

void main() {
  test(
    'spawn is deterministic, outside visible rect, and inside the world',
    () {
      const planner = SpatialSpawnPlanner(seed: 3107);
      final request = SpatialSpawnRequest(
        visibleRect: const Rect.fromLTWH(800, 2200, 433, 938),
        worldBounds: const Rect.fromLTWH(0, 0, 2048, 5120),
        playerPosition: Vector2(1016, 2669),
        recentMotion: Vector2(1, 0),
        sequence: 12,
      );

      final first = planner.positionFor(request);
      final second = planner.positionFor(request);

      expect(second, first);
      expect(request.visibleRect.contains(first.toOffset()), isFalse);
      expect(request.worldBounds.contains(first.toOffset()), isTrue);
      expect(first.distanceTo(request.playerPosition), greaterThan(250));
    },
  );

  test('forward motion biases candidates toward the unexplored direction', () {
    const planner = SpatialSpawnPlanner(seed: 3107);
    final request = SpatialSpawnRequest(
      visibleRect: const Rect.fromLTWH(800, 2200, 433, 938),
      worldBounds: const Rect.fromLTWH(0, 0, 2048, 5120),
      playerPosition: Vector2(1016, 2669),
      recentMotion: Vector2(1, 0),
      sequence: 3,
      pressureFor: (position) => position.x < 1016 ? 100 : 0,
    );

    expect(planner.positionFor(request).x, greaterThan(1016));
  });
}
