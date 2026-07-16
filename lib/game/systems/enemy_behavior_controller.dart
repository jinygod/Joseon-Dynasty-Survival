import 'package:flame/components.dart';

import '../content/enemy_behavior_definitions.dart';
import '../content/ids.dart';

enum EnemyAttackKind { dive, thrust, dash, shockwave, scream }

class EnemyAttackRequest {
  EnemyAttackRequest({
    required this.kind,
    required Vector2 origin,
    required Vector2 direction,
    required this.range,
  }) : origin = origin.clone(),
       direction = direction.clone();

  final EnemyAttackKind kind;
  final Vector2 origin;
  final Vector2 direction;
  final double range;
}

class EnemyBehaviorTick {
  const EnemyBehaviorTick({
    required this.phase,
    required this.movementMultiplier,
    this.attack,
  });

  final EnemyBehaviorPhase phase;
  final double movementMultiplier;
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
  }) {
    final safeDt = !dt.isFinite || dt < 0 ? 0.0 : dt.clamp(0, .05).toDouble();
    final attackKind = _attackKindFor(profile.kind);
    if (attackKind == null) {
      phase = EnemyBehaviorPhase.tracking;
      phaseElapsed += safeDt;
      return const EnemyBehaviorTick(
        phase: EnemyBehaviorPhase.tracking,
        movementMultiplier: 1,
      );
    }

    phaseElapsed += safeDt;
    EnemyAttackRequest? attack;
    switch (phase) {
      case EnemyBehaviorPhase.tracking:
        if (phaseElapsed >= profile.cooldownSeconds) {
          _enter(EnemyBehaviorPhase.warning);
          _lockDirection(origin, target);
        }
      case EnemyBehaviorPhase.warning:
        if (phaseElapsed >= profile.warningSeconds) {
          _enter(EnemyBehaviorPhase.active);
          attack = _attack(attackKind, origin);
          _activeAttackCount = 1;
        }
      case EnemyBehaviorPhase.active:
        if (profile.kind == EnemyBehaviorKind.doubleDash &&
            _activeAttackCount == 1 &&
            phaseElapsed >= profile.activeSeconds / 2) {
          attack = _attack(attackKind, origin);
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
          : 1,
      attack: attack,
    );
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

  EnemyAttackRequest _attack(EnemyAttackKind kind, Vector2 origin) =>
      EnemyAttackRequest(
        kind: kind,
        origin: origin,
        direction: lockedDirection,
        range: profile.range,
      );
}

EnemyAttackKind? _attackKindFor(EnemyBehaviorKind kind) => switch (kind) {
  EnemyBehaviorKind.dive => EnemyAttackKind.dive,
  EnemyBehaviorKind.thrust => EnemyAttackKind.thrust,
  EnemyBehaviorKind.dash ||
  EnemyBehaviorKind.doubleDash => EnemyAttackKind.dash,
  EnemyBehaviorKind.shockwave => EnemyAttackKind.shockwave,
  EnemyBehaviorKind.scream => EnemyAttackKind.scream,
  EnemyBehaviorKind.chase ||
  EnemyBehaviorKind.swarm ||
  EnemyBehaviorKind.tank ||
  EnemyBehaviorKind.deathZone ||
  EnemyBehaviorKind.hasteAura => null,
};
