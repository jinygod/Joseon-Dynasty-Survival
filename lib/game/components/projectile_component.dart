import 'dart:ui';

import 'package:flame/components.dart';

import '../content/ids.dart';

class ProjectileComponent extends PositionComponent {
  ProjectileComponent({
    required this.weaponId,
    required this.damage,
    required Vector2 position,
    required this.velocity,
    Vector2? size,
  }) : super(
         position: position,
         size: size ?? Vector2.all(8),
         anchor: Anchor.center,
       );

  final WeaponId weaponId;
  final double damage;
  final Vector2 velocity;

  @override
  void update(double dt) {
    super.update(dt);

    position.add(velocity * dt);
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
