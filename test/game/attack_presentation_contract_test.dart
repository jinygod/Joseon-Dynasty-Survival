import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/combat/attack_geometry.dart';
import 'package:pixel_survivor/game/combat/attack_presentation_contract.dart';
import 'package:pixel_survivor/game/combat/attack_spec.dart';

void main() {
  test('Hwando hit sector stays ten percent inside the visible slash', () {
    final contract = AttackPresentationContract.fromAttack(_hwandoAttack());

    expect(contract.visualSector.origin, Vector2(20, 30));
    expect(contract.visualSector.direction, Vector2(1, 0));
    expect(contract.visualSector.radius, 58);
    expect(contract.visualSector.angleRadians, math.pi / 2);
    expect(contract.hitSector.radius, closeTo(52.2, .0001));
    expect(
      contract.hitSector.angleRadians,
      closeTo(math.pi / 2 * .9, .0001),
    );
  });

  test('contract defensively freezes caller position and direction', () {
    final origin = Vector2(20, 30);
    final direction = Vector2(5, 0);
    final contract = AttackPresentationContract.fromAttack(
      _hwandoAttack(origin: origin, direction: direction),
    );

    origin.setZero();
    direction.setZero();

    expect(contract.visualSector.origin, Vector2(20, 30));
    expect(contract.visualSector.direction, Vector2(1, 0));
  });

  test('sector contact lands on the target hurt circle toward the blade', () {
    final contact = AttackGeometry.sectorContact(
      SectorGeometry(
        origin: Vector2.zero(),
        direction: Vector2(1, 0),
        radius: 90,
        angleRadians: math.pi / 2,
      ),
      Vector2(60, 8),
      7,
    );

    expect(contact, isNotNull);
    expect(contact!.point.distanceTo(Vector2(60, 8)), closeTo(7, .001));
    expect(contact.point.x, lessThan(60));
    expect(contact.normal.x, greaterThan(0));
  });

  test('sector contact rejects a hurt circle outside the inset fan', () {
    final contact = AttackGeometry.sectorContact(
      SectorGeometry(
        origin: Vector2.zero(),
        direction: Vector2(1, 0),
        radius: 52.2,
        angleRadians: math.pi / 2 * .9,
      ),
      Vector2(0, 70),
      4,
    );

    expect(contact, isNull);
  });
}

AttackInstance _hwandoAttack({
  Vector2? origin,
  Vector2? direction,
}) => AttackInstance(
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
  origin: origin ?? Vector2(20, 30),
  direction: direction ?? Vector2(1, 0),
  sequenceIndex: 0,
);
