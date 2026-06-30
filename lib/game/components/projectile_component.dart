import 'dart:ui';

import 'package:flame/components.dart';

import 'enemy_component.dart';
import '../content/ids.dart';

class ProjectileComponent extends PositionComponent {
  ProjectileComponent({
    required this.weaponId,
    required this.damage,
    required Vector2 position,
    required this.velocity,
    this.lifetime = 2.2,
    Vector2? size,
  }) : super(
         position: position,
         size: size ?? Vector2.all(8),
         anchor: Anchor.center,
       );

  final WeaponId weaponId;
  final double damage;
  final Vector2 velocity;
  final double lifetime;
  double _age = 0;

  bool get isExpired => _age >= lifetime;

  bool overlapsEnemy(EnemyComponent enemy) {
    final hitRadius = (size.x + enemy.size.x) / 2;
    return position.distanceToSquared(enemy.position) < hitRadius * hitRadius;
  }

  @override
  void update(double dt) {
    super.update(dt);

    _age += dt;
    position.add(velocity * dt);
    if (isExpired) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()..color = const Color(0xfff2cc8f);
    final outlinePaint = Paint()
      ..color = const Color(0xff2f1b25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rect = Offset.zero & Size(size.x, size.y);
    canvas.drawOval(rect, paint);
    canvas.drawOval(rect, outlinePaint);
  }
}
