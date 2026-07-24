import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/combat/attack_spec.dart';
import 'package:pixel_survivor/game/combat/hwando_attack_queue.dart';

void main() {
  test('queue emits one strike only when windup crosses into active', () {
    final queue = HwandoAttackQueue()..enqueue(_hwandoAttack());

    expect(queue.advance(.059), isEmpty);
    expect(queue.pendingCount, 1);

    final activations = queue.advance(.001);

    expect(activations, hasLength(1));
    expect(activations.single.attack.spec.id, 'hwando_slash');
    expect(activations.single.contract.hitSector.radius, closeTo(52.2, .0001));
    expect(queue.advance(.08), isEmpty);
    expect(queue.pendingCount, 1);

    queue.advance(.10);
    expect(queue.pendingCount, 0);
  });

  test('large delta cannot emit the same pending strike twice', () {
    final queue = HwandoAttackQueue()..enqueue(_hwandoAttack());

    expect(queue.advance(.20), hasLength(1));
    expect(queue.advance(.20), isEmpty);
    expect(queue.pendingCount, 0);
  });

  test('clearing pending attacks prevents delayed damage after death', () {
    final queue = HwandoAttackQueue()..enqueue(_hwandoAttack());

    queue.clear();

    expect(queue.advance(1), isEmpty);
    expect(queue.pendingCount, 0);
  });
}

AttackInstance _hwandoAttack() => AttackInstance(
  spec: AttackSpec(
    id: 'hwando_slash',
    shape: AttackShape.sector,
    damage: 8,
    range: 58,
    angleRadians: math.pi / 2,
    radius: 0,
    width: 0,
    windupSeconds: .06,
    activeSeconds: .08,
    lingerSeconds: .10,
    knockback: 45,
    slowFraction: 0,
    traits: const {AttackTrait.melee},
    presentation: AttackPresentation.normal,
  ),
  origin: Vector2.zero(),
  direction: Vector2(1, 0),
  sequenceIndex: 0,
);
