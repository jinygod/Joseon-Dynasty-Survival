import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/combat/attack_geometry.dart';
import 'package:pixel_survivor/game/combat/attack_spec.dart';
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

  test('follow clamps invalid frame time and smooths only dead-zone excess', () {
    final rig = CombatCameraController.test(
      config: WorldRuntimeConfig.standard,
      initialPosition: Vector2(1024, 2560),
    );

    rig.follow(Vector2(1054, 2560), dt: .5);

    expect(rig.basePosition.x, closeTo(1030.923, .001));
    expect(rig.basePosition.y, 2560);
  });

  test('camera centers do not alter combat world-space outcomes', () {
    final rig = CombatCameraController.test(
      config: WorldRuntimeConfig.standard,
      initialPosition: Vector2(1024, 2560),
      visibleSize: Vector2(400, 400),
    );
    final attack = AttackInstance(
      spec: AttackSpec(
        id: 'camera_invariance',
        shape: AttackShape.line,
        damage: 10,
        range: 80,
        angleRadians: 0,
        radius: 0,
        width: 12,
        windupSeconds: 0,
        activeSeconds: .1,
        lingerSeconds: 0,
        knockback: 0,
        slowFraction: 0,
        traits: const {AttackTrait.projectile},
        presentation: AttackPresentation.normal,
      ),
      origin: Vector2(1024, 2560),
      direction: Vector2(1, 0),
      sequenceIndex: 0,
    );
    final projectile = Vector2(1060, 2560);
    final enemy = Vector2(1068, 2560);
    final player = Vector2(1024, 2560);
    final outcomes = <({bool attack, bool projectile, bool contact})>[];

    for (final center in [Vector2(240, 480), Vector2(1800, 4600)]) {
      rig.snapTo(center);
      outcomes.add((
        attack: AttackGeometry.contains(attack, enemy, 8),
        projectile: projectile.distanceTo(enemy) <= 16,
        contact: player.distanceTo(enemy) <= 44,
      ));
    }

    expect(outcomes, hasLength(2));
    expect(outcomes.first, outcomes.last);
    expect(attack.origin, Vector2(1024, 2560));
    expect(projectile, Vector2(1060, 2560));
    expect(enemy, Vector2(1068, 2560));
  });
}
