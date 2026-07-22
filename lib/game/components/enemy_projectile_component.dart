import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../combat/combat_vfx_primitives.dart';
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
    const palette = CombatVfxPalette(
      core: Color(0xfffff3fb),
      edge: Color(0xffff5ca8),
      accent: Color(0xffffc2df),
      smoke: Color(0xff5f2346),
    );
    final center = Offset(size.x / 2, size.y / 2);
    final velocityLength = velocity.length;
    final direction = velocityLength <= .001
        ? const Offset(1, 0)
        : Offset(velocity.x / velocityLength, velocity.y / velocityLength);
    final tailEnd =
        center - direction * math.min(22, 10 + velocityLength * .04);
    CombatVfxPrimitives.drawTaperedTrail(
      canvas,
      start: center,
      end: tailEnd,
      startWidth: size.x * .52,
      endWidth: size.x * .14,
      palette: palette,
      progress: _age / lifetime,
      count: 2,
    );
    canvas.drawCircle(
      center,
      size.x * .5,
      Paint()..color = palette.smoke.withValues(alpha: .92),
    );
    canvas.drawCircle(center, size.x * .37, Paint()..color = palette.edge);
    canvas.drawCircle(center, size.x * .19, Paint()..color = palette.core);
    canvas.drawCircle(
      center,
      size.x * .5,
      Paint()
        ..color = palette.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }
}
