import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

enum AttackShape { sector, circle, line }

enum AttackTrait { melee, projectile, piercing, explosion, master, synergy }

enum AttackPresentation { normal, strong, master, synergy }

@immutable
class AttackSpec {
  const AttackSpec({
    required this.id,
    required this.shape,
    required this.damage,
    required this.range,
    required this.angleRadians,
    required this.radius,
    required this.width,
    required this.windupSeconds,
    required this.activeSeconds,
    required this.lingerSeconds,
    required this.knockback,
    required this.slowFraction,
    required this.traits,
    required this.presentation,
  });

  final String id;
  final AttackShape shape;
  final double damage;
  final double range;
  final double angleRadians;
  final double radius;
  final double width;
  final double windupSeconds;
  final double activeSeconds;
  final double lingerSeconds;
  final double knockback;
  final double slowFraction;
  final Set<AttackTrait> traits;
  final AttackPresentation presentation;
}

@immutable
class AttackInstance {
  AttackInstance({
    required this.spec,
    required Vector2 origin,
    required Vector2 direction,
    required this.sequenceIndex,
  }) : origin = origin.clone(),
       direction = _unit(direction);

  final AttackSpec spec;
  final Vector2 origin;
  final Vector2 direction;
  final int sequenceIndex;
}

Vector2 _unit(Vector2 direction) {
  if (direction.length2 == 0) {
    return Vector2(1, 0);
  }
  return direction.clone()..normalize();
}
