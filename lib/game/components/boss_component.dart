import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../content/boss_definitions.dart';
import '../content/ids.dart';
import '../systems/boss_controller.dart';
import 'area_attack_component.dart';
import 'enemy_component.dart';

typedef BossAreaAttackEmitter = void Function(AreaAttackComponent attack);
typedef BossSummonEmitter = void Function(List<String> enemyIds);

class BossComponent extends EnemyComponent {
  BossComponent({
    required BossDefinition definition,
    required TargetPositionProvider targetPositionProvider,
    super.nearbyEnemiesProvider,
    super.position,
    this.onAreaAttack,
    this.onSummonRequested,
    BossController? controller,
  }) : definition = definition,
       displayName = definition.name,
       controller = controller ?? BossController(definition: definition),
       super(
         enemyId: definition.enemy.id,
         maxHealth: definition.enemy.maxHealth,
         moveSpeed: definition.enemy.moveSpeed,
         damage: definition.enemy.damage,
         experienceValue: definition.enemy.experience,
         behaviorType: EnemyBehaviorType.tank,
         rank: EnemyRank.boss,
         targetPositionProvider: targetPositionProvider,
         size: Vector2.all(42),
       );

  final BossDefinition definition;
  final String displayName;
  final BossController controller;
  final BossAreaAttackEmitter? onAreaAttack;
  final BossSummonEmitter? onSummonRequested;

  double _chargeRemaining = 0;
  double _warningRemaining = 0;
  BossPatternDefinition? _warningPattern;
  final Vector2 _chargeDirection = Vector2.zero();

  double get healthFraction =>
      maxHealth <= 0 ? 0 : (currentHealth / maxHealth).clamp(0, 1).toDouble();
  bool get isEnraged => controller.isEnraged;
  bool get isChargeWarningActive =>
      _warningRemaining > 0 && _warningPattern?.kind == BossPatternKind.charge;
  bool get isPatternWarningActive => _warningRemaining > 0;
  String? get warningPatternId => _warningPattern?.id;

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
        _chargeDirection *
            moveSpeed *
            (_warningPattern?.chargeSpeedMultiplier ?? 0) *
            controller.movementMultiplier *
            dt,
      );
      _chargeRemaining = math.max(0.0, _chargeRemaining - dt);
    }
    _warningRemaining = math.max(0.0, _warningRemaining - dt);

    final actions = controller.tick(dt: dt, healthFraction: healthFraction);
    for (final action in actions) {
      _execute(action);
    }
  }

  void _execute(BossAction action) {
    switch (action.type) {
      case BossActionType.warning:
        _warningPattern = action.pattern;
        _warningRemaining = action.pattern.warningSeconds;
        _chargeDirection.setFrom(_directionToTarget());
        playAttack();
        if (action.pattern.kind == BossPatternKind.cone ||
            action.pattern.kind == BossPatternKind.radial) {
          onAreaAttack?.call(
            AreaAttackComponent(
              damage: damage * action.pattern.damageMultiplier,
              radius: action.pattern.radius,
              delaySeconds: action.pattern.warningSeconds,
              knockback: action.pattern.knockback,
              position: position.clone(),
              direction: _chargeDirection,
              angleRadians: action.pattern.angleRadians,
              isBossAttack: true,
            ),
          );
        }
      case BossActionType.execute:
        _warningRemaining = 0;
        playAttack();
        switch (action.pattern.kind) {
          case BossPatternKind.charge:
            _chargeRemaining = action.pattern.chargeSeconds;
          case BossPatternKind.summon:
            onSummonRequested?.call(action.pattern.summonEnemyIds);
          case BossPatternKind.cone:
          case BossPatternKind.radial:
            break;
        }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (_warningRemaining <= 0) return;
    final pattern = _warningPattern;
    if (pattern == null ||
        (pattern.kind != BossPatternKind.charge &&
            pattern.kind != BossPatternKind.summon)) {
      return;
    }

    final center = Offset(size.x / 2, size.y / 2);
    final paint = Paint()
      ..color = const Color(0xffffd166)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    if (pattern.kind == BossPatternKind.charge) {
      canvas.drawLine(
        center,
        center + Offset(_chargeDirection.x, _chargeDirection.y) * 190,
        paint,
      );
    } else {
      canvas.drawCircle(center, 72, paint);
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
