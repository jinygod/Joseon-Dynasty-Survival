import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../combat/attack_spec.dart';
import '../combat/combat_vfx_primitives.dart';
import '../combat/combat_visual_theme.dart';
import '../content/weapon_visual_theme.dart';
import '../content/safe_asset_loader.dart';
import '../content/visual_asset_load_policy.dart';
import 'talisman_presentation_component.dart';

class AttackEffectComponent extends PositionComponent {
  AttackEffectComponent({required this.instance, this.onExpired})
    : visualGeometry = AttackVisualGeometry.fromAttack(instance),
      visualTheme = CombatVisualTheme.forAttack(instance),
      super(
        position: instance.origin,
        priority: AttackPresentationPriority.attack,
      );

  final AttackInstance instance;
  final AttackVisualGeometry visualGeometry;
  final CombatVisualTheme visualTheme;
  final void Function()? onExpired;
  CombatVfxTier get visualTier =>
      combatVfxTierForPresentation(instance.spec.presentation);
  WeaponVfxFamily get vfxFamily => weaponVfxFamilyForAttackId(instance.spec.id);
  bool get usesHwandoRaster =>
      vfxFamily == WeaponVfxFamily.hwandoBlade &&
      (visualGeometry.shape == AttackShape.sector ||
          visualGeometry.shape == AttackShape.circle);
  String get hwandoRasterAssetKey => 'effects/hwando_slash_ribbon_512.png';
  static const synergySlashColor = Color(0xffffd166);
  static const synergyFragmentColors = <Color>[
    Color(0xff3b82f6),
    Color(0xffef4444),
    Color(0xfffacc15),
    Color(0xfff8fafc),
    Color(0xff111827),
  ];
  double _age = 0;
  bool _expired = false;
  Image? _hwandoRaster;

  @override
  void onLoad() {
    super.onLoad();
    if (usesHwandoRaster && shouldLoadVisualAssets(this)) {
      unawaited(_loadHwandoRaster());
    }
  }

  Future<void> _loadHwandoRaster() async {
    final image = await SafeAssetLoader.load(
      load: () => findGame()!.images.load(hwandoRasterAssetKey),
      library: 'pixel_survivor weapon effects',
      assetKey: hwandoRasterAssetKey,
      reportErrors: false,
    );
    if (image != null) _hwandoRaster = image;
  }

  double get _lifetime => math.max(
    .001,
    visualGeometry.activeSeconds + visualGeometry.lingerSeconds,
  );

  double get _trailFade {
    final trailLifetime = math.min(_lifetime, visualTheme.trailLifetimeSeconds);
    return 1 - (_age / math.max(.001, trailLifetime)).clamp(0, 1).toDouble();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (!_expired && _age >= _lifetime) {
      _expired = true;
      onExpired?.call();
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final direction = visualGeometry.direction;
    final heading = math.atan2(direction.y, direction.x);
    final progress = (_age / _lifetime).clamp(0, 1).toDouble();
    final fade = (1 - progress) * visualTheme.maxAlpha;
    final edgePaint = Paint()
      ..color = visualTheme.edgeColor.withValues(alpha: fade * .82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = visualTheme.strokeWidth
      ..strokeCap = StrokeCap.round;
    final corePaint = Paint()
      ..color = visualTheme.coreColor.withValues(alpha: fade)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2, visualTheme.strokeWidth * .42)
      ..strokeCap = StrokeCap.round;
    final palette = CombatVfxPalette(
      core: visualTheme.coreColor,
      edge: visualTheme.edgeColor,
      accent: instance.spec.presentation == AttackPresentation.master
          ? const Color(0xffffd166)
          : visualTheme.coreColor,
      smoke: const Color(0xff53606c),
    );
    final hwandoRaster = _hwandoRaster;
    if (hwandoRaster != null && usesHwandoRaster) {
      final steppedProgress = (progress * 12).floor() / 12;
      _drawHwandoRaster(
        canvas,
        hwandoRaster,
        heading: heading,
        progress: steppedProgress,
        fade: (1 - steppedProgress) * visualTheme.maxAlpha,
      );
      return;
    }

    switch (visualGeometry.shape) {
      case AttackShape.sector:
        _drawSector(canvas, heading, progress, edgePaint, corePaint);
      case AttackShape.circle:
        switch (visualTheme.family) {
          case CombatVisualFamily.synergy:
            _drawSealingSlash(canvas, progress, edgePaint, corePaint);
          case CombatVisualFamily.hwando:
            _drawHwandoStorm(canvas, progress, edgePaint, corePaint);
          case CombatVisualFamily.talisman:
            _drawTalismanBurst(canvas, progress, edgePaint, corePaint);
          case CombatVisualFamily.neutral:
            canvas
              ..drawCircle(Offset.zero, visualGeometry.radius, edgePaint)
              ..drawCircle(Offset.zero, visualGeometry.radius * .78, corePaint);
        }
      case AttackShape.line:
        final end = Offset(
          direction.x * visualGeometry.range,
          direction.y * visualGeometry.range,
        );
        CombatVfxPrimitives.drawTaperedTrail(
          canvas,
          start: Offset.zero,
          end: end,
          startWidth: math.max(2, visualGeometry.width * .24),
          endWidth: math.max(1, visualGeometry.width * .08),
          palette: palette,
          progress: progress,
          count: visualTier == CombatVfxTier.master ? 3 : 1,
          tier: visualTier,
        );
        canvas.drawLine(
          Offset.zero,
          end,
          corePaint
            ..strokeWidth = math.max(
              visualGeometry.width * .3,
              corePaint.strokeWidth,
            ),
        );
        CombatVfxPrimitives.drawRadialBurst(
          canvas,
          center: end,
          radius: math.max(5, visualGeometry.width * 1.2),
          palette: palette,
          progress: progress,
          count: visualTier == CombatVfxTier.master ? 8 : 4,
          tier: visualTier,
        );
    }
  }

  void _drawHwandoRaster(
    Canvas canvas,
    Image image, {
    required double heading,
    required double progress,
    required double fade,
  }) {
    final source = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final radius = visualGeometry.shape == AttackShape.circle
        ? visualGeometry.radius
        : visualGeometry.range;
    final extent = radius * (visualTier == CombatVfxTier.master ? 2.5 : 2.2);
    final destination = Rect.fromCenter(
      center: Offset.zero,
      width: extent,
      height: extent,
    );
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..color = Color.fromRGBO(255, 255, 255, fade.clamp(0, 1));

    canvas.save();
    if (visualGeometry.shape == AttackShape.sector) {
      canvas.rotate(heading);
      final clipRadius = visualGeometry.range * 1.12;
      final clipRect = Rect.fromCircle(center: Offset.zero, radius: clipRadius);
      final halfSweep = visualGeometry.angleRadians / 2;
      final clip = Path()
        ..moveTo(0, 0)
        ..arcTo(clipRect, -halfSweep, visualGeometry.angleRadians, false)
        ..close();
      canvas.clipPath(clip);
      canvas.drawImageRect(image, source, destination, paint);
    } else {
      canvas.rotate(progress * .35);
      if (visualTier == CombatVfxTier.master) {
        canvas.save();
        canvas.rotate(math.pi);
        canvas.drawImageRect(
          image,
          source,
          destination.deflate(radius * .08),
          Paint()
            ..filterQuality = FilterQuality.high
            ..color = Color.fromRGBO(255, 210, 135, fade * .55),
        );
        canvas.restore();
      }
      canvas.drawImageRect(image, source, destination, paint);
    }
    canvas.restore();
  }

  void _drawSector(
    Canvas canvas,
    double heading,
    double progress,
    Paint edgePaint,
    Paint corePaint,
  ) {
    final rect = Rect.fromCircle(
      center: Offset.zero,
      radius: visualGeometry.range,
    );
    final start = heading - visualGeometry.angleRadians / 2;
    final ribbonWidth = math.min(
      visualGeometry.range * .34,
      visualTheme.strokeWidth * visualTier.scale * 1.7,
    );
    canvas.drawPath(
      _sectorRibbon(
        visualGeometry.range,
        ribbonWidth,
        start,
        visualGeometry.angleRadians,
      ),
      Paint()
        ..color = visualTheme.edgeColor.withValues(
          alpha: visualTheme.maxAlpha * (1 - progress) * .34,
        ),
    );
    canvas
      ..drawArc(rect, start, visualGeometry.angleRadians, false, edgePaint)
      ..drawArc(rect, start, visualGeometry.angleRadians, false, corePaint);

    final trailCount = visualTheme.afterimageCount.clamp(0, 3);
    for (var index = 1; index <= trailCount; index += 1) {
      final scale = 1 - index * .09;
      final trailRect = Rect.fromCircle(
        center: Offset.zero,
        radius: visualGeometry.range * scale,
      );
      canvas.drawArc(
        trailRect,
        start,
        visualGeometry.angleRadians * (1 - index * .04),
        false,
        Paint()
          ..color = visualTheme.coreColor.withValues(
            alpha: visualTheme.maxAlpha * _trailFade * (.25 / index),
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(2, visualTheme.strokeWidth * .2)
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawTalismanBurst(
    Canvas canvas,
    double progress,
    Paint edgePaint,
    Paint corePaint,
  ) {
    final radius = visualGeometry.radius;
    final palette = CombatVfxPalette(
      core: visualTheme.coreColor,
      edge: visualTheme.edgeColor,
      accent: const Color(0xfffff4c2),
      smoke: const Color(0xff6c4d5d),
    );
    canvas
      ..drawCircle(
        Offset.zero,
        radius * (.86 + progress * .14),
        Paint()
          ..color = visualTheme.coreColor.withValues(
            alpha: visualTheme.maxAlpha * .18 * (1 - progress),
          ),
      )
      ..drawCircle(Offset.zero, radius, edgePaint)
      ..drawCircle(Offset.zero, radius * .76, corePaint);
    CombatVfxPrimitives.drawRuneRing(
      canvas,
      center: Offset.zero,
      radius: radius * .82,
      palette: palette,
      progress: progress,
      count: visualTier == CombatVfxTier.master ? 12 : 6,
    );
    CombatVfxPrimitives.drawRadialBurst(
      canvas,
      center: Offset.zero,
      radius: radius,
      palette: palette,
      progress: progress,
      count: visualTier == CombatVfxTier.master ? 12 : 7,
      tier: visualTier,
    );
    for (var index = 0; index < 4; index += 1) {
      final angle = index * math.pi / 2 + progress * .8;
      final center = Offset(math.cos(angle), math.sin(angle)) * radius * .55;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle + math.pi / 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-3, -7, 6, 14),
          const Radius.circular(1),
        ),
        Paint()
          ..color = const Color(
            0xfffff4c2,
          ).withValues(alpha: visualTheme.maxAlpha * (1 - progress)),
      );
      canvas.restore();
    }
  }

  void _drawHwandoStorm(
    Canvas canvas,
    double progress,
    Paint edgePaint,
    Paint corePaint,
  ) {
    final radius = visualGeometry.radius;
    canvas
      ..drawCircle(Offset.zero, radius, edgePaint)
      ..drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius * .78),
        -math.pi / 2 + progress * math.pi,
        math.pi * 1.7,
        false,
        corePaint,
      );
    for (var index = 1; index <= visualTheme.afterimageCount; index += 1) {
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset.zero,
          radius: radius * (1 - index * .12),
        ),
        -math.pi / 2 - index * .28 + progress * math.pi,
        math.pi * (1.5 - index * .12),
        false,
        Paint()
          ..color = visualTheme.coreColor.withValues(
            alpha: visualTheme.maxAlpha * _trailFade * (.32 / index),
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(2, visualTheme.strokeWidth * .22)
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawSealingSlash(
    Canvas canvas,
    double progress,
    Paint edgePaint,
    Paint corePaint,
  ) {
    final radius = visualGeometry.radius;
    canvas
      ..drawCircle(Offset.zero, radius, edgePaint)
      ..drawCircle(Offset.zero, radius * .78, corePaint);
    final crackPaint = Paint()
      ..color = synergySlashColor.withValues(
        alpha: visualTheme.maxAlpha * (1 - progress),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(3, visualTheme.strokeWidth * .55)
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 5; index += 1) {
      final angle = -math.pi / 2 + index * math.pi * 2 / 5;
      final unit = Offset(math.cos(angle), math.sin(angle));
      final side = Offset(-unit.dy, unit.dx);
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(
          unit.dx * radius * .32 + side.dx * radius * .08,
          unit.dy * radius * .32 + side.dy * radius * .08,
        )
        ..lineTo(unit.dx * radius * .7, unit.dy * radius * .7);
      canvas.drawPath(path, crackPaint);
    }
    _drawSynergyFragments(canvas, radius, progress);
  }

  void _drawSynergyFragments(Canvas canvas, double radius, double progress) {
    final innerRadius = radius * .62;
    final outerRadius = radius * .88;
    for (var index = 0; index < synergyFragmentColors.length; index += 1) {
      final angle = -math.pi / 2 + index * math.pi * 2 / 5;
      final direction = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        direction * innerRadius,
        direction * outerRadius,
        Paint()
          ..color = synergyFragmentColors[index].withValues(
            alpha: visualTheme.maxAlpha * .72 * (1 - progress),
          )
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
  }
}

Path _sectorRibbon(double radius, double width, double start, double sweep) {
  final innerRadius = math.max(1, radius - width).toDouble();
  final outer = Rect.fromCircle(center: Offset.zero, radius: radius);
  final inner = Rect.fromCircle(center: Offset.zero, radius: innerRadius);
  final startPoint = Offset(math.cos(start), math.sin(start)) * radius;
  final endAngle = start + sweep;
  final innerEnd = Offset(math.cos(endAngle), math.sin(endAngle)) * innerRadius;
  return Path()
    ..moveTo(startPoint.dx, startPoint.dy)
    ..arcTo(outer, start, sweep, false)
    ..lineTo(innerEnd.dx, innerEnd.dy)
    ..arcTo(inner, endAngle, -sweep, false)
    ..close();
}
