import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../combat/combat_vfx_primitives.dart';
import '../content/ids.dart';
import '../content/weapon_effect_atlas.dart';
import '../content/weapon_visual_theme.dart';
import 'enemy_component.dart';

class MeleeArcComponent extends PositionComponent {
  MeleeArcComponent({
    required this.weaponId,
    required this.damage,
    required this.knockback,
    required Vector2 position,
    required Vector2 direction,
    required this.range,
    this.angleRadians = math.pi * 0.7,
    this.lifetime = 0.12,
    this.tier = CombatVfxTier.normal,
  }) : direction = _normalizedDirection(direction),
       super(
         position: position,
         size: Vector2.all(range * 2),
         anchor: Anchor.center,
       );

  final WeaponId weaponId;
  final double damage;
  final double knockback;
  final Vector2 direction;
  final double range;
  final double angleRadians;
  final double lifetime;
  final CombatVfxTier tier;
  double get facingAngle => math.atan2(direction.y, direction.x);
  CombatVfxTier get visualTier => tier;
  WeaponVfxFamily get vfxFamily => weaponVisualThemeFor(weaponId).family;
  int get visualAfterimageCount =>
      weaponVisualThemeFor(weaponId).trailCountFor(tier);

  double _age = 0;
  Image? _effectImage;

  bool containsEnemy(EnemyComponent enemy) {
    final offset = enemy.position - position;
    final hitRange = range + enemy.size.x / 2;
    if (offset.length2 > hitRange * hitRange) {
      return false;
    }
    if (offset.length2 == 0) {
      return true;
    }

    offset.normalize();
    return direction.dot(offset) >= math.cos(angleRadians / 2);
  }

  @override
  void onLoad() {
    super.onLoad();
    unawaited(_loadEffect());
  }

  Future<void> _loadEffect() async {
    _effectImage = await WeaponEffectAtlas.load(this);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= lifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final center = Offset(size.x / 2, size.y / 2);
    final image = _effectImage;
    final atlasRow = WeaponEffectAtlas.rowForWeapon(weaponId);
    if (image != null && atlasRow != null) {
      final sprite = WeaponEffectAtlas.sprite(
        image,
        row: atlasRow,
        frame: WeaponEffectAtlas.frameForProgress(_age / lifetime),
      );
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..rotate(facingAngle);
      sprite.render(
        canvas,
        position: Vector2(-size.x / 2, -size.y / 2),
        size: size,
      );
      canvas.restore();
    }
    final theme = weaponVisualThemeFor(weaponId);
    final progress = (_age / lifetime).clamp(0, 1).toDouble();
    final fade = 1 - progress;
    switch (theme.family) {
      case WeaponVfxFamily.jangseungGuardian:
        _drawGuardianSeal(canvas, center, theme, progress);
      case WeaponVfxFamily.shamanBell:
        _drawBellPulse(canvas, center, theme, progress);
      case WeaponVfxFamily.dokkaebiChain:
        _drawChainSweep(canvas, center, theme, progress);
      case WeaponVfxFamily.windThunderGale:
        _drawBladeRibbons(canvas, center, theme, progress, wind: true);
      default:
        _drawBladeRibbons(canvas, center, theme, progress);
    }
    final tipAngle = facingAngle + angleRadians / 2;
    final tip =
        center + Offset(math.cos(tipAngle), math.sin(tipAngle)) * range * .9;
    CombatVfxPrimitives.drawRadialBurst(
      canvas,
      center: tip,
      radius: math.max(5, range * .1),
      palette: theme.palette,
      progress: 1 - fade,
      count: tier == CombatVfxTier.master ? 7 : 4,
      tier: tier,
    );
  }

  void _drawBladeRibbons(
    Canvas canvas,
    Offset center,
    WeaponVisualTheme theme,
    double progress, {
    bool wind = false,
  }) {
    final count = visualAfterimageCount;
    final fade = 1 - progress;
    final baseWidth = theme.trailWidth * theme.scaleFor(tier);
    for (var index = count - 1; index >= 0; index -= 1) {
      final inset = index * math.max(2, range * .055);
      final outer = math.max(2, range - inset).toDouble();
      final width = math.min(outer * .42, baseWidth * (wind ? 2.15 : 1.55));
      final start = facingAngle - angleRadians / 2 + index * .035;
      final sweep = angleRadians * (1 - index * .045);
      final path = _arcRibbon(center, outer, width, start, sweep);
      canvas.drawPath(
        path,
        Paint()
          ..color = theme.primary.withValues(
            alpha: fade * (.2 + .16 / (index + 1)),
          ),
      );
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outer - width * .28),
        start,
        sweep,
        false,
        Paint()
          ..color = theme.accent.withValues(alpha: fade * .82)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.5, width * .24)
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawGuardianSeal(
    Canvas canvas,
    Offset center,
    WeaponVisualTheme theme,
    double progress,
  ) {
    CombatVfxPrimitives.drawRuneRing(
      canvas,
      center: center,
      radius: range * .92,
      palette: theme.palette,
      progress: progress,
      count: tier == CombatVfxTier.master ? 8 : 4,
    );
    _drawBladeRibbons(canvas, center, theme, progress);
  }

  void _drawBellPulse(
    Canvas canvas,
    Offset center,
    WeaponVisualTheme theme,
    double progress,
  ) {
    final fade = 1 - progress;
    for (var index = 0; index < visualAfterimageCount + 1; index += 1) {
      canvas.drawCircle(
        center,
        range * (1 - index * .16),
        Paint()
          ..color = theme.primary.withValues(alpha: fade * (.5 - index * .09))
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.5, theme.trailWidth * (1 - index * .14)),
      );
    }
    CombatVfxPrimitives.drawRuneRing(
      canvas,
      center: center,
      radius: range * .72,
      palette: theme.palette,
      progress: progress,
      count: tier == CombatVfxTier.master ? 12 : 6,
    );
  }

  void _drawChainSweep(
    Canvas canvas,
    Offset center,
    WeaponVisualTheme theme,
    double progress,
  ) {
    _drawBladeRibbons(canvas, center, theme, progress);
    final fade = 1 - progress;
    final links = tier == CombatVfxTier.master ? 8 : 5;
    for (var index = 0; index < links; index += 1) {
      final fraction = links == 1 ? 0.0 : index / (links - 1);
      final angle = facingAngle - angleRadians / 2 + angleRadians * fraction;
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * range * .76;
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 8, height: 4),
        Paint()
          ..color = theme.accent.withValues(alpha: fade * .75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      canvas.restore();
    }
  }

  static Vector2 _normalizedDirection(Vector2 direction) {
    final result = direction.clone();
    if (result.length2 == 0) {
      result.setValues(1, 0);
    } else {
      result.normalize();
    }
    return result;
  }
}

Path _arcRibbon(
  Offset center,
  double outerRadius,
  double width,
  double start,
  double sweep,
) {
  final innerRadius = math.max(1, outerRadius - width).toDouble();
  final outer = Rect.fromCircle(center: center, radius: outerRadius);
  final inner = Rect.fromCircle(center: center, radius: innerRadius);
  final startPoint =
      center + Offset(math.cos(start), math.sin(start)) * outerRadius;
  final endAngle = start + sweep;
  final innerEnd =
      center + Offset(math.cos(endAngle), math.sin(endAngle)) * innerRadius;
  return Path()
    ..moveTo(startPoint.dx, startPoint.dy)
    ..arcTo(outer, start, sweep, false)
    ..lineTo(innerEnd.dx, innerEnd.dy)
    ..arcTo(inner, endAngle, -sweep, false)
    ..close();
}
