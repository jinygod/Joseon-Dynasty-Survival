import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../combat/attack_spec.dart';
import '../combat/talisman_damage.dart';
import '../content/weapon_definitions.dart';
import '../models/damage_event.dart';
import 'enemy_component.dart';

class FiveColorWardComponent extends PositionComponent {
  FiveColorWardComponent({required this.attack, this.tickSeconds = .5})
    : assert(attack.spec.shape == AttackShape.circle),
      assert(attack.spec.radius > 0),
      assert(attack.spec.lingerSeconds > 0),
      assert(tickSeconds > 0),
      super(
        position: attack.origin,
        size: Vector2.all(attack.spec.radius * 2),
        anchor: Anchor.center,
      );

  final AttackInstance attack;
  final double tickSeconds;

  double _elapsed = 0;
  double _nextTick = 0;
  int _pendingTicks = 0;

  double get radius => attack.spec.radius;
  double get durationSeconds => attack.spec.lingerSeconds;
  double get slowFraction => attack.spec.slowFraction;
  bool get isExpired => _elapsed >= durationSeconds;

  bool containsEnemy(EnemyComponent enemy) {
    final hitRadius = radius + enemy.size.x / 2;
    return position.distanceToSquared(enemy.position) <= hitRadius * hitRadius;
  }

  double slowFor(EnemyComponent enemy) =>
      !enemy.isDead && containsEnemy(enemy) ? slowFraction : 0;

  List<DamageEvent> collectDamageEvents(Iterable<EnemyComponent> enemies) {
    if (_pendingTicks == 0) {
      if (isExpired) removeFromParent();
      return const [];
    }
    final ticks = _pendingTicks;
    _pendingTicks = 0;
    final events = [
      for (var tick = 0; tick < ticks; tick += 1)
        for (final enemy in enemies)
          if (!enemy.isDead && !enemy.isRemoving && containsEnemy(enemy))
            DamageEvent(
              target: enemy,
              damage: talismanDamageForTarget(attack, enemy),
              knockback: attack.spec.knockback,
              direction: _directionTo(enemy.position),
              weaponId: talismanThrow,
              sourceId: attack.spec.id,
              traits: attack.spec.traits,
              isCritical: attack.isCritical,
            ),
    ];
    if (isExpired) removeFromParent();
    return events;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final previousElapsed = _elapsed;
    _elapsed = (_elapsed + max(0, dt)).clamp(0, durationSeconds).toDouble();
    if (durationSeconds - _elapsed <= 1e-9) _elapsed = durationSeconds;
    if (_nextTick == 0) _nextTick = tickSeconds;
    while (_nextTick <= _elapsed && _nextTick > previousElapsed) {
      _pendingTicks += 1;
      _nextTick += tickSeconds;
    }
    if (isExpired && _pendingTicks == 0) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(radius, radius);
    final colors = <Color>[
      const Color(0xff3155a6),
      const Color(0xffc63b32),
      const Color(0xffe8c547),
      const Color(0xfff2eee3),
      const Color(0xff26252b),
    ];
    final rect = Rect.fromCircle(center: center, radius: radius * .86);
    for (var index = 0; index < colors.length; index += 1) {
      canvas.drawArc(
        rect,
        -pi / 2 + index * 2 * pi / colors.length,
        2 * pi / colors.length - .08,
        false,
        Paint()
          ..color = colors[index].withValues(alpha: .82)
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(3, radius * .13),
      );
    }
    canvas.drawCircle(
      center,
      radius * .42,
      Paint()..color = const Color(0xe8ead8b0),
    );
    canvas.drawCircle(
      center,
      radius * .42,
      Paint()
        ..color = const Color(0xff6b4423)
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
