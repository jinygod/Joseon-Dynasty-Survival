import 'dart:math' as math;

import 'package:flame/components.dart';

import '../content/ids.dart';
import '../systems/boss_controller.dart';
import 'area_attack_component.dart';
import 'enemy_component.dart';

typedef BossAreaAttackEmitter = void Function(AreaAttackComponent attack);

class BossComponent extends EnemyComponent {
  BossComponent({
    required EnemyDefinition definition,
    required TargetPositionProvider targetPositionProvider,
    super.nearbyEnemiesProvider,
    super.position,
    this.onAreaAttack,
    this.onSummonRequested,
    BossController? controller,
  }) : displayName = definition.name,
       controller = controller ?? BossController(),
       super(
         enemyId: definition.id,
         maxHealth: definition.maxHealth,
         moveSpeed: definition.moveSpeed,
         damage: definition.damage,
         experienceValue: definition.experience,
         behaviorType: EnemyBehaviorType.tank,
         rank: EnemyRank.boss,
         targetPositionProvider: targetPositionProvider,
         size: Vector2.all(42),
       );

  final String displayName;
  final BossController controller;
  final BossAreaAttackEmitter? onAreaAttack;
  final void Function()? onSummonRequested;

  double _chargeRemaining = 0;
  double _chargeWarningRemaining = 0;
  final Vector2 _chargeDirection = Vector2.zero();

  double get healthFraction =>
      maxHealth <= 0 ? 0 : (currentHealth / maxHealth).clamp(0, 1).toDouble();
  bool get isEnraged => controller.isEnraged;
  bool get isChargeWarningActive => _chargeWarningRemaining > 0;

  @override
  void moveToward(Vector2 target, double dt) {
    final direction = target - position;
    if (direction.length2 == 0) return;
    direction.normalize();
    position.add(direction * moveSpeed * controller.movementMultiplier * dt);
    playMove();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_chargeRemaining > 0 && !isDead) {
      position.add(
        _chargeDirection * moveSpeed * 4 * controller.movementMultiplier * dt,
      );
      _chargeRemaining = math.max(0.0, _chargeRemaining - dt);
    }
    _chargeWarningRemaining = math.max(0.0, _chargeWarningRemaining - dt);

    final actions = controller.tick(dt: dt, healthFraction: healthFraction);
    for (final action in actions) {
      _execute(action);
    }
  }

  void _execute(BossAction action) {
    switch (action.type) {
      case BossActionType.chargeWarning:
        _chargeWarningRemaining = BossController.chargeWarningSeconds;
        playAttack();
      case BossActionType.charge:
        _chargeDirection.setFrom(_directionToTarget());
        _chargeRemaining = 0.35;
        playAttack();
      case BossActionType.coneWarning:
        playAttack();
        onAreaAttack?.call(
          AreaAttackComponent(
            damage: damage * 1.5,
            radius: 130,
            delaySeconds: BossController.coneWarningSeconds,
            knockback: 90,
            position: position.clone(),
            direction: _directionToTarget(),
            angleRadians: math.pi / 2,
            isBossAttack: true,
          ),
        );
      case BossActionType.coneDamage:
        break;
      case BossActionType.summon:
        playAttack();
        onSummonRequested?.call();
    }
  }

  Vector2 _directionToTarget() {
    final target = targetPositionProvider?.call(position);
    if (target == null) return Vector2(1, 0);
    final direction = target - position;
    if (direction.length2 == 0) return Vector2(1, 0);
    return direction..normalize();
  }
}
