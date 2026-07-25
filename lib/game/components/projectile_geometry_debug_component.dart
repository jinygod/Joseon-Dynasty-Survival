import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../combat/projectile_contact.dart';
import '../content/ids.dart';

class ProjectileGeometryDebugComponent extends PositionComponent {
  ProjectileGeometryDebugComponent({
    required this.weaponId,
    required Vector2 previousCenter,
    required Vector2 currentCenter,
    required Vector2 direction,
    required Vector2 visualBodySize,
    required Vector2 hitBodySize,
    required Vector2 hurtCenter,
    required this.hurtRadius,
    required ProjectileContact contact,
    this.autoExpire = true,
  }) : _previousCenter = previousCenter.clone(),
       _currentCenter = currentCenter.clone(),
       _direction = _unit(direction),
       _visualBodySize = visualBodySize.clone(),
       _hitBodySize = hitBodySize.clone(),
       _hurtCenter = hurtCenter.clone(),
       _contact = ProjectileContact(
         travelFraction: contact.travelFraction,
         point: contact.point,
         normal: contact.normal,
       ),
       super(priority: 1001);

  static const lifetime = .12;

  final WeaponId weaponId;
  final Vector2 _previousCenter;
  final Vector2 _currentCenter;
  final Vector2 _direction;
  final Vector2 _visualBodySize;
  final Vector2 _hitBodySize;
  final Vector2 _hurtCenter;
  final double hurtRadius;
  final bool autoExpire;
  final ProjectileContact _contact;
  double _age = 0;

  bool showVisualBody = true;
  bool showHitBody = true;
  bool showSweep = true;
  bool showHurtbox = true;
  bool showContact = true;
  bool showWeaponId = true;

  Vector2 get previousCenter => _previousCenter.clone();
  Vector2 get currentCenter => _currentCenter.clone();
  Vector2 get direction => _direction.clone();
  Vector2 get visualBodySize => _visualBodySize.clone();
  Vector2 get hitBodySize => _hitBodySize.clone();
  Vector2 get hurtCenter => _hurtCenter.clone();
  ProjectileContact get contact => ProjectileContact(
    travelFraction: _contact.travelFraction,
    point: _contact.point,
    normal: _contact.normal,
  );

  @override
  void update(double dt) {
    super.update(dt);
    if (dt.isFinite && dt > 0) {
      _age += dt;
    }
    if (autoExpire && _age >= lifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (!kDebugMode) return;
    final angle = math.atan2(_direction.y, _direction.x);
    if (showSweep) {
      canvas.drawLine(
        _previousCenter.toOffset(),
        _currentCenter.toOffset(),
        _stroke(const Color(0xfff0b847)),
      );
    }
    if (showVisualBody) {
      _drawBody(
        canvas,
        center: _currentCenter,
        size: _visualBodySize,
        angle: angle,
        color: const Color(0xff55d6ff),
      );
    }
    if (showHitBody) {
      _drawBody(
        canvas,
        center: _currentCenter,
        size: _hitBodySize,
        angle: angle,
        color: const Color(0xffff6b57),
      );
    }
    if (showHurtbox) {
      canvas.drawCircle(
        _hurtCenter.toOffset(),
        hurtRadius,
        _stroke(const Color(0xfff4ead2)),
      );
    }
    if (showContact) {
      final point = _contact.point;
      final normalEnd = point + _contact.normal * 14;
      canvas.drawCircle(
        point.toOffset(),
        3,
        _stroke(const Color(0xffff4fd8))..strokeWidth = 2,
      );
      canvas.drawLine(
        point.toOffset(),
        normalEnd.toOffset(),
        _stroke(const Color(0xffff4fd8)),
      );
    }
    if (showWeaponId) {
      final painter = TextPainter(
        text: TextSpan(
          text: '$weaponId  t=${_contact.travelFraction.toStringAsFixed(3)}',
          style: const TextStyle(
            color: Color(0xfff4ead2),
            fontSize: 11,
            backgroundColor: Color(0xcc101923),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, (_currentCenter + Vector2(8, -28)).toOffset());
    }
  }
}

void _drawBody(
  Canvas canvas, {
  required Vector2 center,
  required Vector2 size,
  required double angle,
  required Color color,
}) {
  canvas
    ..save()
    ..translate(center.x, center.y)
    ..rotate(angle)
    ..drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: size.x, height: size.y),
        Radius.circular(size.y / 2),
      ),
      _stroke(color),
    )
    ..restore();
}

Paint _stroke(Color color) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = 1.5
  ..color = color;

Vector2 _unit(Vector2 value) {
  if (value.length2 == 0) return Vector2(1, 0);
  return value.clone()..normalize();
}
