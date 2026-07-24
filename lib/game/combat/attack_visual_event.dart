import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:pixel_survivor/game/combat/attack_spec.dart';

import 'attack_presentation_contract.dart';

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
      windupSeconds = attack.spec.windupSeconds,
      activeSeconds = attack.spec.activeSeconds,
      recoverySeconds = attack.spec.recoverySeconds,
      impactAt = attack.spec.windupSeconds,
      duration =
          attack.spec.windupSeconds +
          attack.spec.activeSeconds +
          attack.spec.lingerSeconds,
      presentation = attack.spec.presentation,
      damage = attack.spec.damage,
      isCritical = attack.isCritical,
      sequenceIndex = attack.sequenceIndex,
      presentationContract = attack.spec.shape == AttackShape.sector
          ? AttackPresentationContract.fromAttack(attack)
          : null;

  final String effectId;
  final AttackShape shape;
  final Vector2 _origin;
  final Vector2 _direction;
  final double range;
  final double angleRadians;
  final double radius;
  final double width;
  final double windupSeconds;
  final double activeSeconds;
  final double recoverySeconds;
  final double impactAt;
  final double duration;
  final AttackPresentation presentation;
  final double damage;
  final bool isCritical;
  final int sequenceIndex;
  final AttackPresentationContract? presentationContract;

  Vector2 get origin => _origin.clone();
  Vector2 get direction => _direction.clone();
}
