import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../content/ids.dart';
import 'enemy_component.dart';

class MeleeArcComponent extends PositionComponent {
  MeleeArcComponent({
    required this.weaponId,
    required this.damage,
    required this.knockback,
    required Vector2 position,
    required Vector2 direction,
    required this.range,
    this.angleRadians = math.pi * 0.7,
    this.lifetime = 0.12,
  }) : direction = _normalizedDirection(direction),
       super(
         position: position,
         size: Vector2.all(range * 2),
         anchor: Anchor.center,
       );

  final WeaponId weaponId;
  final double damage;
  final double knockback;
  final Vector2 direction;
  final double range;
  final double angleRadians;
  final double lifetime;

  double _age = 0;

  bool containsEnemy(EnemyComponent enemy) {
    final offset = enemy.position - position;
    final hitRange = range + enemy.size.x / 2;
    if (offset.length2 > hitRange * hitRange) {
      return false;
    }
    if (offset.length2 == 0) {
      return true;
    }

    offset.normalize();
    return direction.dot(offset) >= math.cos(angleRadians / 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= lifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final center = Offset(size.x / 2, size.y / 2);
    final facingAngle = math.atan2(direction.y, direction.x);
    final paint = Paint()
      ..color = const Color(0xfff4ead2).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: range),
      facingAngle - angleRadians / 2,
      angleRadians,
      false,
      paint,
    );
  }

  static Vector2 _normalizedDirection(Vector2 direction) {
    final result = direction.clone();
    if (result.length2 == 0) {
      result.setValues(1, 0);
    } else {
      result.normalize();
    }
    return result;
  }
}
