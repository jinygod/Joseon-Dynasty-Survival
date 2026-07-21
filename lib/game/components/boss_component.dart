import 'dart:math' as math;

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
    required EnemyDefinition definition,
    required TargetPositionProvider targetPositionProvider,
    NearbyEnemiesProvider? nearbyEnemiesProvider,
    Vector2? position,
    BossAreaAttackEmitter? onAreaAttack,
    void Function()? onSummonRequested,
    BossController? controller,
  }) : this._(
         definition: _definitionForLegacyEnemy(definition),
         enemyDefinition: definition,
         targetPositionProvider: targetPositionProvider,
         nearbyEnemiesProvider: nearbyEnemiesProvider,
         position: position,
         onAreaAttack: onAreaAttack,
         onSummonRequested: onSummonRequested,
         controller: controller,
         legacyController: true,
       );

  BossComponent.fromBossDefinition({
    required BossDefinition definition,
    required TargetPositionProvider targetPositionProvider,
    NearbyEnemiesProvider? nearbyEnemiesProvider,
    Vector2? position,
    BossAreaAttackEmitter? onAreaAttack,
    BossSummonEmitter? onSummonEnemiesRequested,
    void Function()? onSummonRequested,
    BossController? controller,
  }) : this._(
         definition: definition,
         enemyDefinition: definition.enemy,
         targetPositionProvider: targetPositionProvider,
         nearbyEnemiesProvider: nearbyEnemiesProvider,
         position: position,
         onAreaAttack: onAreaAttack,
         onSummonRequested: onSummonRequested,
         onSummonEnemiesRequested: onSummonEnemiesRequested,
         controller: controller,
       );

  BossComponent._({
    required this.definition,
    required EnemyDefinition enemyDefinition,
    required TargetPositionProvider targetPositionProvider,
    super.nearbyEnemiesProvider,
    super.position,
    this.onAreaAttack,
    this.onSummonRequested,
    this.onSummonEnemiesRequested,
    BossController? controller,
    bool legacyController = false,
  }) : displayName = definition.name,
       controller = _validatedController(
         definition,
         controller,
         legacyController: legacyController,
       ),
       super(
         enemyId: enemyDefinition.id,
         maxHealth: enemyDefinition.maxHealth,
         moveSpeed: enemyDefinition.moveSpeed,
         damage: enemyDefinition.damage,
         experienceValue: enemyDefinition.experience,
         behaviorType: EnemyBehaviorType.tank,
         rank: EnemyRank.boss,
         targetPositionProvider: targetPositionProvider,
       );

  final BossDefinition definition;
  final String displayName;
  final BossController controller;
  final BossAreaAttackEmitter? onAreaAttack;
  final void Function()? onSummonRequested;
  final BossSummonEmitter? onSummonEnemiesRequested;

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
  EnemyWarningSnapshot? get warningSnapshot {
    final behaviorWarning = super.warningSnapshot;
    if (behaviorWarning != null) return behaviorWarning;
    final pattern = _warningPattern;
    if (_warningRemaining <= 0 || pattern == null) return null;
    return switch (pattern.kind) {
      BossPatternKind.charge => EnemyWarningSnapshot(
        kind: EnemyBehaviorKind.dash,
        direction: _chargeDirection,
        range: 190,
        progress: 1 - (_warningRemaining / pattern.warningSeconds),
      ),
      BossPatternKind.summon => EnemyWarningSnapshot(
        kind: EnemyBehaviorKind.scream,
        direction: _chargeDirection,
        range: 72,
        progress: 1 - (_warningRemaining / pattern.warningSeconds),
      ),
      BossPatternKind.cone || BossPatternKind.radial => null,
    };
  }

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
    final safeComponentDt = dt.isFinite && dt > 0
        ? math.min(dt, BossController.maxComponentDt)
        : 0.0;
    super.update(safeComponentDt);

    if (_chargeRemaining > 0 && !isDead) {
      position.add(
        _chargeDirection *
            moveSpeed *
            (_warningPattern?.chargeSpeedMultiplier ?? 0) *
            controller.movementMultiplier *
            safeComponentDt,
      );
      _chargeRemaining = math.max(0.0, _chargeRemaining - safeComponentDt);
    }
    _warningRemaining = math.max(0.0, _warningRemaining - safeComponentDt);

    final actions = controller.tick(dt: dt, healthFraction: healthFraction);
    for (final action in actions) {
      _execute(action);
    }
  }

  void _execute(BossAction action) {
    final pattern = action.pattern ?? controller.currentPattern;
    if (pattern == null) return;
    switch (action.type) {
      case BossActionType.chargeWarning:
      case BossActionType.coneWarning:
      case BossActionType.warning:
        _warningPattern = pattern;
        _warningRemaining = pattern.warningSeconds;
        _chargeDirection.setFrom(_directionToTarget());
        playAttack();
        if (pattern.kind == BossPatternKind.cone ||
            pattern.kind == BossPatternKind.radial) {
          onAreaAttack?.call(
            AreaAttackComponent(
              damage: damage * pattern.damageMultiplier,
              radius: pattern.radius,
              delaySeconds: pattern.warningSeconds,
              knockback: pattern.knockback,
              position: position.clone(),
              direction: _chargeDirection,
              angleRadians: pattern.angleRadians,
              isBossAttack: true,
            ),
          );
        }
      case BossActionType.charge:
      case BossActionType.coneDamage:
      case BossActionType.summon:
      case BossActionType.execute:
        _warningRemaining = 0;
        playAttack();
        switch (pattern.kind) {
          case BossPatternKind.charge:
            _chargeRemaining = pattern.chargeSeconds;
          case BossPatternKind.summon:
            onSummonRequested?.call();
            onSummonEnemiesRequested?.call(pattern.summonEnemyIds);
          case BossPatternKind.cone:
          case BossPatternKind.radial:
            break;
        }
    }
  }

  Vector2 _directionToTarget() {
    final target = targetPositionProvider?.call(position);
    if (target == null) return Vector2(1, 0);
    final direction = target - position;
    if (direction.length2 == 0) return Vector2(1, 0);
    return direction..normalize();
  }

  static BossDefinition _definitionForLegacyEnemy(EnemyDefinition enemy) {
    return bossDefinitionForId(enemy.id) ??
        BossDefinition(
          enemy: enemy,
          patterns: fallenGeneralBossDefinition.patterns,
          enrage: fallenGeneralBossDefinition.enrage,
        );
  }

  static BossController _validatedController(
    BossDefinition definition,
    BossController? controller, {
    required bool legacyController,
  }) {
    if (controller != null && controller.definition.id != definition.id) {
      throw ArgumentError.value(
        controller.definition.id,
        'controller',
        'must match boss definition ${definition.id}',
      );
    }
    return controller ??
        BossController(definition: definition, legacyActions: legacyController);
  }
}
