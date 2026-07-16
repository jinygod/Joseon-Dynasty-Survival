import 'dart:ui';

import 'package:flame/components.dart';

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
    final color = switch (kind) {
      EnemyHazardKind.poison => const Color(0x663fa34d),
      EnemyHazardKind.warning => const Color(0x66f4d35e),
      EnemyHazardKind.shockwave => const Color(0x668cd3ff),
      EnemyHazardKind.scream => const Color(0x668c5bd6),
    };
    canvas.drawCircle(
      Offset(radius, radius),
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }
}
