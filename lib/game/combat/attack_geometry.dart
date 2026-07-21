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
    final origin = attack.origin;
    final direction = attack.direction;
    final dx = targetCenter.x - origin.x;
    final dy = targetCenter.y - origin.y;
    final distanceSquared = dx * dx + dy * dy;
    final reach = attack.spec.range + targetRadius;
    if (distanceSquared > reach * reach) return false;
    if (distanceSquared <= targetRadius * targetRadius) return true;

    final forward = dx * direction.x + dy * direction.y;
    final halfAngle = attack.spec.angleRadians / 2;
    if (halfAngle >= math.pi) return true;
    final threshold = math.cos(halfAngle) * math.sqrt(distanceSquared);
    if (forward >= threshold) return true;

    return _overlapsSectorSide(
          origin: origin,
          direction: direction,
          angle: halfAngle,
          range: attack.spec.range,
          targetCenter: targetCenter,
          targetRadius: targetRadius,
        ) ||
        _overlapsSectorSide(
          origin: origin,
          direction: direction,
          angle: -halfAngle,
          range: attack.spec.range,
          targetCenter: targetCenter,
          targetRadius: targetRadius,
        );
  }

  static bool _overlapsSectorSide({
    required Vector2 origin,
    required Vector2 direction,
    required double angle,
    required double range,
    required Vector2 targetCenter,
    required double targetRadius,
  }) {
    final cosine = math.cos(angle);
    final sine = math.sin(angle);
    final sideX = direction.x * cosine - direction.y * sine;
    final sideY = direction.x * sine + direction.y * cosine;
    final dx = targetCenter.x - origin.x;
    final dy = targetCenter.y - origin.y;
    final along = (dx * sideX + dy * sideY).clamp(0.0, range);
    final offsetX = dx - sideX * along;
    final offsetY = dy - sideY * along;
    return offsetX * offsetX + offsetY * offsetY <= targetRadius * targetRadius;
  }

  static bool _circleContains(
    AttackInstance attack,
    Vector2 targetCenter,
    double targetRadius,
  ) {
    final origin = attack.origin;
    final dx = targetCenter.x - origin.x;
    final dy = targetCenter.y - origin.y;
    final reach = attack.spec.radius + targetRadius;
    return dx * dx + dy * dy <= reach * reach;
  }

  static bool _lineContains(
    AttackInstance attack,
    Vector2 targetCenter,
    double targetRadius,
  ) {
    final origin = attack.origin;
    final direction = attack.direction;
    final dx = targetCenter.x - origin.x;
    final dy = targetCenter.y - origin.y;
    final projection = dx * direction.x + dy * direction.y;
    final along = projection.clamp(0.0, attack.spec.range);
    final closestX = origin.x + direction.x * along;
    final closestY = origin.y + direction.y * along;
    final offsetX = targetCenter.x - closestX;
    final offsetY = targetCenter.y - closestY;
    final reach = attack.spec.width / 2 + targetRadius;
    return offsetX * offsetX + offsetY * offsetY <= reach * reach;
  }
}
