import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../content/ids.dart';
import 'enemy_component.dart';
import 'talisman_presentation_component.dart';

abstract final class EnemyCombatOverlayStyle {
  static const warningAlpha = .32;
  static const warningStrokeWidth = 2.0;
  static const shieldSweepRadians = math.pi / 2;
  static const usesFullBodyRectangle = false;
}

class EnemyWarningOverlayComponent extends PositionComponent {
  EnemyWarningOverlayComponent({required this.enemy})
    : super(
        position: enemy.position,
        size: enemy.size.clone(),
        anchor: Anchor.center,
        priority: AttackPresentationPriority.warning,
      );

  final EnemyComponent enemy;
  double _warningAlpha = EnemyCombatOverlayStyle.warningAlpha;

  double get warningAlpha => _warningAlpha;

  static void rankByDistance(
    Iterable<EnemyWarningOverlayComponent> overlays, {
    required Vector2 playerPosition,
  }) {
    final ranked = overlays.toList()
      ..sort((left, right) {
        final distance = left.enemy.position
            .distanceToSquared(playerPosition)
            .compareTo(right.enemy.position.distanceToSquared(playerPosition));
        if (distance != 0) return distance;
        final x = left.enemy.position.x.compareTo(right.enemy.position.x);
        if (x != 0) return x;
        final y = left.enemy.position.y.compareTo(right.enemy.position.y);
        if (y != 0) return y;
        return left.enemy.enemyId.compareTo(right.enemy.enemyId);
      });
    for (var index = 0; index < ranked.length; index += 1) {
      ranked[index]._warningAlpha =
          EnemyCombatOverlayStyle.warningAlpha * (index < 8 ? 1 : .5);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    position.setFrom(enemy.position);
    size.setFrom(enemy.size);
  }

  @override
  void render(Canvas canvas) {
    final warning = enemy.warningSnapshot;
    final paint = Paint()
      ..color = const Color(0xffff476f).withValues(alpha: _warningAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = EnemyCombatOverlayStyle.warningStrokeWidth
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.x / 2, size.y / 2);
    if (enemy.hasDirectionalShield) {
      _drawShieldArc(canvas, center, enemy.shieldDirection, paint);
    }
    if (warning == null) return;
    if (warning.kind == EnemyBehaviorKind.shockwave ||
        warning.kind == EnemyBehaviorKind.scream) {
      canvas.drawCircle(center, warning.range, paint);
      return;
    }
    final direction = warning.direction;
    switch (warning.kind) {
      case EnemyBehaviorKind.dash:
      case EnemyBehaviorKind.dive:
      case EnemyBehaviorKind.doubleDash:
      case EnemyBehaviorKind.thrust:
        _drawDirectionStrip(canvas, center, direction, warning.range, paint);
      case EnemyBehaviorKind.ranged:
        _drawRangedTarget(
          canvas,
          center,
          direction,
          warning.range,
          warning.progress,
          paint,
        );
      default:
        _drawDirectionStrip(canvas, center, direction, warning.range, paint);
    }
  }

  void _drawDirectionStrip(
    Canvas canvas,
    Offset center,
    Vector2 direction,
    double range,
    Paint paint,
  ) {
    final length = range.clamp(24, 72).toDouble();
    final start = center + Offset(direction.x, direction.y) * (size.x * .45);
    canvas.drawLine(
      start,
      start + Offset(direction.x, direction.y) * length,
      paint,
    );
  }

  void _drawRangedTarget(
    Canvas canvas,
    Offset center,
    Vector2 direction,
    double range,
    double progress,
    Paint paint,
  ) {
    final targetDistance = (range * .16).clamp(24, 72).toDouble();
    final target = center + Offset(direction.x, direction.y) * targetDistance;
    canvas.drawCircle(target, 5 + progress * 3, paint);
  }

  void _drawShieldArc(
    Canvas canvas,
    Offset center,
    Vector2 direction,
    Paint paint,
  ) {
    final angle = math.atan2(direction.y, direction.x);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.x * .72),
      angle - EnemyCombatOverlayStyle.shieldSweepRadians / 2,
      EnemyCombatOverlayStyle.shieldSweepRadians,
      false,
      paint,
    );
  }
}

class ShieldBlockEffectComponent extends PositionComponent {
  ShieldBlockEffectComponent({
    required Vector2 position,
    required Vector2 facingDirection,
    this.onExpired,
  }) : _facingDirection = _unit(facingDirection),
       super(
         position: position,
         size: Vector2.all(44),
         anchor: Anchor.center,
         priority: AttackPresentationPriority.attachment,
       );

  static const _lifetime = .22;

  final Vector2 _facingDirection;
  final void Function()? onExpired;
  double _age = 0;
  bool _expired = false;

  Vector2 get facingDirection => _facingDirection.clone();
  double get lifetime => _lifetime;

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (!_expired && _age >= _lifetime) {
      _expired = true;
      onExpired?.call();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final progress = (_age / _lifetime).clamp(0, 1).toDouble();
    final angle = math.atan2(_facingDirection.y, _facingDirection.x);
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(22, 22), radius: 17 + progress * 4),
      angle - EnemyCombatOverlayStyle.shieldSweepRadians / 2,
      EnemyCombatOverlayStyle.shieldSweepRadians,
      false,
      Paint()
        ..color = const Color(0xffe0fbfc).withValues(alpha: 1 - progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 * (1 - progress) + 1
        ..strokeCap = StrokeCap.round,
    );
  }
}

Vector2 _unit(Vector2 direction) {
  if (direction.length2 == 0) return Vector2(1, 0);
  return direction.clone()..normalize();
}
