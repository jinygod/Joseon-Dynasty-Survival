import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../combat/combat_vfx_primitives.dart';
import 'enemy_component.dart';
import '../content/ids.dart';
import '../combat/attack_spec.dart';
import '../combat/attack_visual_event.dart';
import '../content/combat_visual_factory.dart';
import '../content/attack_visual_registry.dart';
import '../content/weapon_definitions.dart';
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
    CombatVisualFactory? visualFactory,
    Image? legacyEffectImage,
  }) : _remainingHits = pierce + 1,
       super(
         position: position,
         size: size ?? Vector2.all(8),
         anchor: Anchor.center,
       ) {
    _effectImage = legacyEffectImage;
    if (visualFactory != null && weaponId == singijeonVolley) {
      _attachRegistryVisual(visualFactory);
    }
  }

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
  bool _usesRegistryVisual = false;
  bool _hasRegistrySprite = false;
  PositionComponent? _registryVisual;

  bool get isExpired => _age >= lifetime;
  bool get isSpent => _remainingHits <= 0;
  int get remainingPierces => (_remainingHits - 1).clamp(0, pierce).toInt();
  CombatVfxTier get visualTier => tier;
  WeaponVfxFamily get vfxFamily => weaponVisualThemeFor(weaponId).family;
  bool get usesRegistryVisual => _usesRegistryVisual;
  bool get startsImageLoadOnMount => false;

  /// The registry presentation delegate never resolves damage.
  bool get ownsDamageResolution => false;

  /// This outer gameplay component continues to resolve projectile hits.
  bool get gameplayOwnsDamageResolution => true;
  Vector2? get registryVisualLocalPosition => _registryVisual?.position.clone();
  Vector2? get registryVisualScale => _registryVisual?.scale.clone();

  void attachVisuals({
    required CombatVisualFactory visualFactory,
    Image? legacyEffectImage,
  }) {
    _effectImage ??= legacyEffectImage;
    if (weaponId == singijeonVolley && !_usesRegistryVisual) {
      _attachRegistryVisual(visualFactory);
    }
  }

  void _attachRegistryVisual(CombatVisualFactory visualFactory) {
    _usesRegistryVisual = true;
    _hasRegistrySprite = AttackVisualRegistry.byId(
      singijeonVolley,
    ).layers.any((layer) => visualFactory.images.containsKey(layer.assetKey));
    final visual =
        visualFactory.create(
            AttackVisualEvent.fromAttack(
              AttackInstance(
                spec: AttackSpec(
                  id: singijeonVolley,
                  shape: AttackShape.line,
                  damage: 0,
                  range: 0,
                  angleRadians: 0,
                  radius: 0,
                  width: 0,
                  windupSeconds: 0,
                  activeSeconds: lifetime,
                  lingerSeconds: 0,
                  knockback: 0,
                  slowFraction: 0,
                  traits: const {},
                  presentation: AttackPresentation.normal,
                ),
                origin: Vector2.zero(),
                direction: velocity,
                sequenceIndex: 0,
              ),
            ),
          )
          ..position = size / 2
          ..scale = Vector2.all(28 / 128);
    _registryVisual = visual;
    add(visual);
  }

  bool registerHit(EnemyComponent enemy) {
    if (isSpent || !_hitEnemies.add(enemy)) {
      return false;
    }

    _remainingHits -= 1;
    return true;
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

    if (_hasRegistrySprite) return;

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
