import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/combat/attack_spec.dart';
import 'package:pixel_survivor/game/components/attack_effect_component.dart';
import 'package:pixel_survivor/game/components/enemy_combat_overlay_component.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';

void main() {
  test('attack effects reference the shared attack presentation priority', () {
    final source = File(
      'lib/game/components/attack_effect_component.dart',
    ).readAsStringSync();

    expect(
      source,
      contains(RegExp(r'priority:\s*AttackPresentationPriority\.attack')),
    );
  });

  test(
    'enemy warning overlay stays above attack effects while body stays below',
    () {
      final enemy = EnemyComponent.fromDefinition(
        enemyDefinitionFor(plagueCrow)!,
      )..position.setValues(20, 30);
      final warning = EnemyWarningOverlayComponent(enemy: enemy);
      final attack = AttackEffectComponent(
        instance: AttackInstance(
          spec: AttackSpec(
            id: 'master',
            shape: AttackShape.circle,
            damage: 1,
            range: 0,
            angleRadians: 0,
            radius: 20,
            width: 0,
            windupSeconds: 0,
            activeSeconds: .1,
            lingerSeconds: .1,
            knockback: 0,
            slowFraction: 0,
            traits: const {AttackTrait.master},
            presentation: AttackPresentation.master,
          ),
          origin: Vector2.zero(),
          direction: Vector2(1, 0),
          sequenceIndex: 0,
        ),
      );

      warning.update(0);
      expect(enemy.priority, lessThan(attack.priority));
      expect(warning.priority, greaterThan(attack.priority));
      expect(warning.position, enemy.position);
    },
  );

  test('shield block feedback is visually distinct and short lived', () {
    var expirations = 0;
    final effect = ShieldBlockEffectComponent(
      position: Vector2(10, 20),
      facingDirection: Vector2(0, -1),
      onExpired: () => expirations += 1,
    );

    expect(effect.facingDirection, Vector2(0, -1));
    expect(effect.lifetime, lessThanOrEqualTo(.3));
    effect.update(effect.lifetime);
    effect.update(1);
    expect(expirations, 1);
  });
}
