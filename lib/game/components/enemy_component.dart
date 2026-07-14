import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../content/ids.dart';
import 'player_component.dart';

typedef TargetPositionProvider = Vector2? Function(Vector2 enemyPosition);
typedef NearbyEnemiesProvider = Iterable<EnemyComponent> Function();

class EnemyComponent extends PositionComponent {
  EnemyComponent({
    required this.enemyId,
    required this.maxHealth,
    required this.moveSpeed,
    required this.damage,
    this.experienceValue = 1,
    this.behaviorType = EnemyBehaviorType.chase,
    this.isElite = false,
    this.targetPositionProvider,
    this.nearbyEnemiesProvider,
    double? currentHealth,
    Vector2? position,
    Vector2? size,
  }) : currentHealth = currentHealth ?? maxHealth,
       super(
         position: position ?? Vector2.zero(),
         size: size ?? Vector2.all(18),
         anchor: Anchor.center,
       );

  factory EnemyComponent.fromDefinition(
    EnemyDefinition definition, {
    bool isElite = false,
    TargetPositionProvider? targetPositionProvider,
    NearbyEnemiesProvider? nearbyEnemiesProvider,
    Vector2? position,
  }) {
    final eliteScale = isElite ? 1.35 : 1.0;
    return EnemyComponent(
      enemyId: definition.id,
      maxHealth: definition.maxHealth * (isElite ? 2.5 : 1),
      moveSpeed: definition.moveSpeed,
      damage: definition.damage * (isElite ? 1.4 : 1),
      experienceValue: definition.experience * (isElite ? 3 : 1),
      behaviorType: definition.behaviorType,
      isElite: isElite,
      targetPositionProvider: targetPositionProvider,
      nearbyEnemiesProvider: nearbyEnemiesProvider,
      position: position,
      size: Vector2.all(18 * eliteScale),
    );
  }

  final EnemyId enemyId;
  final double maxHealth;
  double currentHealth;
  final double moveSpeed;
  final double damage;
  final int experienceValue;
  final EnemyBehaviorType behaviorType;
  final bool isElite;
  final TargetPositionProvider? targetPositionProvider;
  final NearbyEnemiesProvider? nearbyEnemiesProvider;

  static const _dashTrackingSeconds = 2.4;
  static const _dashDurationSeconds = 0.35;
  static const _dashSpeedMultiplier = 3.2;
  static const _hitFlashSeconds = 0.18;

  double _dashTrackingElapsed = 0;
  double _dashRemaining = 0;
  double _hitFlashRemaining = 0;
  final Vector2 knockbackVelocity = Vector2.zero();

  bool get isDead => currentHealth <= 0;
  bool get isDashing => _dashRemaining > 0;
  bool get isHitFlashing => _hitFlashRemaining > 0;

  void takeDamage(double amount) {
    if (amount <= 0 || isDead) {
      return;
    }

    currentHealth = (currentHealth - amount).clamp(0, maxHealth).toDouble();
    _hitFlashRemaining = _hitFlashSeconds;
  }

  void registerHit({Vector2? knockback}) {
    _hitFlashRemaining = _hitFlashSeconds;
    if (knockback != null) {
      applyKnockback(knockback);
    }
  }

  void applyKnockback(Vector2 impulse) {
    final resistanceMultiplier = behaviorType == EnemyBehaviorType.tank
        ? 0.3
        : 1.0;
    knockbackVelocity.add(impulse * resistanceMultiplier);
  }

  bool overlapsPlayer(PlayerComponent player) {
    final hitRadius = (size.x + player.size.x) / 2;
    return position.distanceToSquared(player.position) < hitRadius * hitRadius;
  }

  void moveToward(Vector2 target, double dt) {
    final direction = target - position;
    if (direction.length2 == 0) {
      return;
    }

    direction.normalize();
    if (behaviorType == EnemyBehaviorType.swarm) {
      direction.add(_separationDirection() * 0.45);
      if (direction.length2 > 0) {
        direction.normalize();
      }
    }

    final speedMultiplier = isDashing ? _dashSpeedMultiplier : 1.0;
    position.add(direction * moveSpeed * speedMultiplier * dt);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final wasDashing = isDashing;
    final target = targetPositionProvider?.call(position);
    if (target != null && !isDead) {
      moveToward(target, dt);
    }

    if (!isDead && knockbackVelocity.length2 > 0) {
      position.add(knockbackVelocity * dt);
      knockbackVelocity.scale(math.exp(-6 * dt));
      if (knockbackVelocity.length2 < 0.01) {
        knockbackVelocity.setZero();
      }
    }

    _hitFlashRemaining = math.max(0.0, _hitFlashRemaining - dt);
    if (behaviorType == EnemyBehaviorType.dash && !isDead) {
      if (wasDashing) {
        _dashRemaining = math.max(0.0, _dashRemaining - dt);
      } else {
        _dashTrackingElapsed += dt;
        if (_dashTrackingElapsed >= _dashTrackingSeconds) {
          _dashTrackingElapsed = 0;
          _dashRemaining = _dashDurationSeconds;
        }
      }
    }
  }

  Vector2 _separationDirection() {
    final separation = Vector2.zero();
    final nearbyEnemies = nearbyEnemiesProvider?.call();
    if (nearbyEnemies == null) {
      return separation;
    }

    const separationRadiusSquared = 28.0 * 28.0;
    for (final other in nearbyEnemies) {
      if (identical(other, this) || other.enemyId != enemyId || other.isDead) {
        continue;
      }

      final away = position - other.position;
      final distanceSquared = away.length2;
      if (distanceSquared == 0 || distanceSquared > separationRadiusSquared) {
        continue;
      }

      separation.add(away / math.sqrt(distanceSquared));
    }

    if (separation.length2 > 0) {
      separation.normalize();
    }
    return separation;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final bodyPaint = Paint()
      ..color = isHitFlashing
          ? const Color(0xffffffff)
          : isElite
          ? const Color(0xfff08a5d)
          : const Color(0xffd1495b);
    final outlinePaint = Paint()
      ..color = const Color(0xff2f1b25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = Offset.zero & Size(size.x, size.y);
    canvas.drawRect(rect, bodyPaint);
    canvas.drawRect(rect, outlinePaint);
  }
}
