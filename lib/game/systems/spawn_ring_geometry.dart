import 'dart:math' as math;

import 'package:flame/components.dart';

/// Pure geometry for placing enemies on every angle of an expanded viewport.
abstract final class SpawnRingGeometry {
  static Vector2 offsetForAngle(
    Vector2 viewport,
    double angle, {
    double margin = 24,
  }) {
    final direction = Vector2(math.cos(angle), math.sin(angle));
    final halfWidth = viewport.x / 2 + margin;
    final halfHeight = viewport.y / 2 + margin;
    final xScale = direction.x.abs() < 1e-9
        ? double.infinity
        : halfWidth / direction.x.abs();
    final yScale = direction.y.abs() < 1e-9
        ? double.infinity
        : halfHeight / direction.y.abs();
    return direction * math.min(xScale, yScale);
  }
}
