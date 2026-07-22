import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';

import '../content/actor_render_sizes.dart';
import '../content/actor_visual_spec.dart';
import '../content/character_definitions.dart';
import '../content/ids.dart';
import '../content/safe_asset_loader.dart';
import '../content/visual_asset_load_policy.dart';
import '../models/vector_input.dart';
import '../systems/combat_feedback_tuning.dart';

enum PlayerAnimationState { idle, walking, attacking, hit, death }

abstract final class PlayerSpriteSheet {
  // Legacy single-frame art remains the fallback for characters that have not
  // received an authored atlas yet.
  static const assetKey = 'player/exorcist_swordswoman_static_64.png';
  static final frameSize = Vector2.all(64);
  static final displaySize = Vector2.all(ActorRenderSizes.playerVisual);
  static const frameCount = 1;
  static const authoredAssetKey = 'player/exorcist_dosa_128.png';
  static final authoredFrameSize = Vector2.all(128);
  static const idleFrames = [0];
  static const moveFrames = [0, 1, 2, 3];
  static const attackFrames = [4, 5, 6, 7];
  static const hitFrames = [8, 9];
  static const deathFrames = [10, 11, 12, 13, 14, 15];
  static const attackDurationSeconds = 0.28;
  static const hitDurationSeconds = 0.20;

  static Sprite sprite(Image image) => Sprite(image, srcSize: frameSize);

  static Map<PlayerAnimationState, SpriteAnimation> animations(Image image) {
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
        textureSize: authoredFrameSize,
        loop: loop,
      ),
    );

    return {
      PlayerAnimationState.idle: animation(idleFrames, 1),
      PlayerAnimationState.walking: animation(moveFrames, 0.11),
      PlayerAnimationState.attacking: animation(
        attackFrames,
        attackDurationSeconds / attackFrames.length,
        loop: false,
      ),
      PlayerAnimationState.hit: animation(hitFrames, 0.10, loop: false),
      PlayerAnimationState.death: animation(deathFrames, 0.11, loop: false),
    };
  }
}

class PlayerComponent
    extends SpriteAnimationGroupComponent<PlayerAnimationState> {
  static const attackPoseDurationSeconds =
      PlayerSpriteSheet.attackDurationSeconds;

  PlayerComponent({
    required this.slotIndex,
    this.characterId = rookieConstable,
    required this.maxHealth,
    required this.moveSpeed,
    double? currentHealth,
    Vector2? position,
    Vector2? size,
  }) : currentHealth = currentHealth ?? maxHealth,
       super(
         position: position ?? Vector2.zero(),
         size: size ?? Vector2.all(ActorRenderSizes.playerCollision),
         anchor: Anchor.center,
         autoResize: false,
       ) {
    paint.filterQuality =
        characterId == rookieConstable || characterId == exorcistDosa
        ? FilterQuality.medium
        : FilterQuality.none;
  }

  final int slotIndex;
  final CharacterId characterId;
  double maxHealth;
  double currentHealth;
  final double moveSpeed;
  double moveSpeedMultiplier = 1;
  double _environmentalSlowFraction = 0;
  double _nextDamageAt = double.negativeInfinity;
  PlayerAnimationState visualState = PlayerAnimationState.idle;
  double _hitAnimationRemaining = 0;
  bool _isMoving = false;
  Sprite? _sprite;
  Vector2? _lastMovementDirection;
  Vector2? _lastAttackDirection;
  double _motionBlend = 0;
  double _motionPhase = 0;
  double _desiredFacingX = 1;
  double _displayedFacingX = 1;
  double _attackPoseRemaining = 0;

  bool get isAlive => currentHealth > 0;
  bool get isMoving => _isMoving;
  bool get isAttacking => _attackPoseRemaining > 0;
  bool get usesAuthoredAtlas =>
      characterId == rookieConstable || characterId == exorcistDosa;
  String get visualAssetKey => usesAuthoredAtlas
      ? PlayerSpriteSheet.authoredAssetKey
      : PlayerSpriteSheet.assetKey;
  bool get isFacingLeft => _desiredFacingX < 0;
  double get displayedFacingX => _displayedFacingX;
  double get motionBlend => _motionBlend;
  double get environmentalSlowFraction => _environmentalSlowFraction;
  Vector2? get lastMovementDirection => _lastMovementDirection?.clone();
  Vector2? get lastAttackDirection => _lastAttackDirection?.clone();
  Vector2 get displaySize =>
      Vector2.all(playerVisualSpecFor(characterId).visualSize);
  Vector2 get preferredAttackDirection =>
      (_lastMovementDirection ?? _lastAttackDirection ?? Vector2(1, 0)).clone();
  Color get worldHealthBarColor => healthFraction <= .2
      ? const Color(0xffef5b5b)
      : healthFraction <= .35
      ? const Color(0xffffc857)
      : const Color(0xff39d98a);

  void setEnvironmentalSlow(double fraction) {
    if (!fraction.isFinite || fraction < 0 || fraction >= .8) {
      throw ArgumentError.value(fraction, 'fraction', 'Must be from 0 to 0.8');
    }
    _environmentalSlowFraction = fraction;
  }

  double get healthFraction {
    if (maxHealth <= 0) {
      return 0;
    }

    return (currentHealth / maxHealth).clamp(0, 1).toDouble();
  }

  bool takeDamage(double amount, {double? now}) {
    if (amount <= 0 || !isAlive) {
      return false;
    }
    if (now != null && now < _nextDamageAt) {
      return false;
    }

    currentHealth = (currentHealth - amount).clamp(0, maxHealth).toDouble();
    if (now != null) {
      _nextDamageAt = now + CombatFeedbackTuning.playerInvulnerabilitySeconds;
    }
    _attackPoseRemaining = 0;
    if (isAlive) {
      _hitAnimationRemaining = PlayerSpriteSheet.hitDurationSeconds;
      _setVisualState(PlayerAnimationState.hit);
    } else {
      _setVisualState(PlayerAnimationState.death);
    }
    return true;
  }

  void heal(double amount) {
    if (amount <= 0 || !isAlive) {
      return;
    }

    currentHealth = (currentHealth + amount).clamp(0, maxHealth).toDouble();
  }

  void increaseMaxHealth(double amount, {double healAmount = 0}) {
    if (amount <= 0) {
      return;
    }

    maxHealth += amount;
    heal(healAmount);
  }

  void applyInput(VectorInput input, double dt, {Vector2? bounds}) {
    final direction = Vector2(input.x, input.y);
    _isMoving = direction.length2 > 0;
    if (_isMoving) {
      final normalizedDirection = direction.normalized();
      _lastMovementDirection = normalizedDirection;
      if (!isAttacking && normalizedDirection.x.abs() > 0.05) {
        _desiredFacingX = normalizedDirection.x.sign;
      }
    }
    if (visualState != PlayerAnimationState.hit && !isAttacking && isAlive) {
      _setVisualState(
        _isMoving ? PlayerAnimationState.walking : PlayerAnimationState.idle,
      );
    }
    if (direction.length2 > 1) {
      direction.normalize();
    }

    position.add(
      direction *
          moveSpeed *
          moveSpeedMultiplier *
          (1 - _environmentalSlowFraction) *
          dt,
    );
    if (bounds != null) {
      final minX = size.x / 2;
      final minY = size.y / 2;
      final maxX = bounds.x - minX;
      final maxY = bounds.y - minY;

      position
        ..x = maxX < minX
            ? bounds.x / 2
            : position.x.clamp(minX, maxX).toDouble()
        ..y = maxY < minY
            ? bounds.y / 2
            : position.y.clamp(minY, maxY).toDouble();
    }
  }

  bool playAttack(Vector2 direction) {
    if (!isAlive ||
        visualState == PlayerAnimationState.hit ||
        visualState == PlayerAnimationState.death) {
      return false;
    }
    final normalizedDirection = direction.length2 == 0
        ? Vector2(1, 0)
        : direction.normalized();
    _lastAttackDirection = normalizedDirection;
    if (normalizedDirection.x.abs() > 0.05) {
      _desiredFacingX = normalizedDirection.x.sign;
    }
    _attackPoseRemaining = attackPoseDurationSeconds;
    _setVisualState(PlayerAnimationState.attacking);
    // Assigning the same group state does not reset Flame's ticker. Multi-hit
    // hwando sequences can request another slash before the prior pose ends,
    // so restart explicitly even when `attacking` is already current.
    animationTicker?.reset();
    return true;
  }

  @override
  void onLoad() {
    super.onLoad();
    if (shouldLoadVisualAssets(this)) unawaited(_loadAnimations());
  }

  Future<void> _loadAnimations() async {
    try {
      ServicesBinding.instance;
    } on AssertionError {
      // Pure game-loop tests intentionally run without a Flutter binding.
      return;
    }
    final image = await SafeAssetLoader.load(
      load: () => findGame()!.images.load(visualAssetKey),
      library: 'pixel_survivor player sprites',
      assetKey: visualAssetKey,
    );
    if (image == null) return;
    if (usesAuthoredAtlas) {
      animations = PlayerSpriteSheet.animations(image);
      current = visualState;
    } else {
      _sprite = PlayerSpriteSheet.sprite(image);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _updateProceduralPose(dt);
    if (visualState == PlayerAnimationState.attacking && !isAttacking) {
      _setVisualState(
        _isMoving ? PlayerAnimationState.walking : PlayerAnimationState.idle,
      );
    }
    if (visualState != PlayerAnimationState.hit) {
      return;
    }

    _hitAnimationRemaining -= dt;
    if (_hitAnimationRemaining <= 0) {
      _setVisualState(
        _isMoving ? PlayerAnimationState.walking : PlayerAnimationState.idle,
      );
    }
  }

  void _updateProceduralPose(double dt) {
    final safeDt = dt.clamp(0, 0.05).toDouble();
    final targetBlend = _isMoving ? 1.0 : 0.0;
    final blendRate = _isMoving ? 12.0 : 8.0;
    final blendFactor = 1 - math.exp(-blendRate * safeDt);
    _motionBlend += (targetBlend - _motionBlend) * blendFactor;
    if (_motionBlend < 0.0001) _motionBlend = 0;
    if (_isMoving || _motionBlend > 0) {
      _motionPhase = (_motionPhase + safeDt * 10) % (math.pi * 2);
    }

    _displayedFacingX = _desiredFacingX;
    final timerDt = dt.isFinite && dt > 0 ? dt : 0.0;
    _attackPoseRemaining = math.max(0, _attackPoseRemaining - timerDt);
  }

  void _setVisualState(PlayerAnimationState state) {
    visualState = state;
    if (animations != null) {
      current = state;
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    _applyProceduralPose(canvas);
    if (animations != null) {
      final renderScale = displaySize.x / size.x;
      canvas
        ..translate(size.x / 2, size.y)
        ..scale(renderScale)
        ..translate(-size.x / 2, -size.y);
      super.render(canvas);
    } else if (_sprite case final sprite?) {
      sprite.render(
        canvas,
        position: Vector2((size.x - displaySize.x) / 2, size.y - displaySize.y),
        size: displaySize,
        overridePaint: paint,
      );
    } else {
      final bodyPaint = Paint()..color = const Color(0xff5cc8ff);
      final outlinePaint = Paint()
        ..color = const Color(0xfff4ead2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      final center = Offset(size.x / 2, size.y / 2);
      final radius = size.x < size.y ? size.x / 2 : size.y / 2;
      canvas.drawCircle(center, radius, bodyPaint);
      canvas.drawCircle(center, radius, outlinePaint);
    }
    canvas.restore();
    if (isAlive) _renderWorldHealthBar(canvas);
  }

  void _renderWorldHealthBar(Canvas canvas) {
    const width = 30.0;
    const height = 5.0;
    const inset = 1.0;
    final left = (size.x - width) / 2;
    final top = size.y + 3;
    final outer = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, width, height).shift(Offset(left, top)),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(outer, Paint()..color = const Color(0xdd101820));
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        left + inset,
        top + inset,
        width - inset * 2,
        height - inset * 2,
      ),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(track, Paint()..color = const Color(0xff3a2830));
    final fillWidth = (width - inset * 2) * healthFraction;
    if (fillWidth <= 0) return;
    final fill = RRect.fromRectAndRadius(
      Rect.fromLTWH(left + inset, top + inset, fillWidth, height - inset * 2),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(fill, Paint()..color = worldHealthBarColor);
  }

  void _applyProceduralPose(Canvas canvas) {
    final walkWave = math.sin(_motionPhase);
    final bob = -walkWave.abs() * 1.6 * _motionBlend;
    final walkTilt = walkWave * 0.025 * _motionBlend;
    final walkStretch = walkWave.abs() * 0.025 * _motionBlend;

    var attackPulse = 0.0;
    var attackTilt = 0.0;
    final attackDirection = _lastAttackDirection;
    if (isAttacking && attackDirection != null) {
      final elapsed = 1 - _attackPoseRemaining / attackPoseDurationSeconds;
      attackPulse = math.sin(math.pi * elapsed.clamp(0, 1));
      attackTilt = (attackDirection.x < 0 ? 1 : -1) * 0.07 * attackPulse;
    }

    final pivot = Offset(size.x / 2, size.y);
    canvas
      ..translate(pivot.dx, pivot.dy)
      ..translate(
        (attackDirection?.x ?? 0) * 3.5 * attackPulse,
        bob + (attackDirection?.y ?? 0) * 3.5 * attackPulse,
      )
      ..rotate(walkTilt + attackTilt)
      ..scale(_displayedFacingX * (1 + walkStretch), 1 - walkStretch)
      ..translate(-pivot.dx, -pivot.dy);
  }
}
