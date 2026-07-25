import 'package:flame/components.dart';

class ProjectileContact {
  ProjectileContact({
    required this.travelFraction,
    required Vector2 point,
    required Vector2 normal,
  }) : _point = point.clone(),
       _normal = normal.clone();

  final double travelFraction;
  final Vector2 _point;
  final Vector2 _normal;

  Vector2 get point => _point.clone();
  Vector2 get normal => _normal.clone();
}
