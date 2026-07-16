import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';

import '../content/safe_asset_loader.dart';
import '../models/vector_input.dart';
import '../systems/combat_feedback_tuning.dart';

enum PlayerAnimationState { idle, walking, hit, death }

abstract final class PlayerSpriteSheet {
  static const assetKey = 'player/rookie_constable_player_32.png';
  static final frameSize = Vector2.all(32);
  static const walkFrames = [0, 1, 2, 3, 4, 5];
  static const hitFrames = [6, 7];
  static const deathFrames = [8, 9, 10, 11, 12, 13, 14, 15];
  static const hitDurationSeconds = 0.20;

  static Map<PlayerAnimationState, SpriteAnimation> animations(Image image) {
    return {
      PlayerAnimationState.idle: SpriteAnimation.fromFrameData(
        image,
        SpriteAnimationData.sequenced(
          amount: 1,
          stepTime: 1,
          textureSize: frameSize,
          loop: true,
        ),
      ),
      PlayerAnimationState.walking: SpriteAnimation.fromFrameData(
        image,
        SpriteAnimationData.range(
          start: walkFrames.first,
          end: walkFrames.last,
          amount: 16,
          amountPerRow: 4,
          stepTimes: List.filled(walkFrames.length, 0.11),
          textureSize: frameSize,
          loop: true,
        ),
      ),
      PlayerAnimationState.hit: SpriteAnimation.fromFrameData(
        image,
        SpriteAnimationData.range(
          start: hitFrames.first,
          end: hitFrames.last,
          amount: 16,
          amountPerRow: 4,
          stepTimes: List.filled(hitFrames.length, 0.10),
          textureSize: frameSize,
          loop: false,
        ),
      ),
      PlayerAnimationState.death: SpriteAnimation.fromFrameData(
        image,
        SpriteAnimationData.range(
          start: deathFrames.first,
          end: deathFrames.last,
          amount: 16,
          amountPerRow: 4,
          stepTimes: List.filled(deathFrames.length, 0.12),
          textureSize: frameSize,
          loop: false,
        ),
      ),
    };
  }
}

class PlayerComponent
    extends SpriteAnimationGroupComponent<PlayerAnimationState> {
  PlayerComponent({
    required this.slotIndex,
    required this.maxHealth,
    required this.moveSpeed,
    double? currentHealth,
    Vector2? position,
    Vector2? size,
  }) : currentHealth = currentHealth ?? maxHealth,
       super(
         position: position ?? Vector2.zero(),
         size: size ?? Vector2.all(24),
         anchor: Anchor.center,
         autoResize: false,
       );

  final int slotIndex;
  double maxHealth;
  double currentHealth;
  final double moveSpeed;
  double moveSpeedMultiplier = 1;
  double _environmentalSlowFraction = 0;
  double _nextDamageAt = double.negativeInfinity;
  PlayerAnimationState visualState = PlayerAnimationState.idle;
  double _hitAnimationRemaining = 0;
  bool _isMoving = false;

  bool get isAlive => currentHealth > 0;
  double get environmentalSlowFraction => _environmentalSlowFraction;

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
    if (visualState != PlayerAnimationState.hit && isAlive) {
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

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    unawaited(_loadAnimations());
  }

  Future<void> _loadAnimations() async {
    try {
      ServicesBinding.instance;
    } on AssertionError {
      // Pure game-loop tests intentionally run without a Flutter binding.
      return;
    }
    final image = await SafeAssetLoader.load(
      load: () => findGame()!.images.load(PlayerSpriteSheet.assetKey),
      library: 'pixel_survivor player sprites',
      assetKey: PlayerSpriteSheet.assetKey,
    );
    if (image == null) return;
    animations = PlayerSpriteSheet.animations(image);
    current = visualState;
  }

  @override
  void update(double dt) {
    super.update(dt);
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

  void _setVisualState(PlayerAnimationState state) {
    visualState = state;
    if (animations != null) {
      current = state;
    }
  }

  @override
  void render(Canvas canvas) {
    if (animations != null) {
      super.render(canvas);
      return;
    }

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
}
