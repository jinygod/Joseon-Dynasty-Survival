import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';

import '../combat/attack_spec.dart';
import '../content/actor_render_sizes.dart';
import '../content/enemy_definitions.dart';
import '../content/enemy_behavior_definitions.dart';
import '../content/ids.dart';
import '../content/safe_asset_loader.dart';
import '../content/visual_asset_load_policy.dart';
import '../systems/combat_feedback_tuning.dart';
import '../systems/enemy_behavior_controller.dart';
import '../models/damage_event.dart';
import 'player_component.dart';

typedef TargetPositionProvider = Vector2? Function(Vector2 enemyPosition);
typedef NearbyEnemiesProvider = Iterable<EnemyComponent> Function();

class EnemyWarningSnapshot {
  EnemyWarningSnapshot({
    required this.kind,
    required Vector2 direction,
    required this.range,
    required this.progress,
    required this.durationSeconds,
    required this.phaseToken,
  }) : _direction = direction.clone();

  final EnemyBehaviorKind kind;
  final Vector2 _direction;
  final double range;
  final double progress;
  final double durationSeconds;
  final int phaseToken;

  Vector2 get direction => _direction.clone();
}

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
    sakkatSpecter: EnemySpriteSpec(
      assetKey: 'enemies/sakkat_specter_128.png',
      frameSize: 128,
    ),
    vengefulSpirit: EnemySpriteSpec(
      assetKey: 'monsters/vengeful_spirit_32.png',
      frameSize: 32,
    ),
    plagueCrow: EnemySpriteSpec(
      assetKey: 'enemies/plague_crow_128.png',
      frameSize: 128,
    ),
    spearBandit: EnemySpriteSpec(
      assetKey: 'enemies/spear_bandit_128.png',
      frameSize: 128,
    ),
    rottenHerbalist: EnemySpriteSpec(
      assetKey: 'enemies/rotten_herbalist_128.png',
      frameSize: 128,
    ),
    graveEmber: EnemySpriteSpec(
      assetKey: 'enemies/grave_ember_128.png',
      frameSize: 128,
    ),
    blackHatAssassin: EnemySpriteSpec(
      assetKey: 'enemies/black_hat_assassin_128.png',
      frameSize: 128,
    ),
    brokenJangseungSpirit: EnemySpriteSpec(
      assetKey: 'enemies/broken_jangseung_spirit_128.png',
      frameSize: 128,
    ),
    sorrowfulMaidenGhost: EnemySpriteSpec(
      assetKey: 'enemies/sorrowful_maiden_ghost_128.png',
      frameSize: 128,
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
         size: size ?? Vector2.all(ActorRenderSizes.enemyCollisionSize(rank)),
         anchor: Anchor.center,
         autoResize: false,
       ) {
    paint.filterQuality = FilterQuality.none;
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
  EnemyBehaviorPhase _lastBehaviorPhase = EnemyBehaviorPhase.tracking;
  int _warningPhaseToken = 0;

  static const _hitFlashSeconds = 0.18;

  double _hitFlashRemaining = 0;
  double _visualStateRemaining = 0;
  double _deathVisualElapsed = 0;
  double _environmentalSlowFraction = 0;
  double _environmentalHasteFraction = 0;
  bool _deathZonePending = false;
  bool _blockFeedbackPending = false;
  final Vector2 knockbackVelocity = Vector2.zero();
  final Vector2 facingDirection = Vector2(1, 0);
  EnemyAnimationState visualState = EnemyAnimationState.moving;

  bool get deathVisualComplete =>
      isDead && _deathVisualElapsed >= EnemySpriteSheet.deathDurationSeconds;

  bool get isDead => currentHealth <= 0;
  bool get isElite => rank == EnemyRank.elite;
  double get visualSize => ActorRenderSizes.enemyVisualSize(rank);
  double get visualScale => visualSize / size.x;
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
  bool get hasDirectionalShield => behaviorType == EnemyBehaviorType.tank;
  Vector2 get shieldDirection => facingDirection.clone();
  EnemyWarningSnapshot? get warningSnapshot {
    if (_behaviorController.phase != EnemyBehaviorPhase.warning) return null;
    return EnemyWarningSnapshot(
      kind: _behaviorProfile.kind,
      direction: _behaviorController.lockedDirection,
      range: _behaviorProfile.range,
      durationSeconds: _behaviorProfile.warningSeconds,
      phaseToken: _warningPhaseToken,
      progress: _behaviorProfile.warningSeconds <= 0
          ? 1
          : (_behaviorController.phaseElapsed / _behaviorProfile.warningSeconds)
                .clamp(0, 1)
                .toDouble(),
    );
  }

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

  bool consumeBlockFeedback() {
    if (!_blockFeedbackPending) return false;
    _blockFeedbackPending = false;
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

  double resolveIncomingDamage(DamageEvent event) {
    if (behaviorType != EnemyBehaviorType.tank) return event.damage;
    if (event.traits.contains(AttackTrait.explosion) ||
        event.traits.contains(AttackTrait.synergy)) {
      return event.damage;
    }
    final frontal =
        facingDirection.dot(-event.direction) >= math.cos(math.pi / 3);
    if (!frontal) return event.damage;
    final reduction = event.traits.contains(AttackTrait.piercing) ? .2 : .5;
    _blockFeedbackPending = true;
    return event.damage * (1 - reduction);
  }

  void debugFace(Vector2 direction) => _face(direction);

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

    _face(direction);
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
      final hasLockedAttackFacing =
          _behaviorProfile.kind == EnemyBehaviorKind.ranged &&
          (_behaviorController.phase == EnemyBehaviorPhase.warning ||
              _behaviorController.phase == EnemyBehaviorPhase.active);
      if (_behaviorController.phase == EnemyBehaviorPhase.warning ||
          hasLockedAttackFacing) {
        _face(_behaviorController.lockedDirection);
      }
      if (isDashing) {
        _face(_behaviorController.lockedDirection);
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
        } else if (_behaviorProfile.kind == EnemyBehaviorKind.ranged) {
          final speed = behavior.movementMultiplier.abs();
          if (speed > 0) {
            if (!hasLockedAttackFacing) _face(behavior.movementDirection);
            position.add(
              behavior.movementDirection * effectiveMoveSpeed * speed * dt,
            );
            playMove();
          }
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
      if (_lastBehaviorPhase != EnemyBehaviorPhase.warning &&
          _behaviorController.phase == EnemyBehaviorPhase.warning) {
        _warningPhaseToken += 1;
      }
      _lastBehaviorPhase = _behaviorController.phase;
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
    _face(direction);
    position.add(direction * effectiveMoveSpeed * dt);
  }

  void _face(Vector2 direction) {
    if (direction.length2 <= .0001) return;
    facingDirection.setFrom(direction.normalized());
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
    canvas.save();
    canvas.translate(size.x / 2, size.y);
    canvas.scale(visualScale);
    canvas.translate(-size.x / 2, -size.y);
    super.render(canvas);

    if (animations == null) {
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

      if (enemyId == sakkatSpecter) {
        final centerX = size.x / 2;
        final hat = Path()
          ..moveTo(1, size.y * .38)
          ..lineTo(centerX, 1)
          ..lineTo(size.x - 1, size.y * .38)
          ..close();
        canvas.drawPath(hat, bodyPaint);
        canvas.drawPath(hat, outlinePaint);
        final body = Path()
          ..moveTo(size.x * .31, size.y * .36)
          ..quadraticBezierTo(size.x * .2, size.y * .76, centerX, size.y - 1)
          ..quadraticBezierTo(
            size.x * .8,
            size.y * .76,
            size.x * .69,
            size.y * .36,
          )
          ..close();
        canvas.drawPath(body, bodyPaint);
        canvas.drawPath(body, outlinePaint);
      } else {
        final rect = Offset.zero & Size(size.x, size.y);
        canvas.drawRect(rect, bodyPaint);
        canvas.drawRect(rect, outlinePaint);
      }
    }
    canvas.restore();
    if (hasDirectionalShield) {
      final angle = math.atan2(facingDirection.y, facingDirection.x);
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(size.x / 2, size.y / 2),
          radius: size.x * .58,
        ),
        angle - math.pi / 3,
        math.pi * 2 / 3,
        false,
        Paint()
          ..color = const Color(0xffbde0fe)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
  }
}

EnemyBehaviorProfile _legacyProfileFor(EnemyBehaviorType type) =>
    enemyBehaviorProfileFor(switch (type) {
      EnemyBehaviorType.chase => 'chase',
      EnemyBehaviorType.swarm => 'swarm',
      EnemyBehaviorType.dash => 'dash',
      EnemyBehaviorType.tank => 'tank',
    });
