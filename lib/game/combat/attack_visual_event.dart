import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:pixel_survivor/game/combat/attack_spec.dart';

@immutable
class AttackVisualEvent {
  AttackVisualEvent.fromAttack(AttackInstance attack)
    : effectId = attack.spec.id,
      shape = attack.spec.shape,
      _origin = attack.origin,
      _direction = attack.direction,
      range = attack.spec.range,
      angleRadians = attack.spec.angleRadians,
      radius = attack.spec.radius,
      width = attack.spec.width,
      impactAt = attack.spec.windupSeconds,
      duration =
          attack.spec.windupSeconds +
          attack.spec.activeSeconds +
          attack.spec.lingerSeconds,
      presentation = attack.spec.presentation,
      damage = attack.spec.damage,
      isCritical = attack.isCritical,
      sequenceIndex = attack.sequenceIndex;

  final String effectId;
  final AttackShape shape;
  final Vector2 _origin;
  final Vector2 _direction;
  final double range;
  final double angleRadians;
  final double radius;
  final double width;
  final double impactAt;
  final double duration;
  final AttackPresentation presentation;
  final double damage;
  final bool isCritical;
  final int sequenceIndex;

  Vector2 get origin => _origin.clone();
  Vector2 get direction => _direction.clone();
}
