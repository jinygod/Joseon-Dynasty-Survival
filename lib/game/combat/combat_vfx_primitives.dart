import 'dart:math' as math;
import 'dart:ui';

/// Visual intensity only; it has no connection to combat values or timing.
enum CombatVfxTier {
  normal(1),
  strong(1.16),
  master(1.32);

  const CombatVfxTier(this.scale);

  final double scale;

  int get glowLayers => this == CombatVfxTier.normal ? 1 : 2;
}

/// The four colours used by the bounded combat drawing helpers.
class CombatVfxPalette {
  const CombatVfxPalette({
    required this.core,
    required this.edge,
    required this.accent,
    required this.smoke,
  });

  final Color core;
  final Color edge;
  final Color accent;
  final Color smoke;
}

/// A fixed polar sample used for deterministic radial decoration.
class CombatVfxSample {
  const CombatVfxSample({required this.angle, required this.distanceFactor});

  final double angle;
  final double distanceFactor;

  @override
  bool operator ==(Object other) =>
      other is CombatVfxSample &&
      other.angle == angle &&
      other.distanceFactor == distanceFactor;

  @override
  int get hashCode => Object.hash(angle, distanceFactor);
}

/// Returns fixed-index polar samples, capped for mobile-safe rendering.
List<CombatVfxSample> radialSamples({required int count}) {
  final capped = _cappedCount(count, CombatVfxPrimitives.maxBurstSamples);
  return List<CombatVfxSample>.unmodifiable(
    List.generate(
      capped,
      (index) => CombatVfxSample(
        angle: (math.pi * 2 * index / capped) + .19,
        distanceFactor: .56 + ((index * 3) % 5) * .09,
      ),
      growable: false,
    ),
  );
}

/// Stateless, deterministic Canvas primitives for combat presentation.
///
/// Callers own gameplay state and supply their resolved geometry, palette, and
/// normalized animation progress. Counts are capped here to keep the helpers
/// predictable on mobile web and Android.
abstract final class CombatVfxPrimitives {
  static const int maxBurstSamples = 24;
  static const int maxTrailSegments = 3;
  static const int maxRuneMarks = 12;
  static const int maxCrystalFacets = 8;
  static const int maxChevronMarks = 8;
  static const int maxSmokePuffs = 10;

  /// Draws one to three filled ribbon afterimages from [start] to [end].
  static void drawTaperedTrail(
    Canvas canvas, {
    required Offset start,
    required Offset end,
    required double startWidth,
    required double endWidth,
    required CombatVfxPalette palette,
    required double progress,
    required int count,
    CombatVfxTier tier = CombatVfxTier.normal,
  }) {
    final segments = _cappedCount(count, maxTrailSegments);
    if (segments == 0) return;
    final unit = _unit(start, end);
    final fade = 1 - _normalized(progress);
    for (var index = 0; index < segments; index++) {
      final delay = index / (segments + 2);
      final offset = unit * (-startWidth * delay * .6);
      final opacity = fade * (.35 - index * .07).clamp(.12, .35);
      _drawRibbon(
        canvas,
        start: start + offset,
        end: end + offset,
        startWidth: startWidth * tier.scale,
        endWidth: endWidth * tier.scale,
        color: palette.edge,
        opacity: opacity,
      );
      _drawRibbon(
        canvas,
        start: start + offset,
        end: end + offset,
        startWidth: startWidth * tier.scale * .48,
        endWidth: endWidth * tier.scale * .48,
        color: palette.core,
        opacity: opacity * .9,
      );
    }
  }

  /// Draws capped, fixed-index impact ribbons expanding from [center].
  static void drawRadialBurst(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required CombatVfxPalette palette,
    required double progress,
    required int count,
    CombatVfxTier tier = CombatVfxTier.normal,
  }) {
    final fade = 1 - _normalized(progress);
    final scale = tier.scale;
    for (final sample in radialSamples(count: count)) {
      final direction = Offset(math.cos(sample.angle), math.sin(sample.angle));
      final start = center + direction * (radius * .12 * scale);
      final end = center + direction * (radius * sample.distanceFactor * scale);
      _drawRibbon(
        canvas,
        start: start,
        end: end,
        startWidth: radius * .09 * scale,
        endWidth: radius * .018 * scale,
        color: palette.accent,
        opacity: fade * .7,
      );
    }
  }

  /// Draws a ring and a capped set of fixed diamond-shaped rune marks.
  static void drawRuneRing(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required CombatVfxPalette palette,
    required double progress,
    required int count,
  }) {
    final marks = _cappedCount(count, maxRuneMarks);
    final fade = 1 - _normalized(progress);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = palette.edge.withValues(alpha: fade * .52)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, radius * .055),
    );
    if (marks == 0) return;
    for (var index = 0; index < marks; index++) {
      final angle = (math.pi * 2 * index / marks) + .25;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final point = center + direction * (radius * .76);
      final tangent = Offset(-direction.dy, direction.dx);
      final runeRadius = math.max(1.5, radius * .09);
      final path = Path()
        ..moveTo(
          point.dx + direction.dx * runeRadius,
          point.dy + direction.dy * runeRadius,
        )
        ..lineTo(
          point.dx + tangent.dx * runeRadius,
          point.dy + tangent.dy * runeRadius,
        )
        ..lineTo(
          point.dx - direction.dx * runeRadius,
          point.dy - direction.dy * runeRadius,
        )
        ..lineTo(
          point.dx - tangent.dx * runeRadius,
          point.dy - tangent.dy * runeRadius,
        )
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = palette.accent.withValues(alpha: fade * .72),
      );
    }
  }

  /// Draws capped, faceted crystals around [center] using filled polygons.
  static void drawCrystal(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required CombatVfxPalette palette,
    required double progress,
    required int count,
  }) {
    final facets = _cappedCount(count, maxCrystalFacets);
    if (facets == 0) return;
    final fade = 1 - _normalized(progress);
    for (var index = 0; index < facets; index++) {
      final angle = (math.pi * 2 * index / facets) - math.pi / 2;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final tangent = Offset(-direction.dy, direction.dx);
      final origin = center + direction * (radius * (.2 + (index % 3) * .16));
      final height = radius * (.34 + (index % 2) * .12);
      final width = radius * .13;
      final tip = origin + direction * height;
      final path = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(origin.dx + tangent.dx * width, origin.dy + tangent.dy * width)
        ..lineTo(
          origin.dx - direction.dx * height * .3,
          origin.dy - direction.dy * height * .3,
        )
        ..lineTo(origin.dx - tangent.dx * width, origin.dy - tangent.dy * width)
        ..close();
      canvas.drawPath(
        path,
        Paint()..color = palette.edge.withValues(alpha: fade * .62),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = palette.core.withValues(alpha: fade * .9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, radius * .035),
      );
    }
  }

  /// Draws a translucent lane with a bounded set of direction chevrons.
  static void drawChevronLane(
    Canvas canvas, {
    required Offset start,
    required Offset end,
    required double halfWidth,
    required CombatVfxPalette palette,
    required double progress,
    required int count,
  }) {
    final unit = _unit(start, end);
    final normal = Offset(-unit.dy, unit.dx);
    final fade = 1 - _normalized(progress);
    final lane = Path()
      ..moveTo(
        start.dx + normal.dx * halfWidth,
        start.dy + normal.dy * halfWidth,
      )
      ..lineTo(end.dx + normal.dx * halfWidth, end.dy + normal.dy * halfWidth)
      ..lineTo(end.dx - normal.dx * halfWidth, end.dy - normal.dy * halfWidth)
      ..lineTo(
        start.dx - normal.dx * halfWidth,
        start.dy - normal.dy * halfWidth,
      )
      ..close();
    canvas.drawPath(
      lane,
      Paint()..color = palette.edge.withValues(alpha: fade * .14),
    );
    final marks = _cappedCount(count, maxChevronMarks);
    for (var index = 0; index < marks; index++) {
      final fraction = (index + 1) / (marks + 1);
      final point = Offset.lerp(start, end, fraction)!;
      final depth = math.max(2, halfWidth * .58);
      final width = math.max(1.5, halfWidth * .28);
      final chevron = Path()
        ..moveTo(
          point.dx - unit.dx * depth + normal.dx * width,
          point.dy - unit.dy * depth + normal.dy * width,
        )
        ..lineTo(point.dx + unit.dx * depth, point.dy + unit.dy * depth)
        ..lineTo(
          point.dx - unit.dx * depth - normal.dx * width,
          point.dy - unit.dy * depth - normal.dy * width,
        )
        ..lineTo(
          point.dx - unit.dx * depth - normal.dx * (width * .45),
          point.dy - unit.dy * depth - normal.dy * (width * .45),
        )
        ..lineTo(
          point.dx + unit.dx * (depth * .38),
          point.dy + unit.dy * (depth * .38),
        )
        ..lineTo(
          point.dx - unit.dx * depth + normal.dx * (width * .45),
          point.dy - unit.dy * depth + normal.dy * (width * .45),
        )
        ..close();
      canvas.drawPath(
        chevron,
        Paint()..color = palette.accent.withValues(alpha: fade * .7),
      );
    }
  }

  /// Draws fixed-index, unblurred smoke lobes around [center].
  static void drawSmokePuff(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required CombatVfxPalette palette,
    required double progress,
    required int count,
  }) {
    final puffs = _cappedCount(count, maxSmokePuffs);
    final fade = 1 - _normalized(progress);
    for (var index = 0; index < puffs; index++) {
      final angle = (math.pi * 2 * index / puffs) + .41;
      final distance = radius * (.12 + (index % 4) * .12);
      final size = radius * (.16 + (index % 3) * .045);
      final point =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      canvas.drawCircle(
        point,
        size,
        Paint()
          ..color = palette.smoke.withValues(
            alpha: fade * (.22 + (index % 2) * .08),
          ),
      );
    }
  }
}

int _cappedCount(int count, int maximum) {
  if (count <= 0) return 0;
  return count < maximum ? count : maximum;
}

double _normalized(double progress) => progress.clamp(0, 1).toDouble();

Offset _unit(Offset start, Offset end) {
  final delta = end - start;
  final length = delta.distance;
  return length < .0001 ? const Offset(1, 0) : delta / length;
}

void _drawRibbon(
  Canvas canvas, {
  required Offset start,
  required Offset end,
  required double startWidth,
  required double endWidth,
  required Color color,
  required double opacity,
}) {
  final unit = _unit(start, end);
  final normal = Offset(-unit.dy, unit.dx);
  final path = Path()
    ..moveTo(
      start.dx + normal.dx * startWidth,
      start.dy + normal.dy * startWidth,
    )
    ..lineTo(end.dx + normal.dx * endWidth, end.dy + normal.dy * endWidth)
    ..lineTo(end.dx - normal.dx * endWidth, end.dy - normal.dy * endWidth)
    ..lineTo(
      start.dx - normal.dx * startWidth,
      start.dy - normal.dy * startWidth,
    )
    ..close();
  canvas.drawPath(
    path,
    Paint()..color = color.withValues(alpha: opacity.clamp(0, 1).toDouble()),
  );
}
