import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../systems/talisman_executor.dart';

abstract final class AttackPresentationPriority {
  static const attack = 89;
  static const attachment = 92;
  static const warning = 120;
}

class TalismanAttachmentComponent extends PositionComponent {
  TalismanAttachmentComponent({required this.seal})
    : super(
        size: Vector2(14, 18),
        anchor: Anchor.center,
        priority: AttackPresentationPriority.attachment,
      );

  final AttachedTalisman seal;

  @override
  void update(double dt) {
    super.update(dt);
    final target = seal.target;
    position.setValues(
      target.position.x,
      target.position.y - target.size.y / 2 - 7,
    );
  }

  @override
  void render(Canvas canvas) {
    final paper = RRect.fromRectAndRadius(
      Offset.zero & Size(size.x, size.y),
      const Radius.circular(1),
    );
    canvas.drawRRect(
      paper,
      Paint()..color = const Color(0xfffff1b8).withValues(alpha: .84),
    );
    canvas.drawRRect(
      paper,
      Paint()
        ..color = const Color(0xffd1495b).withValues(alpha: .84)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final ink = Paint()
      ..color =
          (seal.isCritical ? const Color(0xffffd166) : const Color(0xffb4232f))
              .withValues(alpha: .84)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(Offset(size.x / 2, 3), Offset(size.x / 2, 13), ink)
      ..drawLine(const Offset(3, 6), Offset(size.x - 3, 6), ink)
      ..drawLine(const Offset(3, 10), Offset(size.x - 3, 10), ink);
  }
}

class TalismanTransferCueComponent extends PositionComponent {
  TalismanTransferCueComponent({
    required TalismanTransferCue cue,
    this.onExpired,
  }) : _source = cue.source,
       _target = cue.target,
       super(
         position: cue.source,
         priority: AttackPresentationPriority.attachment,
       );

  static const _lifetime = .2;

  final Vector2 _source;
  final Vector2 _target;
  final void Function()? onExpired;
  double _age = 0;
  bool _expired = false;

  Vector2 get source => _source.clone();
  Vector2 get target => _target.clone();
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
    final delta = _target - _source;
    canvas.drawLine(
      Offset.zero,
      Offset(delta.x, delta.y),
      Paint()
        ..color = const Color(
          0xffffd166,
        ).withValues(alpha: .45 * (1 - progress))
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    final paperCenter = Offset(delta.x, delta.y) * progress;
    canvas.save();
    canvas.translate(paperCenter.dx, paperCenter.dy);
    canvas.rotate(math.atan2(delta.y, delta.x) + progress * .8);
    final paper = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-3, -6, 6, 12),
      const Radius.circular(1),
    );
    canvas.drawRRect(
      paper,
      Paint()
        ..color = const Color(
          0xfffff1b8,
        ).withValues(alpha: .84 * (1 - progress)),
    );
    canvas.drawLine(
      const Offset(0, -4),
      const Offset(0, 4),
      Paint()
        ..color = const Color(
          0xffd1495b,
        ).withValues(alpha: .84 * (1 - progress))
        ..strokeWidth = 1.4,
    );
    canvas.restore();
    canvas.drawCircle(
      Offset(delta.x, delta.y),
      3 + progress * 2,
      Paint()
        ..color = const Color(0xffd1495b).withValues(alpha: .8 * (1 - progress))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
}
