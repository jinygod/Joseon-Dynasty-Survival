import 'dart:ui';

import 'package:flame/components.dart';

import '../models/vector_input.dart';

class PlayerComponent extends PositionComponent {
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
       );

  final int slotIndex;
  final double maxHealth;
  double currentHealth;
  final double moveSpeed;

  void applyInput(VectorInput input, double dt) {
    final direction = Vector2(input.x, input.y);
    if (direction.length2 > 1) {
      direction.normalize();
    }

    position.add(direction * moveSpeed * dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

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
