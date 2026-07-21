import 'dart:math' as math;

import 'package:flame/components.dart';

import 'attack_spec.dart';

abstract final class AttackGeometry {
  static bool contains(
    AttackInstance attack,
    Vector2 targetCenter,
    double targetRadius,
  ) {
    return switch (attack.spec.shape) {
      AttackShape.sector => _sectorContains(attack, targetCenter, targetRadius),
      AttackShape.circle => _circleContains(attack, targetCenter, targetRadius),
      AttackShape.line => _lineContains(attack, targetCenter, targetRadius),
    };
  }

  static bool _sectorContains(
    AttackInstance attack,
    Vector2 targetCenter,
    double targetRadius,
  ) {
    final dx = targetCenter.x - attack.origin.x;
    final dy = targetCenter.y - attack.origin.y;
    final distanceSquared = dx * dx + dy * dy;
    final reach = attack.spec.range + targetRadius;
    if (distanceSquared > reach * reach) return false;
    if (distanceSquared == 0) return true;

    final forward = dx * attack.direction.x + dy * attack.direction.y;
    final halfAngle = attack.spec.angleRadians / 2;
    final threshold = math.cos(halfAngle) * math.sqrt(distanceSquared);
    return forward >= threshold;
  }

  static bool _circleContains(
    AttackInstance attack,
    Vector2 targetCenter,
    double targetRadius,
  ) {
    final dx = targetCenter.x - attack.origin.x;
    final dy = targetCenter.y - attack.origin.y;
    final reach = attack.spec.radius + targetRadius;
    return dx * dx + dy * dy <= reach * reach;
  }

  static bool _lineContains(
    AttackInstance attack,
    Vector2 targetCenter,
    double targetRadius,
  ) {
    final dx = targetCenter.x - attack.origin.x;
    final dy = targetCenter.y - attack.origin.y;
    final projection = dx * attack.direction.x + dy * attack.direction.y;
    final along = projection.clamp(0.0, attack.spec.range);
    final closestX = attack.origin.x + attack.direction.x * along;
    final closestY = attack.origin.y + attack.direction.y * along;
    final offsetX = targetCenter.x - closestX;
    final offsetY = targetCenter.y - closestY;
    final reach = attack.spec.width / 2 + targetRadius;
    return offsetX * offsetX + offsetY * offsetY <= reach * reach;
  }
}
