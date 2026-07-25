import 'dart:math' as math;

import 'package:flame/components.dart';

import 'projectile_contact.dart';

abstract final class ProjectileSweepGeometry {
  static const _epsilon = 0.0000001;

  static ProjectileContact? firstContact({
    required Vector2 previousCenter,
    required Vector2 currentCenter,
    required Vector2 direction,
    required Vector2 hitBodySize,
    required Vector2 hurtCenter,
    required double hurtRadius,
  }) {
    _validate(
      previousCenter,
      currentCenter,
      direction,
      hitBodySize,
      hurtCenter,
      hurtRadius,
    );

    final travel = currentCenter - previousCenter;
    final facing = _unitDirection(direction, travel);
    final halfLength = hitBodySize.x / 2;
    final expandedRadius = hurtRadius + hitBodySize.y / 2;
    final initialStart = previousCenter - facing * halfLength;
    final initialEnd = previousCenter + facing * halfLength;
    final initialClosest = _closestPoint(initialStart, initialEnd, hurtCenter);

    if (initialClosest.distanceToSquared(hurtCenter) <=
        expandedRadius * expandedRadius + _epsilon) {
      return _contact(
        travelFraction: 0,
        projectilePoint: initialClosest,
        hurtCenter: hurtCenter,
        hurtRadius: hurtRadius,
        fallbackNormal: facing,
      );
    }

    if (travel.length2 <= _epsilon) {
      return null;
    }

    final leadingStart = previousCenter + facing * halfLength;
    final leadingEnd = currentCenter + facing * halfLength;
    final travelFraction = _firstSegmentCircleFraction(
      leadingStart,
      leadingEnd,
      hurtCenter,
      expandedRadius,
    );
    if (travelFraction == null) {
      return null;
    }

    final projectilePoint =
        leadingStart + (leadingEnd - leadingStart) * travelFraction;
    return _contact(
      travelFraction: travelFraction,
      projectilePoint: projectilePoint,
      hurtCenter: hurtCenter,
      hurtRadius: hurtRadius,
      fallbackNormal: facing,
    );
  }

  static ProjectileContact _contact({
    required double travelFraction,
    required Vector2 projectilePoint,
    required Vector2 hurtCenter,
    required double hurtRadius,
    required Vector2 fallbackNormal,
  }) {
    final normal = hurtCenter - projectilePoint;
    if (normal.length2 <= _epsilon) {
      normal.setFrom(fallbackNormal);
    } else {
      normal.normalize();
    }
    return ProjectileContact(
      travelFraction: travelFraction.clamp(0, 1).toDouble(),
      point: hurtCenter - normal * hurtRadius,
      normal: normal,
    );
  }

  static double? _firstSegmentCircleFraction(
    Vector2 start,
    Vector2 end,
    Vector2 center,
    double radius,
  ) {
    final segment = end - start;
    final offset = start - center;
    final a = segment.dot(segment);
    if (a <= _epsilon) {
      return null;
    }
    final b = 2 * offset.dot(segment);
    final c = offset.dot(offset) - radius * radius;
    final discriminant = b * b - 4 * a * c;
    if (discriminant < 0) {
      return null;
    }
    final root = math.sqrt(discriminant);
    final first = (-b - root) / (2 * a);
    if (first >= 0 && first <= 1) {
      return first;
    }
    final second = (-b + root) / (2 * a);
    return second >= 0 && second <= 1 ? second : null;
  }

  static Vector2 _closestPoint(Vector2 start, Vector2 end, Vector2 point) {
    final segment = end - start;
    final lengthSquared = segment.length2;
    if (lengthSquared <= _epsilon) {
      return start.clone();
    }
    final fraction = ((point - start).dot(segment) / lengthSquared)
        .clamp(0, 1)
        .toDouble();
    return start + segment * fraction;
  }

  static Vector2 _unitDirection(Vector2 direction, Vector2 travel) {
    final result = direction.length2 > _epsilon
        ? direction.clone()
        : travel.length2 > _epsilon
        ? travel.clone()
        : Vector2(1, 0);
    return result..normalize();
  }

  static void _validate(
    Vector2 previousCenter,
    Vector2 currentCenter,
    Vector2 direction,
    Vector2 hitBodySize,
    Vector2 hurtCenter,
    double hurtRadius,
  ) {
    final vectors = [
      previousCenter,
      currentCenter,
      direction,
      hitBodySize,
      hurtCenter,
    ];
    if (vectors.any((value) => !value.x.isFinite || !value.y.isFinite) ||
        !hurtRadius.isFinite ||
        hitBodySize.x <= 0 ||
        hitBodySize.y <= 0 ||
        hurtRadius < 0) {
      throw ArgumentError('Projectile sweep geometry must be finite');
    }
  }
}
