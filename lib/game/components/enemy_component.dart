import 'dart:ui';

import 'package:flame/components.dart';

import '../content/ids.dart';

typedef TargetPositionProvider = Vector2? Function(Vector2 enemyPosition);

class EnemyComponent extends PositionComponent {
  EnemyComponent({
    required this.enemyId,
    required this.maxHealth,
    required this.moveSpeed,
    required this.damage,
    this.experienceValue = 1,
    this.targetPositionProvider,
    double? currentHealth,
    Vector2? position,
    Vector2? size,
  }) : currentHealth = currentHealth ?? maxHealth,
       super(
         position: position ?? Vector2.zero(),
         size: size ?? Vector2.all(18),
         anchor: Anchor.center,
       );

  final EnemyId enemyId;
  final double maxHealth;
  double currentHealth;
  final double moveSpeed;
  final double damage;
  final int experienceValue;
  final TargetPositionProvider? targetPositionProvider;

  bool get isDead => currentHealth <= 0;

  void takeDamage(double amount) {
    currentHealth = (currentHealth - amount).clamp(0, maxHealth).toDouble();
  }

  void moveToward(Vector2 target, double dt) {
    final delta = target - position;
    if (delta.length2 == 0) {
      return;
    }

    delta.normalize();
    position.add(delta * moveSpeed * dt);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final target = targetPositionProvider?.call(position);
    if (target != null && !isDead) {
      moveToward(target, dt);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final bodyPaint = Paint()..color = const Color(0xffd1495b);
    final outlinePaint = Paint()
      ..color = const Color(0xff2f1b25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = Offset.zero & Size(size.x, size.y);
    canvas.drawRect(rect, bodyPaint);
    canvas.drawRect(rect, outlinePaint);
  }
}
