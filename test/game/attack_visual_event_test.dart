import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/combat/attack_spec.dart';
import 'package:pixel_survivor/game/combat/attack_visual_event.dart';

void main() {
  final hwandoSpec = AttackSpec(
    id: 'hwando_slash',
    shape: AttackShape.sector,
    damage: 10,
    range: 80,
    angleRadians: math.pi * .7,
    radius: 0,
    width: 0,
    windupSeconds: .05,
    activeSeconds: .12,
    lingerSeconds: .08,
    knockback: 10,
    slowFraction: 0,
    traits: {AttackTrait.melee},
    presentation: AttackPresentation.normal,
  );

  test('visual event freezes attack direction and timing', () {
    final direction = Vector2(2, 0);
    final attack = AttackInstance(
      spec: hwandoSpec,
      origin: Vector2(10, 20),
      direction: direction,
      sequenceIndex: 3,
    );
    final event = AttackVisualEvent.fromAttack(attack);
    direction.setValues(0, 1);

    expect(event.effectId, hwandoSpec.id);
    expect(event.origin, Vector2(10, 20));
    expect(event.direction, Vector2(1, 0));
    expect(event.impactAt, hwandoSpec.windupSeconds);
    expect(
      event.duration,
      hwandoSpec.windupSeconds +
          hwandoSpec.activeSeconds +
          hwandoSpec.lingerSeconds,
    );
  });
}
