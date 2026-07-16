import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';

import '../content/enemy_definitions.dart';
import '../content/enemy_behavior_definitions.dart';
import '../content/ids.dart';
import '../content/safe_asset_loader.dart';
import '../content/visual_asset_load_policy.dart';
import '../systems/combat_feedback_tuning.dart';
import '../systems/enemy_behavior_controller.dart';
import 'player_component.dart';

typedef TargetPositionProvider = Vector2? Function(Vector2 enemyPosition);
typedef NearbyEnemiesProvider = Iterable<EnemyComponent> Function();

enum EnemyAnimationState { moving, attacking, hit, death }

class EnemySpriteSpec {
  const EnemySpriteSpec({required this.assetKey, required this.frameSize});

  final String assetKey;
  final double frameSize;
}

abstract final class EnemySpriteSheet {
  static const moveFrames = [0, 1, 2, 3];
  static const attackFrames = [4, 5, 6, 7];
  static const hitFrames = [8, 9];
  static const deathFrames = [10, 11, 12, 13, 14, 15];
  static const hitDurationSeconds = 0.18;
  static const attackDurationSeconds = 0.32;
  static const deathDurationSeconds = 0.66;

  static const specs = <EnemyId, EnemySpriteSpec>{
    plagueRatSwarm: EnemySpriteSpec(
      assetKey: 'monsters/plague_rat_swarm_24.png',
      frameSize: 24,
    ),
    bandit: EnemySpriteSpec(assetKey: 'monsters/bandit_32.png', frameSize: 32),
    dokkaebi: EnemySpriteSpec(
      assetKey: 'monsters/dokkaebi_32.png',
      frameSize: 32,
    ),
    vengefulSpirit: EnemySpriteSpec(
      assetKey: 'monsters/vengeful_spirit_32.png',
      frameSize: 32,
    ),
    fallenGeneral: EnemySpriteSpec(
      assetKey: 'monsters/fallen_general_64.png',
      frameSize: 64,
    ),
  };

  static Map<EnemyAnimationState, SpriteAnimation> animations(
    Image image,
    EnemySpriteSpec spec,
  ) {
    final textureSize = Vector2.all(spec.frameSize);
    SpriteAnimation animation(
      List<int> frames,
      double stepTime, {
      bool loop = true,
    }) => SpriteAnimation.fromFrameData(
      image,
      SpriteAnimationData.range(
        start: frames.first,
        end: frames.last,
        amount: 16,
        amountPerRow: 4,
        stepTimes: List.filled(frames.length, stepTime),
        textureSize: textureSize,
        loop: loop,
      ),
    );

    return {
      EnemyAnimationState.moving: animation(moveFrames, 0.12),
      EnemyAnimationState.attacking: animation(attackFrames, 0.08, loop: false),
      EnemyAnimationState.hit: animation(hitFrames, 0.09, loop: false),
      EnemyAnimationState.death: animation(deathFrames, 0.11, loop: false),
    };
  }
}

class EnemyComponent
    extends SpriteAnimationGroupComponent<EnemyAnimationState> {
  EnemyComponent({
    required this.enemyId,
    required this.maxHealth,
    required this.moveSpeed,
    required this.damage,
    this.experienceValue = 1,
    this.behaviorType = EnemyBehaviorType.chase,
    this.rank = EnemyRank.normal,
    EnemyBehaviorProfile? behaviorProfile,
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
         autoResize: false,
       ) {
    _behaviorProfile = behaviorProfile ?? _legacyProfileFor(behaviorType);
    _behaviorController = EnemyBehaviorController(profile: _behaviorProfile);
  }

  factory EnemyComponent.fromDefinition(
    EnemyDefinition definition, {
    TargetPositionProvider? targetPositionProvider,
    NearbyEnemiesProvider? nearbyEnemiesProvider,
    Vector2? position,
  }) {
    return EnemyComponent(
      enemyId: definition.id,
      maxHealth: definition.maxHealth,
      moveSpeed: definition.moveSpeed,
      damage: definition.damage,
      experienceValue: definition.experience,
      behaviorType: definition.behaviorType,
      rank: definition.rank,
      behaviorProfile: enemyBehaviorProfileFor(definition.behaviorProfileId),
      targetPositionProvider: targetPositionProvider,
      nearbyEnemiesProvider: nearbyEnemiesProvider,
      position: position,
      size: Vector2.all(definition.isElite ? 40 : 18),
    );
  }

  final EnemyId enemyId;
  final double maxHealth;
  double currentHealth;
  final double moveSpeed;
  final double damage;
  final int experienceValue;
  final EnemyBehaviorType behaviorType;
  final EnemyRank rank;
  final TargetPositionProvider? targetPositionProvider;
  final NearbyEnemiesProvider? nearbyEnemiesProvider;
  late final EnemyBehaviorProfile _behaviorProfile;
  late final EnemyBehaviorController _behaviorController;
  final List<EnemyAttackRequest> _attackRequests = [];

  static const _hitFlashSeconds = 0.18;

  double _hitFlashRemaining = 0;
  double _visualStateRemaining = 0;
  double _deathVisualElapsed = 0;
  double _environmentalSlowFraction = 0;
  double _environmentalHasteFraction = 0;
  bool _deathZonePending = false;
  final Vector2 knockbackVelocity = Vector2.zero();
  EnemyAnimationState visualState = EnemyAnimationState.moving;

  bool get deathVisualComplete =>
      isDead && _deathVisualElapsed >= EnemySpriteSheet.deathDurationSeconds;

  bool get isDead => currentHealth <= 0;
  bool get isElite => rank == EnemyRank.elite;
  bool get isDashing =>
      _behaviorController.phase == EnemyBehaviorPhase.active &&
      (_behaviorProfile.kind == EnemyBehaviorKind.dash ||
          _behaviorProfile.kind == EnemyBehaviorKind.dive ||
          _behaviorProfile.kind == EnemyBehaviorKind.doubleDash);
  bool get isHitFlashing => _hitFlashRemaining > 0;
  double get environmentalSlowFraction => _environmentalSlowFraction;
  double get environmentalHasteFraction => _environmentalHasteFraction;
  double get effectiveMoveSpeed =>
      moveSpeed *
      (1 + _environmentalHasteFraction) *
      (1 - _environmentalSlowFraction);
  EnemyBehaviorProfile get behaviorProfile => _behaviorProfile;
  EnemyBehaviorPhase get attackPhase => _behaviorController.phase;
  double get hasteAuraFraction =>
      _behaviorProfile.kind == EnemyBehaviorKind.hasteAura
      ? _behaviorProfile.effectMultiplier
      : 0;
  double get slowAuraFraction => enemyId == sorrowfulMaidenGhost ? .25 : 0;

  void setEnvironmentalSlow(double fraction) {
    if (!fraction.isFinite || fraction < 0 || fraction >= .8) {
      throw ArgumentError.value(fraction, 'fraction', 'Must be from 0 to 0.8');
    }
    _environmentalSlowFraction = fraction;
  }

  void setEnvironmentalHaste(double fraction) {
    if (!fraction.isFinite || fraction < 0 || fraction >= .8) {
      throw ArgumentError.value(fraction, 'fraction', 'Must be from 0 to 0.8');
    }
    _environmentalHasteFraction = fraction;
  }

  List<EnemyAttackRequest> drainAttackRequests() {
    final result = List<EnemyAttackRequest>.unmodifiable(_attackRequests);
    _attackRequests.clear();
    return result;
  }

  bool consumeDeathZone() {
    if (!_deathZonePending) return false;
    _deathZonePending = false;
    return true;
  }

  void takeDamage(double amount) {
    if (amount <= 0 || isDead) {
      return;
    }

    final wasAlive = !isDead;
    currentHealth = (currentHealth - amount).clamp(0, maxHealth).toDouble();
    _hitFlashRemaining = _hitFlashSeconds;
    if (isDead) {
      if (wasAlive && _behaviorProfile.kind == EnemyBehaviorKind.deathZone) {
        _deathZonePending = true;
      }
      _setVisualState(EnemyAnimationState.death);
    } else {
      _visualStateRemaining = EnemySpriteSheet.hitDurationSeconds;
      _setVisualState(EnemyAnimationState.hit);
    }
  }

  void registerHit({Vector2? knockback}) {
    _hitFlashRemaining = _hitFlashSeconds;
    if (!isDead) {
      _visualStateRemaining = EnemySpriteSheet.hitDurationSeconds;
      _setVisualState(EnemyAnimationState.hit);
    }
    if (knockback != null) {
      applyKnockback(knockback);
    }
  }

  void playAttack() {
    if (isDead || visualState == EnemyAnimationState.hit) {
      return;
    }
    _visualStateRemaining = EnemySpriteSheet.attackDurationSeconds;
    _setVisualState(EnemyAnimationState.attacking);
  }

  void playMove() {
    if (!isDead &&
        visualState != EnemyAnimationState.hit &&
        visualState != EnemyAnimationState.attacking) {
      _setVisualState(EnemyAnimationState.moving);
    }
  }

  void applyKnockback(Vector2 impulse) {
    final resistanceMultiplier = behaviorType == EnemyBehaviorType.tank
        ? 0.3
        : 1.0;
    knockbackVelocity.add(impulse * resistanceMultiplier);
    if (knockbackVelocity.length >
        CombatFeedbackTuning.maxEnemyKnockbackSpeed) {
      knockbackVelocity
        ..normalize()
        ..scale(CombatFeedbackTuning.maxEnemyKnockbackSpeed);
    }
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

    position.add(direction * effectiveMoveSpeed * dt);
    if (visualState != EnemyAnimationState.hit &&
        visualState != EnemyAnimationState.attacking &&
        !isDead) {
      playMove();
    }
  }

  @override
  void onLoad() {
    super.onLoad();
    final spec = EnemySpriteSheet.specs[enemyId];
    if (spec != null && shouldLoadVisualAssets(this)) {
      unawaited(_loadAnimations(spec));
    }
  }

  Future<void> _loadAnimations(EnemySpriteSpec spec) async {
    try {
      ServicesBinding.instance;
    } on AssertionError {
      return;
    }
    final image = await SafeAssetLoader.load(
      load: () => findGame()!.images.load(spec.assetKey),
      library: 'pixel_survivor enemy sprites',
      assetKey: spec.assetKey,
    );
    if (image == null) return;
    animations = EnemySpriteSheet.animations(image, spec);
    current = visualState;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isDead) {
      _deathVisualElapsed += dt;
    }

    final target = targetPositionProvider?.call(position);
    if (target != null && !isDead) {
      final behavior = _tickBehavior(dt, target);
      if (isDashing) {
        position.add(
          _behaviorController.lockedDirection *
              effectiveMoveSpeed *
              behavior.movementMultiplier *
              dt,
        );
      } else if (!_blocksMovementForPhase()) {
        if (_behaviorProfile.kind == EnemyBehaviorKind.dive &&
            _behaviorController.phase == EnemyBehaviorPhase.tracking) {
          _moveCrowToward(target, dt);
        } else {
          moveToward(target, dt);
        }
      }
    }

    if (!isDead && knockbackVelocity.length2 > 0) {
      position.add(knockbackVelocity * dt);
      knockbackVelocity.scale(math.exp(-6 * dt));
      if (knockbackVelocity.length2 < 0.01) {
        knockbackVelocity.setZero();
      }
    }

    _hitFlashRemaining = math.max(0.0, _hitFlashRemaining - dt);
    if (isDashing && visualState != EnemyAnimationState.hit) {
      playAttack();
    }
    if (_visualStateRemaining > 0) {
      _visualStateRemaining = math.max(0.0, _visualStateRemaining - dt);
      if (_visualStateRemaining == 0 && !isDead) {
        _setVisualState(EnemyAnimationState.moving);
      }
    }
  }

  EnemyBehaviorTick _tickBehavior(double dt, Vector2 target) {
    var remaining = dt.isFinite && dt > 0 ? dt : 0.0;
    var result = _behaviorController.tick(
      dt: 0,
      origin: position,
      target: target,
    );
    while (remaining > 0) {
      final step = math.min(.05, remaining);
      result = _behaviorController.tick(
        dt: step,
        origin: position,
        target: target,
      );
      final attack = result.attack;
      if (attack != null) {
        if (_attackRequests.length == 2) _attackRequests.removeAt(0);
        _attackRequests.add(attack);
      }
      remaining -= step;
    }
    return result;
  }

  bool _blocksMovementForPhase() {
    if (_behaviorController.phase != EnemyBehaviorPhase.warning &&
        _behaviorController.phase != EnemyBehaviorPhase.recovery) {
      return false;
    }
    return _behaviorProfile.kind == EnemyBehaviorKind.thrust ||
        _behaviorProfile.kind == EnemyBehaviorKind.shockwave ||
        _behaviorProfile.kind == EnemyBehaviorKind.scream;
  }

  void _moveCrowToward(Vector2 target, double dt) {
    final toward = target - position;
    if (toward.length2 == 0) return;
    toward.normalize();
    final direction = toward * .45 + Vector2(-toward.y, toward.x) * .55;
    direction.normalize();
    position.add(direction * effectiveMoveSpeed * dt);
  }

  void _setVisualState(EnemyAnimationState state) {
    visualState = state;
    if (animations != null) {
      current = state;
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
    _renderWarning(canvas);
    if (animations != null) {
      super.render(canvas);
      return;
    }

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

  void _renderWarning(Canvas canvas) {
    if (_behaviorController.phase != EnemyBehaviorPhase.warning) return;
    final paint = Paint()
      ..color = const Color(0xaaffd166)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final center = Offset(size.x / 2, size.y / 2);
    if (_behaviorProfile.kind == EnemyBehaviorKind.shockwave ||
        _behaviorProfile.kind == EnemyBehaviorKind.scream) {
      canvas.drawCircle(center, _behaviorProfile.range, paint);
      return;
    }
    final direction = _behaviorController.lockedDirection;
    canvas.drawLine(
      center,
      center + Offset(direction.x, direction.y) * _behaviorProfile.range,
      paint,
    );
  }
}

EnemyBehaviorProfile _legacyProfileFor(EnemyBehaviorType type) =>
    enemyBehaviorProfileFor(switch (type) {
      EnemyBehaviorType.chase => 'chase',
      EnemyBehaviorType.swarm => 'swarm',
      EnemyBehaviorType.dash => 'dash',
      EnemyBehaviorType.tank => 'tank',
    });
