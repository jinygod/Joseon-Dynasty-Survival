import 'dart:ui';

import 'package:flame/components.dart';

import '../content/ids.dart';
import '../combat/attack_spec.dart';
import '../combat/attack_visual_event.dart';
import '../content/combat_visual_factory.dart';
import '../content/attack_visual_registry.dart';
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
    CombatVisualFactory? visualFactory,
  }) : assert(damage >= 0),
       assert(radius > 0),
       assert(durationSeconds > 0),
       assert(tickSeconds > 0),
       assert(slowFraction >= 0 && slowFraction < .8),
       super(
         position: position,
         size: Vector2.all(radius * 2),
         anchor: Anchor.center,
       ) {
    if (visualFactory != null) attachVisuals(visualFactory);
  }

  final WeaponId weaponId;
  final double damage;
  final double radius;
  final double durationSeconds;
  final double tickSeconds;
  final double slowFraction;
  final double knockback;

  double _elapsed = 0;
  double _nextTick = 0;
  int _pendingTicks = 0;

  bool get isExpired => _elapsed >= durationSeconds;
  String get visualEffectId => 'frost_flask';
  bool get usesRegistryVisual => _usesRegistryVisual;
  bool get startsImageLoadOnMount => false;

  /// The registry presentation delegate never resolves damage.
  bool get ownsDamageResolution => false;

  /// Damage ticks remain owned by this gameplay component.
  bool get gameplayOwnsDamageResolution => true;
  bool _usesRegistryVisual = false;
  bool _hasRegistrySprite = false;

  void attachVisuals(CombatVisualFactory visualFactory) {
    if (_usesRegistryVisual) return;
    _usesRegistryVisual = true;
    _hasRegistrySprite = AttackVisualRegistry.byId(
      visualEffectId,
    ).layers.any((layer) => visualFactory.images.containsKey(layer.assetKey));
    add(
      visualFactory.create(
        AttackVisualEvent.fromAttack(
          AttackInstance(
            spec: AttackSpec(
              id: visualEffectId,
              shape: AttackShape.circle,
              damage: 0,
              range: 0,
              angleRadians: 0,
              radius: radius,
              width: 0,
              windupSeconds: 0,
              activeSeconds: durationSeconds,
              lingerSeconds: 0,
              knockback: 0,
              slowFraction: 0,
              traits: const {},
              presentation: AttackPresentation.normal,
            ),
            origin: Vector2.zero(),
            direction: Vector2(1, 0),
            sequenceIndex: 0,
          ),
        ),
      )..scale = Vector2.all(size.x / 128),
    );
  }

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
    if (_hasRegistrySprite) return;
    final center = Offset(radius, radius);
    canvas.drawCircle(center, radius, Paint()..color = const Color(0x554cc9f0));
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xccbde0fe)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  Vector2 _directionTo(Vector2 target) {
    final direction = target - position;
    if (direction.length2 == 0) return Vector2(1, 0);
    return direction..normalize();
  }
}
