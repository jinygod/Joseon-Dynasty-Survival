import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../content/ids.dart';
import 'enemy_component.dart';
import 'talisman_presentation_component.dart';
import '../content/combat_visual_factory.dart';

class EnemyWarningOverlayComponent extends PositionComponent {
  EnemyWarningOverlayComponent({required this.enemy, this.visualFactory})
    : super(
        position: enemy.position,
        size: enemy.size.clone(),
        anchor: Anchor.center,
        priority: AttackPresentationPriority.warning,
      );

  final EnemyComponent enemy;
  final CombatVisualFactory? visualFactory;
  bool get usesRegistryVisual => false;
  bool get startsImageLoadOnMount => false;
  bool get ownsDamageResolution => false;

  @override
  void update(double dt) {
    super.update(dt);
    position.setFrom(enemy.position);
    size.setFrom(enemy.size);
  }

  @override
  void render(Canvas canvas) {
    final warning = enemy.warningSnapshot;
    if (warning == null) return;
    final paint = Paint()
      ..color = const Color(0xd9ff476f)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final center = Offset(size.x / 2, size.y / 2);
    if (warning.kind == EnemyBehaviorKind.shockwave ||
        warning.kind == EnemyBehaviorKind.scream) {
      canvas.drawCircle(center, warning.range, paint);
      return;
    }
    final direction = warning.direction;
    canvas.drawLine(
      center,
      center + Offset(direction.x, direction.y) * warning.range,
      paint,
    );
    if (warning.kind == EnemyBehaviorKind.ranged) {
      canvas.drawCircle(center, 4 + warning.progress * 10, paint);
    }
  }
}

class ShieldBlockEffectComponent extends PositionComponent {
  ShieldBlockEffectComponent({
    required Vector2 position,
    required Vector2 facingDirection,
    this.onExpired,
    this.visualFactory,
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
  final CombatVisualFactory? visualFactory;
  double _age = 0;
  bool _expired = false;

  Vector2 get facingDirection => _facingDirection.clone();
  double get lifetime => _lifetime;
  bool get usesRegistryVisual => false;
  bool get startsImageLoadOnMount => false;
  bool get ownsDamageResolution => false;

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
      angle - math.pi / 3,
      math.pi * 2 / 3,
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
