import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../combat/combat_vfx_primitives.dart';
import '../content/ids.dart';
import 'enemy_component.dart';
import 'talisman_presentation_component.dart';

abstract final class EnemyCombatOverlayStyle {
  static const warningAlpha = .32;
  static const warningStrokeWidth = 2.0;
  static const shieldSweepRadians = math.pi / 2;
  static const laneHalfWidth = 10.0;
  static const laneChevronCount = 6;
  static const reticleRingCount = 3;
  static const shieldPlateCount = 3;
  static const usesFullBodyRectangle = false;
}

const _warningPalette = CombatVfxPalette(
  core: Color(0xfffff4d6),
  edge: Color(0xffff476f),
  accent: Color(0xffffc857),
  smoke: Color(0xff5a2230),
);

class EnemyWarningOverlayComponent extends PositionComponent {
  EnemyWarningOverlayComponent({required this.enemy, int? stableOrder})
    : stableOrder = stableOrder ?? _nextStableOrder++,
      super(
        position: enemy.position,
        size: enemy.size.clone(),
        anchor: Anchor.center,
        priority: AttackPresentationPriority.warning,
      );

  final EnemyComponent enemy;
  static int _nextStableOrder = 0;
  final int stableOrder;
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
        final id = left.enemy.enemyId.compareTo(right.enemy.enemyId);
        if (id != 0) return id;
        return left.stableOrder.compareTo(right.stableOrder);
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
      ..color = _warningPalette.edge.withValues(alpha: _warningAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = EnemyCombatOverlayStyle.warningStrokeWidth
      ..strokeCap = StrokeCap.round;
    final center = Offset(size.x / 2, size.y / 2);
    if (enemy.hasDirectionalShield) {
      _drawShieldArc(canvas, center, enemy.shieldDirection, paint);
      _drawShieldPlates(canvas, center, enemy.shieldDirection);
    }
    if (warning == null) return;
    if (warning.kind == EnemyBehaviorKind.shockwave ||
        warning.kind == EnemyBehaviorKind.scream) {
      canvas.drawCircle(center, warning.range, paint);
      return;
    }
    final direction = warning.direction;
    final endpoint =
        warning.telegraphEndpoint ?? enemy.position + direction * warning.range;
    switch (warning.kind) {
      case EnemyBehaviorKind.dash:
      case EnemyBehaviorKind.dive:
      case EnemyBehaviorKind.doubleDash:
      case EnemyBehaviorKind.thrust:
        _drawDirectionStrip(canvas, center, endpoint);
      case EnemyBehaviorKind.ranged:
        _drawRangedTarget(canvas, center, endpoint, warning.progress, paint);
      default:
        _drawDirectionStrip(canvas, center, endpoint);
    }
  }

  void _drawDirectionStrip(Canvas canvas, Offset center, Vector2 endpoint) {
    final endpointOffset = endpoint - enemy.position;
    final target = center + Offset(endpointOffset.x, endpointOffset.y);
    CombatVfxPrimitives.drawChevronLane(
      canvas,
      start: center,
      end: target,
      halfWidth: EnemyCombatOverlayStyle.laneHalfWidth,
      palette: _warningPalette,
      progress: 1 - _warningAlpha / EnemyCombatOverlayStyle.warningAlpha,
      count: EnemyCombatOverlayStyle.laneChevronCount,
    );
    final delta = target - center;
    final length = delta.distance;
    if (length <= .001) return;
    final normal = Offset(-delta.dy / length, delta.dx / length);
    final border = Paint()
      ..color = _warningPalette.core.withValues(alpha: _warningAlpha * .86)
      ..style = PaintingStyle.stroke
      ..strokeWidth = EnemyCombatOverlayStyle.warningStrokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center + normal * EnemyCombatOverlayStyle.laneHalfWidth,
      target + normal * EnemyCombatOverlayStyle.laneHalfWidth,
      border,
    );
    canvas.drawLine(
      center - normal * EnemyCombatOverlayStyle.laneHalfWidth,
      target - normal * EnemyCombatOverlayStyle.laneHalfWidth,
      border,
    );
  }

  void _drawRangedTarget(
    Canvas canvas,
    Offset center,
    Vector2 endpoint,
    double progress,
    Paint paint,
  ) {
    final endpointOffset = endpoint - enemy.position;
    final target = center + Offset(endpointOffset.x, endpointOffset.y);
    final pulse = 1 + progress * .22;
    for (
      var index = 0;
      index < EnemyCombatOverlayStyle.reticleRingCount;
      index += 1
    ) {
      canvas.drawCircle(
        target,
        (5 + index * 4) * pulse,
        Paint()
          ..color = (index == 1 ? _warningPalette.accent : _warningPalette.core)
              .withValues(alpha: _warningAlpha * (1 - index * .16))
          ..style = PaintingStyle.stroke
          ..strokeWidth = index == 1 ? 2.2 : 1.4,
      );
    }
    final reticleSize = 12 * pulse;
    final reticlePaint = Paint()
      ..color = _warningPalette.edge.withValues(alpha: _warningAlpha)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(target.dx - reticleSize, target.dy),
      Offset(target.dx + reticleSize, target.dy),
      reticlePaint,
    );
    canvas.drawLine(
      Offset(target.dx, target.dy - reticleSize),
      Offset(target.dx, target.dy + reticleSize),
      reticlePaint,
    );
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

  void _drawShieldPlates(Canvas canvas, Offset center, Vector2 direction) {
    final angle = math.atan2(direction.y, direction.x);
    final radius = size.x * .72;
    for (
      var index = 0;
      index < EnemyCombatOverlayStyle.shieldPlateCount;
      index += 1
    ) {
      final fraction = EnemyCombatOverlayStyle.shieldPlateCount == 1
          ? .5
          : index / (EnemyCombatOverlayStyle.shieldPlateCount - 1);
      final plateAngle =
          angle -
          EnemyCombatOverlayStyle.shieldSweepRadians / 2 +
          EnemyCombatOverlayStyle.shieldSweepRadians * fraction;
      final facing = Offset(math.cos(plateAngle), math.sin(plateAngle));
      final tangent = Offset(-facing.dy, facing.dx);
      final point = center + facing * radius;
      final plate = Path()
        ..moveTo(
          point.dx + tangent.dx * 5 - facing.dx * 4,
          point.dy + tangent.dy * 5 - facing.dy * 4,
        )
        ..lineTo(point.dx + facing.dx * 6, point.dy + facing.dy * 6)
        ..lineTo(
          point.dx - tangent.dx * 5 - facing.dx * 4,
          point.dy - tangent.dy * 5 - facing.dy * 4,
        )
        ..close();
      canvas.drawPath(
        plate,
        Paint()..color = const Color(0xffbde0fe).withValues(alpha: .52),
      );
    }
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
