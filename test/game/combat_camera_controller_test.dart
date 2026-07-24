import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/world/combat_camera_controller.dart';
import 'package:pixel_survivor/game/world/world_runtime_config.dart';

void main() {
  test('small target motion remains inside dead zone', () {
    final rig = CombatCameraController.test(
      config: WorldRuntimeConfig.standard,
      initialPosition: Vector2(1024, 2560),
    );

    rig.follow(Vector2(1030, 2568), dt: 1 / 60);

    expect(rig.basePosition, Vector2(1024, 2560));
  });

  test('camera center clamps so visible rect remains inside world', () {
    final center = CombatCameraController.clampCenter(
      desired: Vector2.zero(),
      visibleSize: Vector2(433.333, 937.778),
      worldBounds: const Rect.fromLTWH(0, 0, 2048, 5120),
    );

    expect(center.x, closeTo(216.6665, .001));
    expect(center.y, closeTo(468.889, .001));
  });

  test('a viewport larger than the world centers that axis', () {
    final center = CombatCameraController.clampCenter(
      desired: Vector2(75, 10),
      visibleSize: Vector2(200, 40),
      worldBounds: const Rect.fromLTWH(0, 0, 100, 80),
    );

    expect(center, Vector2(50, 20));
  });

  test(
    'follow clamps invalid frame time and smooths only dead-zone excess',
    () {
      final rig = CombatCameraController.test(
        config: WorldRuntimeConfig.standard,
        initialPosition: Vector2(1024, 2560),
      );

      rig.follow(Vector2(1054, 2560), dt: .5);

      expect(rig.basePosition.x, closeTo(1030.923, .001));
      expect(rig.basePosition.y, 2560);
    },
  );
}
