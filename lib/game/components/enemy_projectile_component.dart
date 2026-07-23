import 'dart:ui';
import 'dart:math' as math;

import 'package:flame/components.dart';

import 'player_component.dart';
import '../content/combat_visual_factory.dart';
import '../combat/attack_spec.dart';
import '../combat/attack_visual_event.dart';

class EnemyProjectileComponent extends PositionComponent {
  EnemyProjectileComponent({
    required this.sourceId,
    required this.damage,
    required Vector2 position,
    required Vector2 velocity,
    this.lifetime = 3,
    Vector2? size,
    this.visualFactory,
  }) : velocity = velocity.clone(),
       super(
         position: position,
         size: size ?? Vector2.all(10),
         anchor: Anchor.center,
       );

  final String sourceId;
  final double damage;
  final Vector2 velocity;
  final double lifetime;
  final CombatVisualFactory? visualFactory;
  double _age = 0;
  bool _spent = false;

  bool get isExpired => _age >= lifetime;
  bool get isSpent => _spent;
  double get visualFootprint => 34;
  PositionComponent? _registryVisual;
  bool get usesRegistryVisual => _registryVisual != null;
  bool get startsImageLoadOnMount => false;
  bool get ownsDamageResolution => false;

  bool overlapsPlayer(PlayerComponent player) {
    final radius = (size.x + player.size.x) / 2;
    return position.distanceToSquared(player.position) < radius * radius;
  }

  bool registerHit() {
    if (_spent) return false;
    _spent = true;
    return true;
  }

  @override
  void onMount() {
    super.onMount();
    const key = 'projectiles/enemy/sakkat_spirit_projectile_128.png';
    if (sourceId != 'sakkat_specter' ||
        visualFactory?.images.containsKey(key) != true) {
      return;
    }
    final visual = visualFactory!.create(_projectileVisualEvent(lifetime));
    visual
      ..position = center
      ..scale = Vector2.all(visualFootprint / 128)
      ..angle = _velocityAngle;
    add(visual);
    _registryVisual = visual;
  }

  double get _velocityAngle =>
      velocity.length2 == 0 ? 0 : math.atan2(velocity.y, velocity.x);

  @override
  void update(double dt) {
    super.update(dt);
    final safeDt = dt.isFinite && dt > 0 ? dt : 0.0;
    _age += safeDt;
    position.add(velocity * safeDt);
    _registryVisual?.angle = _velocityAngle;
    if (isExpired || isSpent) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (usesRegistryVisual) return;
    final rect = Rect.fromCenter(
      center: Offset(size.x / 2, size.y / 2),
      width: visualFootprint,
      height: visualFootprint,
    );
    canvas.drawOval(rect, Paint()..color = const Color(0xff9f2b68));
    canvas.drawOval(
      rect,
      Paint()
        ..color = const Color(0xffff5ca8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}

AttackVisualEvent _projectileVisualEvent(double duration) =>
    AttackVisualEvent.fromAttack(
      AttackInstance(
        spec: AttackSpec(
          id: 'sakkat_spirit_projectile',
          shape: AttackShape.line,
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
