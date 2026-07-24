import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../combat/attack_presentation_contract.dart';
import '../combat/attack_timeline.dart';
import '../combat/combat_contact.dart';

class CombatGeometryDebugComponent extends PositionComponent {
  CombatGeometryDebugComponent({
    required this.contract,
    required Vector2 targetCenter,
    required this.targetRadius,
    required CombatContact contact,
  }) : _targetCenter = targetCenter.clone(),
       _contactPoint = contact.point,
       super(position: contract.visualSector.origin, priority: 1000);

  final AttackPresentationContract contract;
  final Vector2 _targetCenter;
  final double targetRadius;
  final Vector2 _contactPoint;

  bool showVisualBounds = false;
  bool showHitbox = false;
  bool showHurtbox = false;
  bool showContactPoint = false;
  AttackPhase phase = AttackPhase.windup;
  int remainingMilliseconds = 0;

  double get visualRadius => contract.visualSector.radius;
  double get hitRadius => contract.hitSector.radius;
  Vector2 get targetCenter => _targetCenter.clone();
  Vector2 get contactPoint => _contactPoint.clone();

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final direction = contract.visualSector.direction;
    final angle = math.atan2(direction.y, direction.x);

    canvas.save();
    canvas.rotate(angle);
    if (showVisualBounds) {
      canvas.drawPath(
        _sectorPath(
          contract.visualSector.radius,
          contract.visualSector.angleRadians,
        ),
        _stroke(const Color(0xff5ee8ff)),
      );
    }
    if (showHitbox) {
      canvas.drawPath(
        _sectorPath(contract.hitSector.radius, contract.hitSector.angleRadians),
        _stroke(
          phase == AttackPhase.active
              ? const Color(0xffe84b3c)
              : const Color(0x99d7ad45),
        ),
      );
    }
    canvas.restore();

    if (showHurtbox) {
      canvas.drawCircle(
        (_targetCenter - position).toOffset(),
        targetRadius,
        _stroke(const Color(0xfff4ead2)),
      );
    }
    if (showContactPoint) {
      final point = _contactPoint - position;
      final paint = _stroke(const Color(0xffff4fd8))..strokeWidth = 2;
      canvas.drawLine(
        Offset(point.x - 5, point.y),
        Offset(point.x + 5, point.y),
        paint,
      );
      canvas.drawLine(
        Offset(point.x, point.y - 5),
        Offset(point.x, point.y + 5),
        paint,
      );
    }
    _renderLabel(canvas);
  }

  void _renderLabel(Canvas canvas) {
    final painter = TextPainter(
      text: TextSpan(
        text: '${phase.name} ${remainingMilliseconds}ms',
        style: const TextStyle(
          color: Color(0xfff4ead2),
          fontSize: 12,
          backgroundColor: Color(0xaa101923),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, const Offset(8, -24));
  }
}

Paint _stroke(Color color) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 1.5
  ..color = color;

Path _sectorPath(double radius, double angleRadians) {
  final start = -angleRadians / 2;
  return Path()
    ..moveTo(0, 0)
    ..lineTo(math.cos(start) * radius, math.sin(start) * radius)
    ..arcTo(
      Rect.fromCircle(center: Offset.zero, radius: radius),
      start,
      angleRadians,
      false,
    )
    ..close();
}
