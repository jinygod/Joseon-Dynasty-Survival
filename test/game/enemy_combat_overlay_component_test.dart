import 'dart:math' show pi;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/combat/attack_spec.dart';
import 'package:pixel_survivor/game/components/attack_effect_component.dart';
import 'package:pixel_survivor/game/components/enemy_combat_overlay_component.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';

void main() {
  test(
    'overlay style limits warning opacity and keeps shields as low arcs',
    () {
      expect(EnemyCombatOverlayStyle.warningAlpha, lessThanOrEqualTo(.32));
      expect(EnemyCombatOverlayStyle.shieldSweepRadians, closeTo(pi / 2, 1e-9));
      expect(EnemyCombatOverlayStyle.usesFullBodyRectangle, isFalse);
    },
  );

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

  test('warning ranks keep the nearest eight at the normal opacity', () {
    final overlays = List.generate(10, (index) {
      final enemy = EnemyComponent(
        enemyId: 'warning-$index',
        maxHealth: 1,
        moveSpeed: 0,
        damage: 0,
        position: Vector2(index.toDouble(), 0),
      );
      return EnemyWarningOverlayComponent(enemy: enemy);
    });

    EnemyWarningOverlayComponent.rankByDistance(
      overlays,
      playerPosition: Vector2.zero(),
    );

    for (var index = 0; index < 8; index += 1) {
      expect(
        overlays[index].warningAlpha,
        EnemyCombatOverlayStyle.warningAlpha,
      );
    }
    expect(overlays[8].warningAlpha, EnemyCombatOverlayStyle.warningAlpha * .5);
    expect(overlays[9].warningAlpha, EnemyCombatOverlayStyle.warningAlpha * .5);
  });

  test('shield block feedback is visually distinct and short lived', () {
    var expirations = 0;
    final effect = ShieldBlockEffectComponent(
      position: Vector2(10, 20),
      facingDirection: Vector2(0, -1),
      onExpired: () => expirations += 1,
    );

    expect(effect.facingDirection, Vector2(0, -1));
    expect(effect.lifetime, lessThanOrEqualTo(.3));
    expect(
      effect.priority,
      lessThan(
        EnemyWarningOverlayComponent(
          enemy: EnemyComponent(
            enemyId: 'warning-priority',
            maxHealth: 1,
            moveSpeed: 0,
            damage: 0,
          ),
        ).priority,
      ),
    );
    effect.update(effect.lifetime);
    effect.update(1);
    expect(expirations, 1);
  });
}
