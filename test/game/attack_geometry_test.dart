import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/combat/attack_geometry.dart';
import 'package:pixel_survivor/game/combat/attack_spec.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/components/attack_effect_component.dart';
import 'package:pixel_survivor/game/models/damage_event.dart';

void main() {
  test('sector visual and hit test use the same frozen direction', () {
    final origin = Vector2.zero();
    final direction = Vector2(1, 0);
    final attack = AttackInstance(
      spec: AttackSpec(
        id: 'test_sector',
        shape: AttackShape.sector,
        damage: 8,
        range: 60,
        angleRadians: pi / 2,
        radius: 0,
        width: 0,
        windupSeconds: 0,
        activeSeconds: .08,
        lingerSeconds: .12,
        knockback: 20,
        slowFraction: 0,
        traits: const {AttackTrait.melee},
        presentation: AttackPresentation.normal,
      ),
      origin: origin,
      direction: direction,
      sequenceIndex: 0,
    );

    origin.setValues(100, 100);
    direction.setValues(-1, 0);

    expect(AttackGeometry.contains(attack, Vector2(40, 10), 9), isTrue);
    expect(AttackGeometry.contains(attack, Vector2(-40, 0), 9), isFalse);
    expect(attack.origin, Vector2.zero());
    expect(attack.direction, Vector2(1, 0));
  });

  test('mutating returned vectors cannot change frozen attack geometry', () {
    final attack = AttackInstance(
      spec: _spec(shape: AttackShape.line, range: 20, width: 2),
      origin: Vector2.zero(),
      direction: Vector2(1, 0),
      sequenceIndex: 0,
    );

    attack.origin.setValues(100, 100);
    attack.direction.setValues(-1, 0);

    expect(attack.origin, Vector2.zero());
    expect(attack.direction, Vector2(1, 0));
    expect(AttackGeometry.contains(attack, Vector2(10, 0), 0), isTrue);
    expect(AttackGeometry.contains(attack, Vector2(-10, 0), 0), isFalse);
  });

  test('renderer consumes the same frozen sector geometry as hit testing', () {
    final attack = AttackInstance(
      spec: _spec(shape: AttackShape.sector, range: 72, angleRadians: pi * .75),
      origin: Vector2(14, 9),
      direction: Vector2(0, -4),
      sequenceIndex: 0,
    );
    final effect = AttackEffectComponent(instance: attack);

    expect(effect.position, attack.origin);
    expect(effect.visualGeometry.direction, attack.direction);
    expect(effect.visualGeometry.range, attack.spec.range);
    expect(effect.visualGeometry.angleRadians, attack.spec.angleRadians);
    expect(
      AttackGeometry.contains(attack, attack.origin + attack.direction * 50, 0),
      isTrue,
    );
  });

  test('attack spec defensively freezes caller traits', () {
    final traits = <AttackTrait>{AttackTrait.melee};
    final spec = _spec(shape: AttackShape.line, traits: traits);

    traits.add(AttackTrait.master);

    expect(spec.traits, {AttackTrait.melee});
    expect(() => spec.traits.add(AttackTrait.synergy), throwsUnsupportedError);
  });

  test('sector includes a target centered inside the wedge', () {
    final attack = AttackInstance(
      spec: _spec(shape: AttackShape.sector, range: 60, angleRadians: pi / 2),
      origin: Vector2.zero(),
      direction: Vector2(1, 0),
      sequenceIndex: 0,
    );

    expect(AttackGeometry.contains(attack, Vector2(30, 0), 2), isTrue);
  });

  test('sector includes a target circle overlapping a side ray', () {
    final attack = AttackInstance(
      spec: _spec(shape: AttackShape.sector, range: 60, angleRadians: pi / 2),
      origin: Vector2.zero(),
      direction: Vector2(1, 0),
      sequenceIndex: 0,
    );
    final side = Vector2(cos(pi / 4), sin(pi / 4));
    for (final sign in [-1.0, 1.0]) {
      final signedSide = Vector2(side.x, side.y * sign);
      final outward = Vector2(-signedSide.y * sign, signedSide.x * sign);
      expect(
        AttackGeometry.contains(attack, signedSide * 40 + outward * 4.9, 5),
        isTrue,
      );
    }
  });

  test('sector includes a target circle overlapping the outer arc', () {
    final attack = AttackInstance(
      spec: _spec(shape: AttackShape.sector, range: 60, angleRadians: pi / 2),
      origin: Vector2.zero(),
      direction: Vector2(1, 0),
      sequenceIndex: 0,
    );

    expect(AttackGeometry.contains(attack, Vector2(64.9, 0), 5), isTrue);
    expect(AttackGeometry.contains(attack, Vector2(65.01, 0), 5), isFalse);
  });

  test('sector excludes a target circle just outside a side ray', () {
    final attack = AttackInstance(
      spec: _spec(shape: AttackShape.sector, range: 60, angleRadians: pi / 2),
      origin: Vector2.zero(),
      direction: Vector2(1, 0),
      sequenceIndex: 0,
    );
    final side = Vector2(cos(pi / 4), sin(pi / 4));
    final outward = Vector2(-side.y, side.x);

    expect(
      AttackGeometry.contains(attack, side * 40 + outward * 5.01, 5),
      isFalse,
    );
  });

  test('circle includes a target whose edge reaches the attack radius', () {
    final attack = AttackInstance(
      spec: _spec(shape: AttackShape.circle, radius: 30),
      origin: Vector2(10, 10),
      direction: Vector2(0, 1),
      sequenceIndex: 1,
    );

    expect(AttackGeometry.contains(attack, Vector2(45, 10), 5), isTrue);
    expect(AttackGeometry.contains(attack, Vector2(45.01, 10), 5), isFalse);
  });

  test(
    'line uses its width as a finite capsule around the frozen direction',
    () {
      final attack = AttackInstance(
        spec: _spec(shape: AttackShape.line, range: 50, width: 10),
        origin: Vector2.zero(),
        direction: Vector2(3, 0),
        sequenceIndex: 2,
      );

      expect(AttackGeometry.contains(attack, Vector2(25, 8), 3), isTrue);
      expect(AttackGeometry.contains(attack, Vector2(25, 8.01), 3), isFalse);
      expect(AttackGeometry.contains(attack, Vector2(60, 0), 5), isTrue);
      expect(AttackGeometry.contains(attack, Vector2(60.01, 0), 5), isFalse);
    },
  );

  test('zero direction normalizes to the positive x axis', () {
    final attack = AttackInstance(
      spec: _spec(shape: AttackShape.line, range: 20, width: 2),
      origin: Vector2.zero(),
      direction: Vector2.zero(),
      sequenceIndex: 0,
    );

    expect(attack.direction, Vector2(1, 0));
    expect(AttackGeometry.contains(attack, Vector2(10, 0), 0), isTrue);
    expect(AttackGeometry.contains(attack, Vector2(-10, 0), 0), isFalse);
  });

  test('damage event keeps legacy callers source-compatible', () {
    final event = DamageEvent(
      target: EnemyComponent(
        enemyId: 'test_enemy',
        maxHealth: 1,
        moveSpeed: 0,
        damage: 0,
      ),
      damage: 1,
      knockback: 0,
      direction: Vector2.zero(),
    );

    expect(event.sourceId, isNull);
    expect(event.traits, isEmpty);
  });

  test('damage event defensively freezes caller traits', () {
    final traits = <AttackTrait>{AttackTrait.projectile};
    final event = DamageEvent(
      target: EnemyComponent(
        enemyId: 'test_enemy',
        maxHealth: 1,
        moveSpeed: 0,
        damage: 0,
      ),
      damage: 1,
      knockback: 0,
      direction: Vector2.zero(),
      traits: traits,
    );

    traits.add(AttackTrait.piercing);

    expect(event.traits, {AttackTrait.projectile});
    expect(() => event.traits.clear(), throwsUnsupportedError);
  });
}

AttackSpec _spec({
  required AttackShape shape,
  double range = 0,
  double radius = 0,
  double width = 0,
  double angleRadians = 0,
  Set<AttackTrait> traits = const {},
}) {
  return AttackSpec(
    id: 'test_${shape.name}',
    shape: shape,
    damage: 1,
    range: range,
    angleRadians: angleRadians,
    radius: radius,
    width: width,
    windupSeconds: 0,
    activeSeconds: .1,
    lingerSeconds: 0,
    knockback: 0,
    slowFraction: 0,
    traits: traits,
    presentation: AttackPresentation.normal,
  );
}
