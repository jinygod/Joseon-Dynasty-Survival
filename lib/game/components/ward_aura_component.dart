import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

class WardAuraComponent extends PositionComponent {
  WardAuraComponent({
    required this.positionProvider,
    required this.radiusProvider,
  }) : super(anchor: Anchor.center);

  final Vector2 Function() positionProvider;
  final double Function() radiusProvider;

  @override
  void update(double dt) {
    super.update(dt);
    position.setFrom(positionProvider());
    final diameter = radiusProvider() * 2;
    size.setValues(diameter, diameter);
  }

  @override
  void render(Canvas canvas) {
    final radius = size.x / 2;
    final center = Offset(radius, radius);
    final fill = Paint()..color = const Color(0x2239d98a);
    final ring = Paint()
      ..color = const Color(0xaa9bf6c7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, fill);
    canvas.drawCircle(center, radius, ring);
    canvas.drawCircle(center, radius * .68, ring);
    for (var index = 0; index < 8; index += 1) {
      final angle = index * .7853981634;
      final point = Offset(
        center.dx + radius * .82 * math.cos(angle),
        center.dy + radius * .82 * math.sin(angle),
      );
      canvas.drawCircle(point, 3, ring);
    }
  }
}
