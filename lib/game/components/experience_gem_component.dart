import 'dart:ui';

import 'package:flame/components.dart';

import 'player_component.dart';

class ExperienceGemComponent extends PositionComponent {
  ExperienceGemComponent({
    required this.experienceValue,
    Vector2? position,
    this.pickupRadius = 28,
    Vector2? size,
  }) : super(
         position: position ?? Vector2.zero(),
         size: size ?? Vector2.all(10),
         anchor: Anchor.center,
       );

  final int experienceValue;
  final double pickupRadius;

  bool canBePickedUpBy(PlayerComponent player, {double additionalRadius = 0}) {
    final effectiveRadius = pickupRadius + additionalRadius;
    return position.distanceToSquared(player.position) <=
        effectiveRadius * effectiveRadius;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final paint = Paint()..color = const Color(0xff7bdff2);
    final outlinePaint = Paint()
      ..color = const Color(0xfff4ead2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final center = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(center, size.x / 2, paint);
    canvas.drawCircle(center, size.x / 2, outlinePaint);
  }
}
