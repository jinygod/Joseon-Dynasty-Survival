import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

typedef SpawnPressureProvider = double Function(Vector2 position);

@immutable
class SpatialSpawnRequest {
  SpatialSpawnRequest({
    required this.visibleRect,
    required this.worldBounds,
    required Vector2 playerPosition,
    required Vector2 recentMotion,
    required this.sequence,
    this.minDistance = 250,
    this.pressureFor,
  }) : playerPosition = playerPosition.clone(),
       recentMotion = recentMotion.clone();

  final Rect visibleRect;
  final Rect worldBounds;
  final Vector2 playerPosition;
  final Vector2 recentMotion;
  final int sequence;
  final double minDistance;
  final SpawnPressureProvider? pressureFor;
}

class SpatialSpawnPlanner {
  const SpatialSpawnPlanner({required this.seed});

  final int seed;

  Vector2 positionFor(SpatialSpawnRequest request) {
    final motion = request.recentMotion.clone();
    if (motion.length2 > 0) motion.normalize();
    Vector2? best;
    var bestScore = double.infinity;

    for (var index = 0; index < 24; index += 1) {
      final unit = _unitFor(request.sequence, index);
      final candidate = Vector2(
        request.visibleRect.center.dx +
            unit.x * (request.visibleRect.width / 2 + 96),
        request.visibleRect.center.dy +
            unit.y * (request.visibleRect.height / 2 + 96),
      );
      candidate.setValues(
        candidate.x.clamp(
          request.worldBounds.left + 24,
          request.worldBounds.right - 24,
        ),
        candidate.y.clamp(
          request.worldBounds.top + 24,
          request.worldBounds.bottom - 24,
        ),
      );
      if (request.visibleRect.contains(candidate.toOffset()) ||
          candidate.distanceTo(request.playerPosition) < request.minDistance) {
        continue;
      }
      final pressure = request.pressureFor?.call(candidate) ?? 0;
      final direction = candidate - request.playerPosition;
      if (direction.length2 > 0) direction.normalize();
      final forwardBias = motion.length2 == 0 ? 0 : direction.dot(motion);
      final score =
          pressure * 100 -
          forwardBias * 80 +
          (_hash(request.sequence, index) & 1023) / 1023;
      if (score < bestScore) {
        bestScore = score;
        best = candidate;
      }
    }

    return best ??
        Vector2(request.worldBounds.center.dx, request.worldBounds.center.dy);
  }

  Vector2 _unitFor(int sequence, int index) {
    final phase = (_hash(sequence, 97) & 0xffff) / 0xffff * math.pi * 2;
    final angle = phase + index * math.pi * 2 / 24;
    return Vector2(math.cos(angle), math.sin(angle));
  }

  int _hash(int sequence, int index) {
    var value = seed ^ (sequence * 0x45d9f3b) ^ (index * 0x27d4eb2d);
    value = ((value >> 16) ^ value) * 0x45d9f3b;
    value = ((value >> 16) ^ value) * 0x45d9f3b;
    return (value >> 16) ^ value;
  }
}
