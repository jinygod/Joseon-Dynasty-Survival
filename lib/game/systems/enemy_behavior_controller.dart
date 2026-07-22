import 'package:flame/components.dart';

import '../content/enemy_behavior_definitions.dart';
import '../content/ids.dart';

enum EnemyAttackKind { dive, thrust, dash, shockwave, scream, projectile }

class EnemyAttackRequest {
  EnemyAttackRequest({
    required this.kind,
    required Vector2 origin,
    required Vector2 direction,
    required this.range,
    double? telegraphDistance,
  }) : telegraphDistance = telegraphDistance ?? range,
       origin = origin.clone(),
       direction = direction.clone();

  final EnemyAttackKind kind;
  final Vector2 origin;
  final Vector2 direction;
  final double range;
  final double telegraphDistance;

  Vector2 get telegraphEndpoint => origin + direction * telegraphDistance;
}

class EnemyBehaviorTick {
  const EnemyBehaviorTick({
    required this.phase,
    required this.movementMultiplier,
    required this.movementDirection,
    this.attack,
  });

  final EnemyBehaviorPhase phase;
  final double movementMultiplier;
  final Vector2 movementDirection;
  final EnemyAttackRequest? attack;
}

class EnemyBehaviorController {
  EnemyBehaviorController({required this.profile});

  final EnemyBehaviorProfile profile;
  EnemyBehaviorPhase phase = EnemyBehaviorPhase.tracking;
  double phaseElapsed = 0;
  final Vector2 lockedDirection = Vector2(1, 0);
  int _activeAttackCount = 0;

  double get warningRange => profile.range;

  EnemyBehaviorTick tick({
    required double dt,
    required Vector2 origin,
    required Vector2 target,
    double dashTravelDistance = 0,
  }) {
    final safeDt = !dt.isFinite || dt < 0 ? 0.0 : dt.clamp(0, .05).toDouble();
    final attackKind = _attackKindFor(profile.kind);
    final towardTarget = _directionFrom(origin, target);
    final movement = _movementFor(towardTarget, origin.distanceTo(target));
    if (attackKind == null) {
      phase = EnemyBehaviorPhase.tracking;
      phaseElapsed += safeDt;
      return EnemyBehaviorTick(
        phase: EnemyBehaviorPhase.tracking,
        movementMultiplier: 1,
        movementDirection: towardTarget,
      );
    }

    phaseElapsed += safeDt;
    EnemyAttackRequest? attack;
    switch (phase) {
      case EnemyBehaviorPhase.tracking:
        if (profile.kind == EnemyBehaviorKind.ranged ||
            phaseElapsed >= profile.cooldownSeconds) {
          _enter(EnemyBehaviorPhase.warning);
          _lockDirection(origin, target);
        }
      case EnemyBehaviorPhase.warning:
        if (phaseElapsed >= profile.warningSeconds) {
          _enter(EnemyBehaviorPhase.active);
          attack = _attack(attackKind, origin, dashTravelDistance);
          _activeAttackCount = 1;
        }
      case EnemyBehaviorPhase.active:
        if (profile.kind == EnemyBehaviorKind.doubleDash &&
            _activeAttackCount == 1 &&
            phaseElapsed >= profile.activeSeconds / 2) {
          attack = _attack(attackKind, origin, dashTravelDistance);
          _activeAttackCount = 2;
        }
        if (phaseElapsed >= profile.activeSeconds) {
          _enter(EnemyBehaviorPhase.recovery);
        }
      case EnemyBehaviorPhase.recovery:
        if (phaseElapsed >= profile.recoverySeconds) {
          _enter(EnemyBehaviorPhase.cooldown);
        }
      case EnemyBehaviorPhase.cooldown:
        if (phaseElapsed >= profile.cooldownSeconds) {
          _enter(EnemyBehaviorPhase.warning);
          _lockDirection(origin, target);
        }
    }

    return EnemyBehaviorTick(
      phase: phase,
      movementMultiplier: phase == EnemyBehaviorPhase.active
          ? profile.movementMultiplier
          : movement.$1,
      movementDirection:
          phase == EnemyBehaviorPhase.active &&
              profile.kind != EnemyBehaviorKind.ranged
          ? lockedDirection.clone()
          : movement.$2,
      attack: attack,
    );
  }

  EnemyAttackRequest? warningAttackPreview({
    required Vector2 origin,
    required double dashTravelDistance,
  }) {
    if (phase != EnemyBehaviorPhase.warning) return null;
    final attackKind = _attackKindFor(profile.kind);
    if (attackKind == null) return null;
    return _attack(attackKind, origin, dashTravelDistance);
  }

  void _enter(EnemyBehaviorPhase next) {
    phase = next;
    phaseElapsed = 0;
    if (next == EnemyBehaviorPhase.active) _activeAttackCount = 0;
  }

  void _lockDirection(Vector2 origin, Vector2 target) {
    lockedDirection.setFrom(target - origin);
    if (lockedDirection.length2 == 0) {
      lockedDirection.setValues(1, 0);
    } else {
      lockedDirection.normalize();
    }
  }

  EnemyAttackRequest _attack(
    EnemyAttackKind kind,
    Vector2 origin,
    double dashTravelDistance,
  ) => EnemyAttackRequest(
    kind: kind,
    origin: origin,
    direction: lockedDirection,
    range: profile.range,
    telegraphDistance: switch (kind) {
      EnemyAttackKind.dash || EnemyAttackKind.dive => dashTravelDistance,
      _ => profile.range,
    },
  );

  (double, Vector2) _movementFor(Vector2 towardTarget, double distance) {
    if (profile.kind != EnemyBehaviorKind.ranged) return (1, towardTarget);
    if (distance < profile.minimumRange) return (-1, -towardTarget);
    if (distance <= profile.preferredRange) return (0, Vector2.zero());
    return (1, towardTarget);
  }
}

Vector2 _directionFrom(Vector2 origin, Vector2 target) {
  final direction = target - origin;
  return direction.length2 == 0 ? Vector2(1, 0) : direction.normalized();
}

EnemyAttackKind? _attackKindFor(EnemyBehaviorKind kind) => switch (kind) {
  EnemyBehaviorKind.dive => EnemyAttackKind.dive,
  EnemyBehaviorKind.thrust => EnemyAttackKind.thrust,
  EnemyBehaviorKind.dash ||
  EnemyBehaviorKind.doubleDash => EnemyAttackKind.dash,
  EnemyBehaviorKind.shockwave => EnemyAttackKind.shockwave,
  EnemyBehaviorKind.scream => EnemyAttackKind.scream,
  EnemyBehaviorKind.ranged => EnemyAttackKind.projectile,
  EnemyBehaviorKind.chase ||
  EnemyBehaviorKind.swarm ||
  EnemyBehaviorKind.tank ||
  EnemyBehaviorKind.deathZone ||
  EnemyBehaviorKind.hasteAura => null,
};
