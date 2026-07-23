import 'dart:ui';

import 'package:flame/components.dart';

import 'player_component.dart';
import '../combat/attack_spec.dart';
import '../combat/attack_visual_event.dart';
import '../content/combat_visual_factory.dart';

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
    this.visualFactory,
  }) : super(
         position: position,
         size: Vector2.all(radius * 2),
         anchor: Anchor.center,
       );

  factory EnemyHazardComponent.poison({
    required Vector2 position,
    required double damage,
    required String sourceId,
    CombatVisualFactory? visualFactory,
  }) => EnemyHazardComponent(
    kind: EnemyHazardKind.poison,
    radius: 38,
    damage: damage,
    durationSeconds: 4,
    tickIntervalSeconds: .5,
    sourceId: sourceId,
    position: position,
    visualFactory: visualFactory,
  );

  factory EnemyHazardComponent.shockwave({
    required Vector2 position,
    required double radius,
    required double damage,
    required String sourceId,
    CombatVisualFactory? visualFactory,
  }) => EnemyHazardComponent(
    kind: EnemyHazardKind.shockwave,
    radius: radius,
    damage: damage,
    durationSeconds: .12,
    tickIntervalSeconds: double.infinity,
    sourceId: sourceId,
    position: position,
    visualFactory: visualFactory,
  );

  factory EnemyHazardComponent.scream({
    required Vector2 position,
    required double radius,
    required double damage,
    required String sourceId,
    CombatVisualFactory? visualFactory,
  }) => EnemyHazardComponent(
    kind: EnemyHazardKind.scream,
    radius: radius,
    damage: damage,
    durationSeconds: .15,
    tickIntervalSeconds: double.infinity,
    sourceId: sourceId,
    position: position,
    visualFactory: visualFactory,
  );

  final EnemyHazardKind kind;
  final double radius;
  final double damage;
  final double durationSeconds;
  final double tickIntervalSeconds;
  final String sourceId;
  final CombatVisualFactory? visualFactory;
  final Map<PlayerComponent, double> _nextHitAt = {};
  double _elapsed = 0;

  bool get isExpired => _elapsed >= durationSeconds;
  double get damageRadius => radius;
  double get visualRadius => radius + 12;
  bool _usesRegistryVisual = false;
  bool get usesRegistryVisual => _usesRegistryVisual;
  bool get startsImageLoadOnMount => false;
  bool get ownsDamageResolution => false;

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
  void onMount() {
    super.onMount();
    final effectId = switch (kind) {
      EnemyHazardKind.poison => 'enemy_poison_pool',
      EnemyHazardKind.shockwave => 'enemy_shockwave',
      EnemyHazardKind.scream => 'enemy_spirit_scream',
      EnemyHazardKind.warning => null,
    };
    if (effectId == null || visualFactory == null) return;
    final spec = visualFactory!.images;
    final key = switch (effectId) {
      'enemy_poison_pool' => 'vfx/enemy/poison_pool_128.png',
      'enemy_shockwave' => 'vfx/enemy/shockwave_128.png',
      _ => 'vfx/enemy/spirit_scream_128.png',
    };
    if (!spec.containsKey(key)) return;
    final visual = visualFactory!.create(
      _enemyVisualEvent(effectId, durationSeconds),
    );
    visual.position = center;
    visual.scale = Vector2.all(visualRadius * 2 / 128);
    add(visual);
    _usesRegistryVisual = true;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (dt.isFinite && dt > 0) _elapsed += dt;
    if (isExpired && isMounted) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (usesRegistryVisual) return;
    final color = switch (kind) {
      EnemyHazardKind.poison => const Color(0x663fa34d),
      EnemyHazardKind.warning => const Color(0x66f4d35e),
      EnemyHazardKind.shockwave => const Color(0x668cd3ff),
      EnemyHazardKind.scream => const Color(0x668c5bd6),
    };
    canvas.drawCircle(
      Offset(radius, radius),
      visualRadius,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }
}

AttackVisualEvent _enemyVisualEvent(String effectId, double duration) =>
    AttackVisualEvent.fromAttack(
      AttackInstance(
        spec: AttackSpec(
          id: effectId,
          shape: AttackShape.circle,
          damage: 0,
          range: 0,
          angleRadians: 0,
          radius: 0,
          width: 0,
          windupSeconds: 0,
          activeSeconds: duration,
          lingerSeconds: 0,
          knockback: 0,
          slowFraction: 0,
          traits: const {},
          presentation: AttackPresentation.master,
        ),
        origin: Vector2.zero(),
        direction: Vector2(1, 0),
        sequenceIndex: 0,
      ),
    );
