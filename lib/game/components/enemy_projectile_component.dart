import 'dart:ui';

import 'package:flame/components.dart';

import 'player_component.dart';
import '../content/combat_visual_factory.dart';

class EnemyProjectileComponent extends PositionComponent {
  EnemyProjectileComponent({
    required this.sourceId,
    required this.damage,
    required Vector2 position,
    required Vector2 velocity,
    this.lifetime = 3,
    Vector2? size,
    this.visualFactory,
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
  final CombatVisualFactory? visualFactory;
  double _age = 0;
  bool _spent = false;

  bool get isExpired => _age >= lifetime;
  bool get isSpent => _spent;
  double get visualFootprint => 34;
  bool get usesRegistryVisual =>
      visualFactory?.images.containsKey(
        'projectiles/enemy/sakkat_spirit_projectile_128.png',
      ) ??
      false;
  bool get startsImageLoadOnMount => false;
  bool get ownsDamageResolution => false;

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
    final rect = Rect.fromCenter(
      center: Offset(size.x / 2, size.y / 2),
      width: visualFootprint,
      height: visualFootprint,
    );
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
