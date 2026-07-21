import 'dart:ui';

import 'package:flame/components.dart';

import 'player_component.dart';

class EnemyProjectileComponent extends PositionComponent {
  EnemyProjectileComponent({
    required this.sourceId,
    required this.damage,
    required Vector2 position,
    required Vector2 velocity,
    this.lifetime = 3,
    Vector2? size,
  }) : velocity = velocity.clone(),
       super(
         position: position,
         size: size ?? Vector2.all(10),
         anchor: Anchor.center,
       );

  final String sourceId;
  final double damage;
  final Vector2 velocity;
  final double lifetime;
  double _age = 0;
  bool _spent = false;

  bool get isExpired => _age >= lifetime;
  bool get isSpent => _spent;

  bool overlapsPlayer(PlayerComponent player) {
    final radius = (size.x + player.size.x) / 2;
    return position.distanceToSquared(player.position) < radius * radius;
  }

  bool registerHit() {
    if (_spent) return false;
    _spent = true;
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final safeDt = dt.isFinite && dt > 0 ? dt : 0.0;
    _age += safeDt;
    position.add(velocity * safeDt);
    if (isExpired || isSpent) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final rect = Offset.zero & Size(size.x, size.y);
    canvas.drawOval(rect, Paint()..color = const Color(0xff9f2b68));
    canvas.drawOval(
      rect,
      Paint()
        ..color = const Color(0xffff5ca8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}
