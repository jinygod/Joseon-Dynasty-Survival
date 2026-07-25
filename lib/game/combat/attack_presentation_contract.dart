import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import 'attack_spec.dart';
import 'attack_timeline.dart';

@immutable
class SectorGeometry {
  SectorGeometry({
    required Vector2 origin,
    required Vector2 direction,
    required this.radius,
    required this.angleRadians,
  }) : assert(radius >= 0),
       assert(angleRadians >= 0),
       _origin = origin.clone(),
       _direction = _unit(direction);

  final Vector2 _origin;
  final Vector2 _direction;
  final double radius;
  final double angleRadians;

  Vector2 get origin => _origin.clone();
  Vector2 get direction => _direction.clone();

  SectorGeometry inset(double fraction) {
    if (!fraction.isFinite || fraction < 0 || fraction > .15) {
      throw ArgumentError.value(
        fraction,
        'fraction',
        'must be finite and between 0 and 0.15',
      );
    }
    final scale = 1 - fraction;
    return SectorGeometry(
      origin: _origin,
      direction: _direction,
      radius: radius * scale,
      angleRadians: angleRadians * scale,
    );
  }
}

@immutable
class AttackPresentationContract {
  const AttackPresentationContract._({
    required this.effectId,
    required this.timing,
    required this.visualSector,
    required this.hitSector,
  });

  factory AttackPresentationContract.fromAttack(
    AttackInstance attack, {
    double hitInsetFraction = .10,
  }) {
    if (attack.spec.shape != AttackShape.sector) {
      throw ArgumentError.value(
        attack.spec.shape,
        'attack.spec.shape',
        'Hwando presentation contract requires a sector attack',
      );
    }
    final visualSector = SectorGeometry(
      origin: attack.origin,
      direction: attack.direction,
      radius: attack.spec.range,
      angleRadians: attack.spec.angleRadians,
    );
    return AttackPresentationContract._(
      effectId: attack.spec.id,
      timing: AttackTiming(
        windupSeconds: _safeDuration(attack.spec.windupSeconds),
        activeSeconds: _safeDuration(attack.spec.activeSeconds),
        recoverySeconds: _safeDuration(attack.spec.recoverySeconds),
      ),
      visualSector: visualSector,
      hitSector: visualSector.inset(hitInsetFraction),
    );
  }

  final String effectId;
  final AttackTiming timing;
  final SectorGeometry visualSector;
  final SectorGeometry hitSector;
}

double _safeDuration(double value) => value.isFinite && value >= 0 ? value : 0;

Vector2 _unit(Vector2 value) {
  if (value.length2 == 0) return Vector2(1, 0);
  return value.clone()..normalize();
}
