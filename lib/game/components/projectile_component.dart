import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../combat/combat_vfx_primitives.dart';
import '../combat/projectile_contact.dart';
import '../combat/projectile_sweep_geometry.dart';
import '../content/ids.dart';
import '../content/projectile_presentation_spec.dart';
import '../content/weapon_visual_theme.dart';
import 'enemy_component.dart';

class ProjectileTargetContact {
  const ProjectileTargetContact({required this.enemy, required this.contact});

  final EnemyComponent enemy;
  final ProjectileContact contact;
}

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
    this.sizeMultiplier = 1,
    Image? visualImage,
  }) : presentation = ProjectilePresentationSpecs.forWeapon(weaponId),
       _remainingHits = pierce + 1,
       assert(sizeMultiplier > 0),
       super(
         position: position,
         size:
             ProjectilePresentationSpecs.forWeapon(weaponId).renderSize *
             sizeMultiplier,
         anchor: Anchor.center,
       ) {
    _previousPosition = position.clone();
    _visualImage = visualImage;
    _spritePaint = Paint()..filterQuality = presentation.filterQuality;
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
  final double sizeMultiplier;
  final ProjectilePresentationSpec presentation;
  final Set<EnemyComponent> _hitEnemies = {};

  late final Vector2 _previousPosition;
  int _remainingHits;
  double _age = 0;
  Image? _visualImage;
  late final Paint _spritePaint;

  bool get isExpired => _age >= lifetime;
  bool get isSpent => _remainingHits <= 0;
  int get remainingPierces => (_remainingHits - 1).clamp(0, pierce).toInt();
  CombatVfxTier get visualTier => tier;
  WeaponVfxFamily get vfxFamily => weaponVisualThemeFor(weaponId).family;
  Vector2 get previousPosition => _previousPosition.clone();
  Vector2 get visualBodySize => presentation.bodySize * sizeMultiplier;
  Vector2 get hitBodySize => presentation.hitBodySize * sizeMultiplier;
  bool get startsImageLoadOnMount => false;

  /// This presentation component never resolves damage while rendering.
  bool get ownsDamageResolution => false;

  /// The outer gameplay loop remains the only projectile damage owner.
  bool get gameplayOwnsDamageResolution => true;

  void attachVisualImage(Image image) {
    _visualImage = image;
  }

  void synchronizePreviousPosition() {
    _previousPosition.setFrom(position);
  }

  bool registerHit(EnemyComponent enemy) {
    if (isSpent || !_hitEnemies.add(enemy)) {
      return false;
    }

    _remainingHits -= 1;
    return true;
  }

  List<ProjectileTargetContact> contactsFor(Iterable<EnemyComponent> enemies) {
    if (isExpired || isSpent) {
      return const [];
    }
    final contacts = <ProjectileTargetContact>[];
    for (final enemy in enemies) {
      if (enemy.isDead || _hitEnemies.contains(enemy)) {
        continue;
      }
      final contact = ProjectileSweepGeometry.firstContact(
        previousCenter: _previousPosition,
        currentCenter: position,
        direction: velocity,
        hitBodySize: hitBodySize,
        hurtCenter: enemy.position,
        hurtRadius: enemy.hurtRadius,
      );
      if (contact != null) {
        contacts.add(ProjectileTargetContact(enemy: enemy, contact: contact));
      }
    }
    contacts.sort(
      (a, b) => a.contact.travelFraction.compareTo(b.contact.travelFraction),
    );
    return contacts;
  }

  bool overlapsEnemy(EnemyComponent enemy) => contactsFor([enemy]).isNotEmpty;

  @override
  void update(double dt) {
    super.update(dt);

    _previousPosition.setFrom(position);
    _age += dt;
    position.add(velocity * dt);
    if (isExpired || isSpent) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final image = _visualImage;
    if (image == null) {
      return;
    }
    final frame =
        ((_age / presentation.frameSeconds).floor()) % presentation.frameCount;
    final sprite = Sprite(
      image,
      srcPosition: Vector2(
        frame * presentation.frameSize,
        presentation.atlasRow * presentation.frameSize,
      ),
      srcSize: Vector2.all(presentation.frameSize),
    );
    final center = Offset(size.x / 2, size.y / 2);
    final facingAngle = presentation.rotateWithVelocity
        ? math.atan2(velocity.y, velocity.x) + presentation.assetForwardAngle
        : presentation.assetForwardAngle;
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(facingAngle);
    sprite.render(
      canvas,
      position: -size / 2,
      size: size,
      overridePaint: _spritePaint,
    );
    canvas.restore();
  }
}
