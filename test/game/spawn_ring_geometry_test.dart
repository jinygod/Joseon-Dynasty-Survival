import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/systems/spawn_ring_geometry.dart';

void main() {
  test('diagonal spawn angles use both axes', () {
    final offset = SpawnRingGeometry.offsetForAngle(
      Vector2(390, 844),
      math.pi / 4,
    );

    expect(offset.x, greaterThan(0));
    expect(offset.y, greaterThan(0));
  });

  test('all sampled angles land on the expanded viewport perimeter', () {
    const margin = 24.0;
    final viewport = Vector2(390, 844);
    final halfWidth = viewport.x / 2 + margin;
    final halfHeight = viewport.y / 2 + margin;

    for (var index = 0; index < 72; index += 1) {
      final offset = SpawnRingGeometry.offsetForAngle(
        viewport,
        index * math.pi * 2 / 72,
        margin: margin,
      );
      final onVerticalEdge = (offset.x.abs() - halfWidth).abs() < 1e-6;
      final onHorizontalEdge = (offset.y.abs() - halfHeight).abs() < 1e-6;

      expect(
        onVerticalEdge || onHorizontalEdge,
        isTrue,
        reason: 'angle sample $index must touch the expanded rectangle',
      );
      expect(offset.x.abs(), lessThanOrEqualTo(halfWidth + 1e-6));
      expect(offset.y.abs(), lessThanOrEqualTo(halfHeight + 1e-6));
    }
  });
}
