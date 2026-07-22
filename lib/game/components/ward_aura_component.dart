import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../combat/combat_vfx_primitives.dart';
import '../content/weapon_definitions.dart';
import '../content/weapon_visual_theme.dart';

class WardAuraComponent extends PositionComponent {
  WardAuraComponent({
    required this.positionProvider,
    required this.radiusProvider,
    CombatVfxTier Function()? tierProvider,
  }) : _tierProvider = tierProvider ?? _normalTier,
       super(anchor: Anchor.center);

  final Vector2 Function() positionProvider;
  final double Function() radiusProvider;
  final CombatVfxTier Function() _tierProvider;
  CombatVfxTier get visualTier => _tierProvider();
  List<double> get guardianAngles {
    final count = visualTier == CombatVfxTier.master ? 8 : 4;
    return List<double>.generate(
      count,
      (index) => index * 2 * math.pi / count,
      growable: false,
    );
  }

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
    final theme = weaponVisualThemeFor(jangseungWard);
    final tier = visualTier;
    final fill = Paint()..color = theme.primary.withValues(alpha: .12);
    canvas.drawCircle(center, radius, fill);
    CombatVfxPrimitives.drawRuneRing(
      canvas,
      center: center,
      radius: radius * .96,
      palette: theme.palette,
      progress: .08,
      count: tier == CombatVfxTier.master ? 12 : 8,
    );
    CombatVfxPrimitives.drawRuneRing(
      canvas,
      center: center,
      radius: radius * .68,
      palette: theme.palette,
      progress: .28,
      count: tier == CombatVfxTier.master ? 8 : 4,
    );
    for (final angle in guardianAngles) {
      final point = Offset(
        center.dx + radius * .82 * math.cos(angle),
        center.dy + radius * .82 * math.sin(angle),
      );
      final path = Path()
        ..moveTo(point.dx, point.dy - 4)
        ..lineTo(point.dx + 3, point.dy + 3)
        ..lineTo(point.dx, point.dy + 1)
        ..lineTo(point.dx - 3, point.dy + 3)
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = theme.accent.withValues(alpha: .7),
      );
    }
  }
}

CombatVfxTier _normalTier() => CombatVfxTier.normal;
