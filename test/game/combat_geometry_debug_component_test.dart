import 'dart:math' as math;
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/combat/attack_geometry.dart';
import 'package:pixel_survivor/game/combat/attack_presentation_contract.dart';
import 'package:pixel_survivor/game/combat/attack_spec.dart';
import 'package:pixel_survivor/game/combat/attack_timeline.dart';
import 'package:pixel_survivor/game/components/combat_geometry_debug_component.dart';

void main() {
  test('gallery gates combat geometry behind debug mode', () {
    final source = File('lib/game/vfx_gallery_game.dart').readAsStringSync();

    expect(source, contains('if (!kDebugMode) return;'));
    expect(source, contains('CombatGeometryDebugComponent'));
  });

  test('debug geometry keeps the exact visual hit hurt and contact data', () {
    final attack = AttackInstance(
      spec: AttackSpec(
        id: 'hwando_slash',
        shape: AttackShape.sector,
        damage: 1,
        range: 100,
        angleRadians: math.pi / 2,
        radius: 0,
        width: 0,
        windupSeconds: .06,
        activeSeconds: .08,
        lingerSeconds: .10,
        knockback: 0,
        slowFraction: 0,
        traits: const {AttackTrait.melee},
        presentation: AttackPresentation.normal,
      ),
      origin: Vector2(10, 20),
      direction: Vector2(1, 0),
      sequenceIndex: 0,
    );
    final contract = AttackPresentationContract.fromAttack(attack);
    final target = Vector2(75, 20);
    final contact = AttackGeometry.sectorContact(
      contract.hitSector,
      target,
      10,
    )!;
    final component = CombatGeometryDebugComponent(
      contract: contract,
      targetCenter: target,
      targetRadius: 10,
      contact: contact,
    );

    expect(component.contract, same(contract));
    expect(component.visualRadius, 100);
    expect(component.hitRadius, 90);
    expect(component.targetCenter, target);
    expect(component.contactPoint, contact.point);
    component.phase = AttackPhase.active;
    component.remainingMilliseconds = 42;
    expect(component.phase, AttackPhase.active);
    expect(component.remainingMilliseconds, 42);
  });
}
