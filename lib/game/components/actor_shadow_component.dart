import 'dart:ui';

import 'package:flame/components.dart';

/// A presentation-only ground shadow for a root-level combat actor.
///
/// It owns no collision or gameplay state. The tiny position-only sync keeps
/// the oval fixed at the actor's foot anchor through attacks, hit flashes, and
/// atlas animation, while render-time synchronization removes ordering lag.
class ActorShadowComponent extends PositionComponent {
  ActorShadowComponent({required this.target, required double width})
    : opacity = .18,
      _paint = Paint()..color = const Color(0xff13233c).withValues(alpha: .18),
      super(
        size: Vector2(width, width * .28),
        anchor: Anchor.center,
        priority: -1,
      );

  final PositionComponent target;
  final double opacity;
  final Paint _paint;
  bool _targetWasMounted = false;

  @override
  double get width => size.x;

  /// Exactly one paint is reused for every oval draw.
  int get cachedPaintCount => 1;

  /// Updates only at render time, keeping shadow following cost out of game
  /// simulation and collision processing.
  void syncToTarget() {
    position.setFrom(target.position);
    position.y += target.size.y / 2;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _syncIfMounted();
  }

  @override
  void renderTree(Canvas canvas) {
    if (!_syncIfMounted()) {
      if (target.isRemoving || _targetWasMounted) removeFromParent();
      return;
    }
    super.renderTree(canvas);
  }

  bool _syncIfMounted() {
    if (!target.isMounted || target.isRemoving) return false;
    _targetWasMounted = true;
    syncToTarget();
    return true;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawOval(Offset.zero & size.toSize(), _paint);
  }
}
