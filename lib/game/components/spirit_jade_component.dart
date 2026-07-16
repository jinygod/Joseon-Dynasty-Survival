import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../balance/meta_reward_balance.dart';
import '../content/combat_effect_atlas.dart';
import 'player_component.dart';

class SpiritJadePickup {
  const SpiritJadePickup({
    required this.pickupId,
    required this.claimsFirstBossReward,
  });

  final String pickupId;
  final bool claimsFirstBossReward;
}

typedef SpiritJadePersistence = Future<bool> Function(SpiritJadePickup pickup);

class SpiritJadeComponent extends PositionComponent {
  SpiritJadeComponent({
    required this.pickup,
    required this.persistPickup,
    required this.onCollected,
    required this.isBossDrop,
    Vector2? position,
    this.pickupRadius = 28,
  }) : super(
         position: position ?? Vector2.zero(),
         size: Vector2.all(14),
         anchor: Anchor.center,
       );

  final SpiritJadePickup pickup;
  final SpiritJadePersistence persistPickup;
  final void Function() onCollected;
  final bool isBossDrop;
  final double pickupRadius;

  bool _saving = false;
  double _retryRemaining = 0;
  double _age = 0;
  Image? _atlasImage;

  bool get isSaving => _saving;
  bool get canRetry => !_saving && _retryRemaining <= 0;

  @override
  void onLoad() {
    super.onLoad();
    unawaited(_loadAtlas());
  }

  Future<void> _loadAtlas() async {
    _atlasImage = await CombatEffectAtlas.load(this);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_retryRemaining > 0) {
      _retryRemaining -= dt;
    }
    scale.setAll(_saving ? 0.9 + 0.08 * sin(_age * 8).abs() : 1);
  }

  bool canBePickedUpBy(PlayerComponent player, {double additionalRadius = 0}) {
    final effectiveRadius = pickupRadius + additionalRadius;
    return position.distanceToSquared(player.position) <=
        effectiveRadius * effectiveRadius;
  }

  Future<bool> tryCollect() async {
    if (!canRetry || isRemoving) return false;
    _saving = true;
    try {
      final persisted = await persistPickup(pickup);
      if (!persisted) {
        _retryRemaining = MetaRewardBalance.failedPickupRetrySeconds;
        return false;
      }
      onCollected();
      removeFromParent();
      return true;
    } on Object {
      _retryRemaining = MetaRewardBalance.failedPickupRetrySeconds;
      return false;
    } finally {
      _saving = false;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final image = _atlasImage;
    if (image != null) {
      CombatEffectAtlas.sprite(
        image,
        kind: CombatEffectKind.experience,
        frame: ((_age / 0.10).floor()) % CombatEffectAtlas.framesPerEffect,
      ).render(canvas, size: size);
    }
    final center = Offset(size.x / 2, size.y / 2);
    final path = Path()
      ..moveTo(center.dx, 0)
      ..lineTo(size.x, center.dy)
      ..lineTo(center.dx, size.y)
      ..lineTo(0, center.dy)
      ..close();
    if (image == null) {
      canvas.drawPath(path, Paint()..color = const Color(0xffd99cff));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xfffff1b8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
}
