import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../combat/combat_vfx_primitives.dart';
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
    this.tier = CombatVfxTier.normal,
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
  final CombatVfxTier tier;
  final Set<EnemyComponent> _hitEnemies = {};
  int _remainingHits;
  double _age = 0;
  Image? _effectImage;

  bool get isExpired => _age >= lifetime;
  bool get isSpent => _remainingHits <= 0;
  int get remainingPierces => (_remainingHits - 1).clamp(0, pierce).toInt();
  CombatVfxTier get visualTier => tier;
  WeaponVfxFamily get vfxFamily => weaponVisualThemeFor(weaponId).family;

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

    final theme = weaponVisualThemeFor(weaponId);
    final center = Offset(size.x / 2, size.y / 2);
    final direction = velocity.length2 == 0
        ? Vector2(1, 0)
        : velocity.normalized();
    final heading = math.atan2(direction.y, direction.x);
    final scale = theme.scaleFor(tier);
    final trailLength = size.x * (isMasterLead ? theme.masterScale : 1.5);
    final trailEnd = center - Offset(direction.x, direction.y) * trailLength;
    CombatVfxPrimitives.drawTaperedTrail(
      canvas,
      start: trailEnd,
      end: center,
      startWidth: math.max(1, theme.trailWidth * .18),
      endWidth: math.max(2, theme.trailWidth * .72),
      palette: theme.palette,
      progress: (_age / lifetime).clamp(0, 1).toDouble(),
      count: theme.trailCountFor(tier),
      tier: tier,
    );
    if (theme.family == WeaponVfxFamily.singijeonRocket ||
        theme.family == WeaponVfxFamily.matchlockShot) {
      CombatVfxPrimitives.drawSmokePuff(
        canvas,
        center: trailEnd,
        radius: math.max(4, size.x * .7),
        palette: theme.palette,
        progress: (_age / lifetime).clamp(0, 1).toDouble(),
        count: tier == CombatVfxTier.master ? 5 : 3,
      );
    }

    final image = _effectImage;
    final row = WeaponEffectAtlas.rowForWeapon(weaponId);
    if (image != null && row != null) {
      final visualExtent = isMasterLead
          ? 52.0
          : followUpIndex > 0
          ? 36.0
          : 28.0;
      final visualSize = Vector2.all(visualExtent);
      final sprite = WeaponEffectAtlas.sprite(
        image,
        row: row,
        frame: ((_age / 0.08).floor()) % WeaponEffectAtlas.framesPerEffect,
      );
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..rotate(heading);
      sprite.render(
        canvas,
        position: Vector2(-visualSize.x / 2, -visualSize.y / 2),
        size: visualSize,
      );
      canvas.restore();
    }

    if (isMasterLead) {
      canvas.drawCircle(
        center,
        size.x * .9,
        Paint()..color = theme.primary.withValues(alpha: .22),
      );
    }
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(heading);
    final halfWidth = size.x * .5 * scale;
    final halfHeight = size.y * .5 * scale;
    final paint = Paint()..color = theme.primary.withValues(alpha: .92);
    final outlinePaint = Paint()
      ..color = theme.accent.withValues(alpha: .95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final silhouette = switch (theme.family) {
      WeaponVfxFamily.hawkFlight =>
        Path()
          ..moveTo(halfWidth, 0)
          ..lineTo(-halfWidth, -halfHeight)
          ..lineTo(-halfWidth * .35, 0)
          ..lineTo(-halfWidth, halfHeight)
          ..lineTo(0, halfHeight * .35)
          ..close(),
      WeaponVfxFamily.singijeonRocket =>
        Path()
          ..moveTo(halfWidth, 0)
          ..lineTo(-halfWidth * .42, -halfHeight * .72)
          ..lineTo(-halfWidth, -halfHeight)
          ..lineTo(-halfWidth * .72, 0)
          ..lineTo(-halfWidth, halfHeight)
          ..lineTo(-halfWidth * .42, halfHeight * .72)
          ..close(),
      WeaponVfxFamily.matchlockShot =>
        Path()
          ..moveTo(halfWidth, 0)
          ..quadraticBezierTo(halfWidth * .72, -halfHeight, 0, -halfHeight)
          ..lineTo(-halfWidth, -halfHeight * .5)
          ..lineTo(-halfWidth, halfHeight * .5)
          ..lineTo(0, halfHeight)
          ..quadraticBezierTo(halfWidth * .72, halfHeight, halfWidth, 0)
          ..close(),
      _ =>
        Path()
          ..moveTo(halfWidth, 0)
          ..lineTo(0, -halfHeight)
          ..lineTo(-halfWidth, 0)
          ..lineTo(0, halfHeight)
          ..close(),
    };
    canvas.drawPath(silhouette, paint);
    canvas.drawPath(silhouette, outlinePaint);
    if (theme.family == WeaponVfxFamily.gakgungArrow) {
      canvas.drawLine(
        Offset(-halfWidth, 0),
        Offset(halfWidth, 0),
        Paint()
          ..color = theme.accent
          ..strokeWidth = math.max(1, theme.trailWidth * .35),
      );
    }
    canvas.restore();
  }
}
