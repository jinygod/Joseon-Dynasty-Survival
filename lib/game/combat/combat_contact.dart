import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

@immutable
class CombatContact {
  CombatContact({required Vector2 point, required Vector2 normal})
    : _point = point.clone(),
      _normal = _unit(normal);

  final Vector2 _point;
  final Vector2 _normal;

  Vector2 get point => _point.clone();
  Vector2 get normal => _normal.clone();
}

Vector2 _unit(Vector2 value) {
  if (value.length2 == 0) return Vector2(1, 0);
  return value.clone()..normalize();
}
