import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import 'enemy_component.dart';
import '../content/ids.dart';
import '../content/weapon_effect_atlas.dart';

class ProjectileComponent extends PositionComponent {
  ProjectileComponent({
    required this.weaponId,
    required this.damage,
    required Vector2 position,
    required this.velocity,
    this.lifetime = 2.2,
    this.pierce = 0,
    this.knockback = 0,
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
      final visualSize = Vector2(28, 28);
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
