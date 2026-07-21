import 'package:flame/components.dart';

import '../components/enemy_component.dart';

class HwandoAimDecision {
  HwandoAimDecision({required this.target, required Vector2 direction})
    : direction = direction.clone();

  final EnemyComponent? target;
  final Vector2 direction;
}

abstract final class HwandoAimResolver {
  static HwandoAimDecision resolve({
    required Vector2 origin,
    required Iterable<EnemyComponent> enemies,
    required double maxRange,
    required Vector2 fallbackDirection,
  }) {
    EnemyComponent? nearest;
    var nearestDistance = double.infinity;
    var nearestIndex = -1;
    final rangeSquared = maxRange <= 0 ? 0.0 : maxRange * maxRange;

    var index = 0;
    for (final enemy in enemies) {
      if (enemy.isDead || enemy.isRemoving) {
        index += 1;
        continue;
      }
      final distance = enemy.position.distanceToSquared(origin);
      if (distance > rangeSquared) {
        index += 1;
        continue;
      }

      final idOrder = nearest == null
          ? -1
          : enemy.enemyId.compareTo(nearest.enemyId);
      final isBetter =
          distance < nearestDistance ||
          (distance == nearestDistance &&
              (idOrder < 0 || (idOrder == 0 && index < nearestIndex)));
      if (isBetter) {
        nearest = enemy;
        nearestDistance = distance;
        nearestIndex = index;
      }
      index += 1;
    }

    final targetDirection = nearest == null ? null : nearest.position - origin;
    return HwandoAimDecision(
      target: nearest,
      direction: _normalizedOrFallback(targetDirection, fallbackDirection),
    );
  }

  static Vector2 _normalizedOrFallback(
    Vector2? direction,
    Vector2 fallbackDirection,
  ) {
    final result = direction?.clone() ?? fallbackDirection.clone();
    if (result.length2 == 0) return Vector2(1, 0);
    return result..normalize();
  }
}
