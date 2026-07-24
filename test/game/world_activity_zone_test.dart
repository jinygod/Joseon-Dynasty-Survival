import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/world/world_activity_zone.dart';

void main() {
  test('position transitions visible active sleeping recycle', () {
    final zones = WorldActivityZones.fromVisibleRect(
      const Rect.fromLTWH(800, 2200, 433, 938),
      worldBounds: const Rect.fromLTWH(0, 0, 2048, 5120),
      hysteresis: 64,
    );

    expect(zones.classify(Vector2(900, 2500)), WorldActivityTier.visible);
    expect(zones.classify(Vector2(600, 1800)), WorldActivityTier.active);
    expect(zones.classify(Vector2(100, 800)), WorldActivityTier.sleeping);
    expect(zones.classify(Vector2(1900, 20)), WorldActivityTier.recycle);
  });

  test(
    'hysteresis retains the previous tier across a short boundary wobble',
    () {
      final zones = WorldActivityZones.fromVisibleRect(
        const Rect.fromLTWH(800, 2200, 433, 938),
        worldBounds: const Rect.fromLTWH(0, 0, 2048, 5120),
        hysteresis: 64,
      );

      expect(
        zones.classify(Vector2(776, 2500), previous: WorldActivityTier.visible),
        WorldActivityTier.visible,
      );
      expect(
        zones.classify(Vector2(700, 2500), previous: WorldActivityTier.visible),
        WorldActivityTier.active,
      );
    },
  );
}
