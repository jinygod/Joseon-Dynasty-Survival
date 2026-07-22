import 'dart:ui';

import 'package:flame/components.dart';

/// A presentation-only ground shadow for a root-level combat actor.
///
/// It reads its target just before rendering instead of owning an update loop,
/// collision shape, or gameplay state. This keeps the oval fixed at the
/// actor's foot anchor through attacks, hit flashes, and atlas animation.
class ActorShadowComponent extends PositionComponent {
  ActorShadowComponent({required this.target, required double width})
    : opacity = .18,
      super(
        size: Vector2(width, width * .28),
        anchor: Anchor.center,
        priority: -1,
      );

  final PositionComponent target;
  final double opacity;

  /// Updates only at render time, keeping shadow following cost out of game
  /// simulation and collision processing.
  void syncToTarget() {
    position.setFrom(target.position);
    position.y += target.size.y / 2;
  }

  @override
  void renderTree(Canvas canvas) {
    if (!target.isMounted || target.isRemoving) {
      removeFromParent();
      return;
    }
    syncToTarget();
    super.renderTree(canvas);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawOval(
      Offset.zero & size.toSize(),
      Paint()..color = const Color(0xff13233c).withValues(alpha: opacity),
    );
  }
}
