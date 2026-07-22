import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

class DamageNumberComponent extends PositionComponent {
  DamageNumberComponent({
    required this.damage,
    required Vector2 position,
    this.isCritical = false,
    this.isEmphasized = false,
    this.lifetime = 0.55,
    this.onExpired,
  }) : super(
         position: position,
         size: Vector2(72, 24),
         anchor: Anchor.center,
         priority: 100,
       );

  double damage;
  final bool isCritical;
  bool isEmphasized;
  final double lifetime;
  final void Function()? onExpired;

  double _age = 0;
  bool _didExpire = false;

  bool get isExpired => _age >= lifetime;

  void absorbDamage(double amount, {bool emphasize = false}) {
    if (amount > 0) damage += amount;
    isEmphasized = isEmphasized || emphasize;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    position.y -= 24 * dt;
    if (isExpired && !_didExpire) {
      _didExpire = true;
      onExpired?.call();
      removeFromParent();
    }
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    final opacity = (1 - (_age / lifetime)).clamp(0, 1).toDouble();
    final painter = TextPainter(
      text: TextSpan(
        text: damage.round().toString(),
        style: TextStyle(
          color:
              ((isCritical || isEmphasized)
                      ? const ui.Color(0xffffd166)
                      : const ui.Color(0xffffffff))
                  .withValues(alpha: opacity),
          fontSize: (isCritical || isEmphasized) ? 19 : 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          shadows: const [
            ui.Shadow(
              color: ui.Color(0xff101820),
              blurRadius: 2,
              offset: ui.Offset(1, 1),
            ),
          ],
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: size.x);
    painter.paint(
      canvas,
      ui.Offset((size.x - painter.width) / 2, (size.y - painter.height) / 2),
    );
  }
}
