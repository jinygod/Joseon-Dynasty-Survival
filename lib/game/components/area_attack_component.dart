import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../combat/attack_spec.dart';
import '../content/combat_effect_atlas.dart';
import '../content/ids.dart';
import '../content/weapon_effect_atlas.dart';
import '../models/damage_event.dart';
import 'enemy_component.dart';
import 'player_component.dart';

class AreaAttackComponent extends PositionComponent {
  AreaAttackComponent({
    required this.damage,
    required this.radius,
    required this.delaySeconds,
    required this.knockback,
    required Vector2 position,
    this.weaponId,
    Vector2? direction,
    this.angleRadians = math.pi * 2,
    this.isBossAttack = false,
  }) : direction = _normalizedDirection(direction ?? Vector2(1, 0)),
       super(
         position: position,
         size: Vector2.all(radius * 2),
         anchor: Anchor.center,
       );

  final WeaponId? weaponId;
  final double damage;
  final double radius;
  final double delaySeconds;
  final double knockback;
  final Vector2 direction;
  final double angleRadians;
  final bool isBossAttack;

  double _elapsed = 0;
  bool _hasTriggered = false;
  Image? _effectImage;
  Image? _combatEffectImage;

  bool get isReady => _elapsed >= delaySeconds;
  bool get hasTriggered => _hasTriggered;

  @override
  void onLoad() {
    super.onLoad();
    if (weaponId == 'thunder_crash_bomb') {
      unawaited(_loadEffect());
    }
    if (isBossAttack) {
      unawaited(_loadCombatEffect());
    }
  }

  Future<void> _loadEffect() async {
    _effectImage = await WeaponEffectAtlas.load(this);
  }

  Future<void> _loadCombatEffect() async {
    _combatEffectImage = await CombatEffectAtlas.load(this);
  }

  List<DamageEvent> collectDamageEvents(Iterable<EnemyComponent> enemies) {
    if (!isReady || _hasTriggered) {
      return const [];
    }

    _hasTriggered = true;
    return [
      for (final enemy in enemies)
        if (!enemy.isDead && containsEnemy(enemy))
          DamageEvent(
            target: enemy,
            damage: damage,
            knockback: knockback,
            direction: _directionTo(enemy.position),
            weaponId: weaponId,
            traits: const {AttackTrait.explosion},
          ),
    ];
  }

  bool containsEnemy(EnemyComponent enemy) {
    return _containsCircle(enemy.position, enemy.size.x / 2);
  }

  bool containsPlayer(PlayerComponent player) {
    return _containsCircle(player.position, player.size.x / 2);
  }

  bool _containsCircle(Vector2 center, double targetRadius) {
    final offset = center - position;
    final hitRange = radius + targetRadius;
    if (offset.length2 > hitRange * hitRange) {
      return false;
    }
    if (offset.length2 == 0 || angleRadians >= math.pi * 2) {
      return true;
    }

    offset.normalize();
    return direction.dot(offset) >= math.cos(angleRadians / 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_hasTriggered && _elapsed >= delaySeconds + 0.12) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final center = Offset(size.x / 2, size.y / 2);
    final combatImage = _combatEffectImage;
    if (combatImage != null && isBossAttack && !_hasTriggered) {
      final progress = delaySeconds <= 0 ? 1.0 : _elapsed / delaySeconds;
      CombatEffectAtlas.sprite(
        combatImage,
        kind: CombatEffectKind.warning,
        frame: CombatEffectAtlas.frameForProgress(progress),
      ).render(canvas, size: size);
      return;
    }
    final image = _effectImage;
    if (image != null && weaponId == 'thunder_crash_bomb') {
      final progress = delaySeconds <= 0 ? 1.0 : _elapsed / delaySeconds;
      final frame = _hasTriggered
          ? 2 + ((_elapsed - delaySeconds) / 0.06).floor().clamp(0, 1)
          : WeaponEffectAtlas.frameForProgress(progress).clamp(0, 1);
      final visualExtent = _hasTriggered ? radius * 2 : 32.0;
      WeaponEffectAtlas.sprite(
        image,
        row: WeaponEffectAtlas.bombRow,
        frame: frame,
      ).render(
        canvas,
        position: Vector2(
          center.dx - visualExtent / 2,
          center.dy - visualExtent / 2,
        ),
        size: Vector2.all(visualExtent),
      );
      return;
    }
    final paint = Paint()
      ..color = (_hasTriggered
          ? const Color(0xffffb703)
          : const Color(0xffe63946).withValues(alpha: 0.38))
      ..style = _hasTriggered ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 2;
    if (angleRadians >= math.pi * 2) {
      canvas.drawCircle(center, radius, paint);
      return;
    }

    final facingAngle = math.atan2(direction.y, direction.x);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      facingAngle - angleRadians / 2,
      angleRadians,
      true,
      paint,
    );
  }

  Vector2 _directionTo(Vector2 target) {
    final result = target - position;
    if (result.length2 == 0) {
      return direction.clone();
    }
    return result..normalize();
  }

  static Vector2 _normalizedDirection(Vector2 direction) {
    final result = direction.clone();
    if (result.length2 == 0) {
      result.setValues(1, 0);
    } else {
      result.normalize();
    }
    return result;
  }
}
