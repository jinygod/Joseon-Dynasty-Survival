import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'enemy_component.dart';
import '../content/ids.dart';
import '../content/weapon_effect_atlas.dart';
import '../content/weapon_visual_theme.dart';

class ProjectileComponent extends PositionComponent {
  ProjectileComponent({
    required this.weaponId,
    required this.damage,
    required Vector2 position,
    required this.velocity,
    this.lifetime = 2.2,
    this.pierce = 0,
    this.knockback = 0,
    this.followUpIndex = 0,
    this.isMasterLead = false,
    this.laneIndex = 0,
    Vector2? size,
  }) : _remainingHits = pierce + 1,
       super(
         position: position,
         size: size ?? Vector2.all(8),
         anchor: Anchor.center,
       );

  final WeaponId weaponId;
  final double damage;
  final Vector2 velocity;
  final double lifetime;
  final int pierce;
  final double knockback;
  final int followUpIndex;
  final bool isMasterLead;
  final int laneIndex;
  final Set<EnemyComponent> _hitEnemies = {};
  int _remainingHits;
  double _age = 0;
  Image? _effectImage;

  bool get isExpired => _age >= lifetime;
  bool get isSpent => _remainingHits <= 0;
  int get remainingPierces => (_remainingHits - 1).clamp(0, pierce).toInt();

  bool registerHit(EnemyComponent enemy) {
    if (isSpent || !_hitEnemies.add(enemy)) {
      return false;
    }

    _remainingHits -= 1;
    return true;
  }

  @override
  void onLoad() {
    super.onLoad();
    unawaited(_loadEffect());
  }

  Future<void> _loadEffect() async {
    _effectImage = await WeaponEffectAtlas.load(this);
  }

  bool overlapsEnemy(EnemyComponent enemy) {
    final hitRadius = (size.x + enemy.size.x) / 2;
    return position.distanceToSquared(enemy.position) < hitRadius * hitRadius;
  }

  @override
  void update(double dt) {
    super.update(dt);

    _age += dt;
    position.add(velocity * dt);
    if (isExpired || isSpent) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final image = _effectImage;
    final row = WeaponEffectAtlas.rowForWeapon(weaponId);
    if (image != null && row != null) {
      final visualExtent = isMasterLead
          ? 52.0
          : followUpIndex > 0
          ? 36.0
          : 28.0;
      final visualSize = Vector2.all(visualExtent);
      final center = Offset(size.x / 2, size.y / 2);
      final facingAngle = math.atan2(velocity.y, velocity.x);
      final sprite = WeaponEffectAtlas.sprite(
        image,
        row: row,
        frame: ((_age / 0.08).floor()) % WeaponEffectAtlas.framesPerEffect,
      );
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..rotate(facingAngle);
      sprite.render(
        canvas,
        position: Vector2(-visualSize.x / 2, -visualSize.y / 2),
        size: visualSize,
      );
      canvas.restore();
      return;
    }

    final theme = weaponVisualThemeFor(weaponId);
    final center = Offset(size.x / 2, size.y / 2);
    final direction = velocity.length2 == 0
        ? Vector2(1, 0)
        : velocity.normalized();
    final trailLength = size.x * (isMasterLead ? theme.masterScale : 1.25);
    canvas.drawLine(
      center,
      center - Offset(direction.x, direction.y) * trailLength,
      Paint()
        ..color = theme.accent.withValues(alpha: .72)
        ..strokeWidth = theme.trailWidth
        ..strokeCap = StrokeCap.round,
    );
    if (isMasterLead) {
      canvas.drawCircle(
        center,
        size.x * .9,
        Paint()..color = theme.primary.withValues(alpha: .22),
      );
    }
    final paint = Paint()..color = theme.primary;
    final outlinePaint = Paint()
      ..color = const Color(0xff2f1b25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final rect = Offset.zero & Size(size.x, size.y);
    if (weaponId == 'hawk_summon') {
      final path = Path()
        ..moveTo(size.x, size.y / 2)
        ..lineTo(0, 0)
        ..lineTo(size.x * .28, size.y / 2)
        ..lineTo(0, size.y)
        ..close();
      canvas.drawPath(path, paint);
      canvas.drawPath(path, outlinePaint);
      return;
    }
    if (weaponId == 'matchlock_cannon') {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(size.y / 2)),
        paint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(size.y / 2)),
        outlinePaint,
      );
      return;
    }
    canvas.drawOval(rect, paint);
    canvas.drawOval(rect, outlinePaint);
  }
}
