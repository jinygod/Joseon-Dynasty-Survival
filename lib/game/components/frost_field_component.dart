import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../combat/combat_vfx_primitives.dart';
import '../content/ids.dart';
import '../models/damage_event.dart';
import 'enemy_component.dart';

class FrostFieldComponent extends PositionComponent {
  FrostFieldComponent({
    required this.weaponId,
    required this.damage,
    required this.radius,
    required this.durationSeconds,
    required this.slowFraction,
    required this.knockback,
    required Vector2 position,
    this.tickSeconds = .5,
    this.tier = CombatVfxTier.normal,
  }) : assert(damage >= 0),
       assert(radius > 0),
       assert(durationSeconds > 0),
       assert(tickSeconds > 0),
       assert(slowFraction >= 0 && slowFraction < .8),
       super(
         position: position,
         size: Vector2.all(radius * 2),
         anchor: Anchor.center,
       );

  final WeaponId weaponId;
  final double damage;
  final double radius;
  final double durationSeconds;
  final double tickSeconds;
  final double slowFraction;
  final double knockback;
  final CombatVfxTier tier;

  double _elapsed = 0;
  double _nextTick = 0;
  int _pendingTicks = 0;

  bool get isExpired => _elapsed >= durationSeconds;

  /// Presentation-only tier. Combat values remain unchanged by this value.
  CombatVfxTier get visualTier => tier;

  /// Normalized time since the latest damage tick for the ice-sigil pulse.
  double get pulseProgress => (_elapsed / tickSeconds) % 1;

  int get visualLayerCount => switch (tier) {
    CombatVfxTier.normal => 1,
    CombatVfxTier.strong => 2,
    CombatVfxTier.master => 3,
  };

  int get driftingSpeckCount => switch (tier) {
    CombatVfxTier.normal => 4,
    CombatVfxTier.strong => 6,
    CombatVfxTier.master => 8,
  };

  bool containsEnemy(EnemyComponent enemy) {
    final hitRadius = radius + enemy.size.x / 2;
    return position.distanceToSquared(enemy.position) <= hitRadius * hitRadius;
  }

  List<DamageEvent> collectDamageEvents(Iterable<EnemyComponent> enemies) {
    if (_pendingTicks == 0) return const [];
    final ticks = _pendingTicks;
    _pendingTicks = 0;
    return [
      for (var tick = 0; tick < ticks; tick += 1)
        for (final enemy in enemies)
          if (!enemy.isDead && containsEnemy(enemy))
            DamageEvent(
              target: enemy,
              damage: damage,
              knockback: knockback,
              direction: _directionTo(enemy.position),
              weaponId: weaponId,
            ),
    ];
  }

  @override
  void update(double dt) {
    super.update(dt);
    final previousElapsed = _elapsed;
    _elapsed = (_elapsed + dt).clamp(0, durationSeconds).toDouble();
    if (_nextTick == 0) _nextTick = tickSeconds;
    while (_nextTick <= _elapsed && _nextTick > previousElapsed) {
      _pendingTicks += 1;
      _nextTick += tickSeconds;
    }
    if (isExpired) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(radius, radius);
    final pulse = 1 - pulseProgress;
    const palette = CombatVfxPalette(
      core: Color(0xffe0f7ff),
      edge: Color(0xff7dd3fc),
      accent: Color(0xffb9f3ff),
      smoke: Color(0xff4cc9f0),
    );

    _drawIceFootprint(canvas, center, palette, pulse);
    _drawSnowflakeRune(canvas, center, palette, pulse);
    _drawCracks(canvas, center, palette, pulse);
    CombatVfxPrimitives.drawCrystal(
      canvas,
      center: center,
      radius: radius,
      palette: palette,
      progress: pulseProgress,
      count: 8,
    );
    _drawDriftingSpecks(canvas, center, palette, pulse);
  }

  void _drawIceFootprint(
    Canvas canvas,
    Offset center,
    CombatVfxPalette palette,
    double pulse,
  ) {
    for (var layer = 0; layer < visualLayerCount; layer += 1) {
      final fraction = 1 - layer * .11;
      canvas.drawCircle(
        center,
        radius * fraction,
        Paint()
          ..color = palette.smoke.withValues(
            alpha: (.16 + pulse * .10 - layer * .025).clamp(0, 1),
          ),
      );
    }
    canvas.drawCircle(
      center,
      radius * (.88 + pulse * .07),
      Paint()
        ..color = palette.edge.withValues(alpha: .54 + pulse * .18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, radius * .025),
    );
  }

  void _drawSnowflakeRune(
    Canvas canvas,
    Offset center,
    CombatVfxPalette palette,
    double pulse,
  ) {
    final paint = Paint()
      ..color = palette.accent.withValues(alpha: .52 + pulse * .28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, radius * .022)
      ..strokeCap = StrokeCap.round;
    for (var layer = 0; layer < visualLayerCount; layer += 1) {
      final layerRadius = radius * (.62 - layer * .11);
      final rotation = layer == 0 ? 0.0 : math.pi / 6;
      for (var axis = 0; axis < 6; axis += 1) {
        final angle = math.pi * 2 * axis / 6 + rotation;
        final direction = _directionAt(angle);
        final tangent = Offset(-direction.dy, direction.dx);
        final end = center + direction * layerRadius;
        final branchBase = center + direction * (layerRadius * .56);
        final branchLength = layerRadius * .19;
        canvas.drawLine(center, end, paint);
        canvas.drawLine(
          branchBase,
          branchBase - direction * branchLength + tangent * branchLength,
          paint,
        );
        canvas.drawLine(
          branchBase,
          branchBase - direction * branchLength - tangent * branchLength,
          paint,
        );
      }
    }
  }

  void _drawCracks(
    Canvas canvas,
    Offset center,
    CombatVfxPalette palette,
    double pulse,
  ) {
    const angles = [.21, 1.17, 2.32, 3.48, 4.44, 5.61];
    final paint = Paint()
      ..color = palette.core.withValues(alpha: .22 + pulse * .18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, radius * .014)
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < angles.length; index += 1) {
      final direction = _directionAt(angles[index]);
      final tangent = Offset(-direction.dy, direction.dx);
      final start = center + direction * (radius * (.12 + (index % 2) * .05));
      final bend = center + direction * (radius * (.38 + (index % 3) * .04));
      final end = center + direction * (radius * (.61 + (index % 2) * .07));
      final branch = bend + tangent * (radius * .12);
      canvas.drawLine(start, bend, paint);
      canvas.drawLine(bend, end, paint);
      canvas.drawLine(bend, branch, paint);
    }
  }

  void _drawDriftingSpecks(
    Canvas canvas,
    Offset center,
    CombatVfxPalette palette,
    double pulse,
  ) {
    final samples = radialSamples(count: driftingSpeckCount);
    for (var index = 0; index < samples.length; index += 1) {
      final sample = samples[index];
      final direction = _directionAt(sample.angle + pulseProgress * .42);
      final distance = radius * (.22 + sample.distanceFactor * .53);
      final point = center + direction * distance;
      canvas.drawCircle(
        point,
        math.max(1, radius * (.018 + (index % 2) * .008)),
        Paint()..color = palette.accent.withValues(alpha: .34 + pulse * .32),
      );
    }
  }

  Offset _directionAt(double angle) => Offset(math.cos(angle), math.sin(angle));

  Vector2 _directionTo(Vector2 target) {
    final direction = target - position;
    if (direction.length2 == 0) return Vector2(1, 0);
    return direction..normalize();
  }
}
