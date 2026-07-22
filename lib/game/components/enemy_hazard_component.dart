import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../combat/combat_vfx_primitives.dart';
import 'player_component.dart';

enum EnemyHazardKind { poison, warning, shockwave, scream }

class EnemyHazardComponent extends PositionComponent {
  EnemyHazardComponent({
    required this.kind,
    required this.radius,
    required this.damage,
    required this.durationSeconds,
    required this.tickIntervalSeconds,
    required this.sourceId,
    required Vector2 position,
  }) : super(
         position: position,
         size: Vector2.all(radius * 2),
         anchor: Anchor.center,
       );

  factory EnemyHazardComponent.poison({
    required Vector2 position,
    required double damage,
    required String sourceId,
  }) => EnemyHazardComponent(
    kind: EnemyHazardKind.poison,
    radius: 38,
    damage: damage,
    durationSeconds: 4,
    tickIntervalSeconds: .5,
    sourceId: sourceId,
    position: position,
  );

  factory EnemyHazardComponent.shockwave({
    required Vector2 position,
    required double radius,
    required double damage,
    required String sourceId,
  }) => EnemyHazardComponent(
    kind: EnemyHazardKind.shockwave,
    radius: radius,
    damage: damage,
    durationSeconds: .12,
    tickIntervalSeconds: double.infinity,
    sourceId: sourceId,
    position: position,
  );

  factory EnemyHazardComponent.scream({
    required Vector2 position,
    required double radius,
    required double damage,
    required String sourceId,
  }) => EnemyHazardComponent(
    kind: EnemyHazardKind.scream,
    radius: radius,
    damage: damage,
    durationSeconds: .15,
    tickIntervalSeconds: double.infinity,
    sourceId: sourceId,
    position: position,
  );

  final EnemyHazardKind kind;
  final double radius;
  final double damage;
  final double durationSeconds;
  final double tickIntervalSeconds;
  final String sourceId;
  final Map<PlayerComponent, double> _nextHitAt = {};
  double _elapsed = 0;

  bool get isExpired => _elapsed >= durationSeconds;

  bool containsPlayer(PlayerComponent player) {
    final hitRadius = radius + player.size.x / 2;
    return position.distanceToSquared(player.position) <= hitRadius * hitRadius;
  }

  double damageFor(PlayerComponent player) {
    if (isExpired || !containsPlayer(player)) return 0;
    final nextHitAt = _nextHitAt[player] ?? 0;
    if (_elapsed < nextHitAt) return 0;
    _nextHitAt[player] = tickIntervalSeconds.isFinite
        ? _elapsed + tickIntervalSeconds
        : double.infinity;
    return damage;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (dt.isFinite && dt > 0) _elapsed += dt;
    if (isExpired && isMounted) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(radius, radius);
    final progress = durationSeconds <= 0
        ? 1.0
        : (_elapsed / durationSeconds).clamp(0, 1).toDouble();
    switch (kind) {
      case EnemyHazardKind.poison:
        _drawPoisonPuddle(canvas, center, progress);
      case EnemyHazardKind.warning:
        _drawWarningRing(canvas, center);
      case EnemyHazardKind.shockwave:
        _drawShockwave(canvas, center, progress);
      case EnemyHazardKind.scream:
        _drawScreamBands(canvas, center, progress);
    }
  }

  void _drawPoisonPuddle(Canvas canvas, Offset center, double progress) {
    const palette = CombatVfxPalette(
      core: Color(0xffd9ff8a),
      edge: Color(0xff6dbb4f),
      accent: Color(0xffb2e35c),
      smoke: Color(0xff274d37),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = palette.edge.withValues(alpha: .26),
    );
    for (var index = 0; index < 7; index += 1) {
      final angle = math.pi * 2 * index / 7 + .21;
      final lobeCenter =
          center +
          Offset(math.cos(angle), math.sin(angle)) *
              radius *
              (.38 + (index % 3) * .08);
      canvas.drawCircle(
        lobeCenter,
        radius * (.21 + (index % 2) * .035),
        Paint()..color = palette.smoke.withValues(alpha: .22),
      );
    }
    for (var index = 0; index < 4; index += 1) {
      final angle = math.pi * 2 * index / 4 + .62;
      final bubble =
          center +
          Offset(math.cos(angle), math.sin(angle)) *
              radius *
              (.22 + index * .09);
      canvas.drawCircle(
        bubble,
        radius * (.055 + index * .01),
        Paint()
          ..color = palette.core.withValues(alpha: .48 * (1 - progress * .35))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  void _drawWarningRing(Canvas canvas, Offset center) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xfff4d35e).withValues(alpha: .28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawShockwave(Canvas canvas, Offset center, double progress) {
    const palette = CombatVfxPalette(
      core: Color(0xffe4f7ff),
      edge: Color(0xff65b6e9),
      accent: Color(0xffb6ecff),
      smoke: Color(0xff2d586c),
    );
    for (final factor in [.42, .7, 1.0]) {
      canvas.drawCircle(
        center,
        radius * factor,
        Paint()
          ..color = palette.edge.withValues(
            alpha: (.68 - factor * .28) * (1 - progress * .35),
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = factor == 1 ? 3 : 2,
      );
    }
    CombatVfxPrimitives.drawRadialBurst(
      canvas,
      center: center,
      radius: radius,
      palette: palette,
      progress: progress,
      count: 8,
    );
  }

  void _drawScreamBands(Canvas canvas, Offset center, double progress) {
    const palette = CombatVfxPalette(
      core: Color(0xffffebff),
      edge: Color(0xffb16de3),
      accent: Color(0xffffa8dc),
      smoke: Color(0xff47235c),
    );
    for (var index = 0; index < 4; index += 1) {
      final factor = .28 + index * .24;
      final bandRadius = radius * factor;
      final bandRect = Rect.fromCenter(
        center: center,
        width: bandRadius * 2,
        height: bandRadius * (1.25 + index * .08),
      );
      canvas.drawArc(
        bandRect,
        -.72,
        1.44,
        false,
        Paint()
          ..color = (index.isEven ? palette.edge : palette.accent).withValues(
            alpha: (.64 - index * .09) * (1 - progress * .42),
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawArc(
        bandRect,
        math.pi - .72,
        1.44,
        false,
        Paint()
          ..color = palette.core.withValues(
            alpha: (.4 - index * .045) * (1 - progress * .42),
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3
          ..strokeCap = StrokeCap.round,
      );
    }
  }
}
