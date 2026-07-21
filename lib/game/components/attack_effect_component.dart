import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../combat/attack_spec.dart';
import 'talisman_presentation_component.dart';

class AttackEffectComponent extends PositionComponent {
  AttackEffectComponent({required this.instance, this.onExpired})
    : super(
        position: instance.origin,
        priority: AttackPresentationPriority.attack,
      );

  final AttackInstance instance;
  final void Function()? onExpired;
  static const synergySlashColor = Color(0xffffd166);
  static const synergyFragmentColors = <Color>[
    Color(0xff3b82f6),
    Color(0xffef4444),
    Color(0xfffacc15),
    Color(0xfff8fafc),
    Color(0xff111827),
  ];
  double _age = 0;
  bool _expired = false;

  double get _lifetime =>
      instance.spec.activeSeconds + instance.spec.lingerSeconds;

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
    super.render(canvas);
    final spec = instance.spec;
    final direction = instance.direction;
    final heading = math.atan2(direction.y, direction.x);
    final progress = (_age / _lifetime).clamp(0, 1).toDouble();
    final color = switch (spec.presentation) {
      AttackPresentation.master => const Color(0xfff6d365),
      AttackPresentation.strong => const Color(0xffbdf7ff),
      AttackPresentation.synergy => synergySlashColor,
      AttackPresentation.normal => const Color(0xffe8fdff),
    };
    final paint = Paint()
      ..color = color.withValues(alpha: .85 * (1 - progress))
      ..style = PaintingStyle.stroke
      ..strokeWidth =
          spec.presentation == AttackPresentation.master ||
              spec.presentation == AttackPresentation.synergy
          ? 5
          : 3
      ..strokeCap = StrokeCap.round;

    switch (spec.shape) {
      case AttackShape.sector:
        final path = Path()..moveTo(0, 0);
        path.arcTo(
          Rect.fromCircle(center: Offset.zero, radius: spec.range),
          heading - spec.angleRadians / 2,
          spec.angleRadians,
          false,
        );
        path.close();
        canvas.drawPath(path, paint);
      case AttackShape.circle:
        canvas.drawCircle(Offset.zero, spec.radius, paint);
        if (spec.presentation == AttackPresentation.synergy) {
          _drawSynergyFragments(canvas, spec.radius, progress);
        }
      case AttackShape.line:
        canvas.drawLine(
          Offset.zero,
          Offset(direction.x * spec.range, direction.y * spec.range),
          paint..strokeWidth = math.max(spec.width, paint.strokeWidth),
        );
    }
  }

  void _drawSynergyFragments(Canvas canvas, double radius, double progress) {
    final innerRadius = radius * .62;
    final outerRadius = radius * .88;
    for (var index = 0; index < synergyFragmentColors.length; index += 1) {
      final angle = -math.pi / 2 + index * math.pi * 2 / 5;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        direction * innerRadius,
        direction * outerRadius,
        Paint()
          ..color = synergyFragmentColors[index].withValues(
            alpha: .9 * (1 - progress),
          )
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
  }
}
