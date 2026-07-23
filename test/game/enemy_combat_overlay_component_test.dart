import 'dart:io';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/combat/attack_spec.dart';
import 'package:pixel_survivor/game/components/attack_effect_component.dart';
import 'package:pixel_survivor/game/components/enemy_combat_overlay_component.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/components/enemy_telegraph_vfx_component.dart';
import 'package:pixel_survivor/game/components/status_marker_vfx_component.dart';
import 'package:pixel_survivor/game/content/combat_visual_factory.dart';
import 'package:pixel_survivor/game/content/enemy_behavior_definitions.dart';
import 'package:pixel_survivor/game/content/ids.dart';
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

  test(
    'cached shield visual is centered, aimed, and still expires once',
    () async {
      final image = await _testImage();
      var callbacks = 0;
      final effect = ShieldBlockEffectComponent(
        position: Vector2.zero(),
        facingDirection: Vector2(0, -1),
        visualFactory: CombatVisualFactory(
          images: {'vfx/enemy/shield_block_flash_128.png': image},
        ),
        onExpired: () => callbacks += 1,
      );
      effect.onMount();
      expect(effect.registryVisual, isA<StatusMarkerVfxComponent>());
      expect(effect.registryVisual!.position, effect.center);
      expect(effect.registryVisual!.angle, closeTo(-1.5708, .001));
      effect.update(.22);
      effect.update(1);
      expect(callbacks, 1);
    },
  );

  test(
    'warning delegates map cached radial and line visuals and replace phases',
    () async {
      final image = await _testImage();
      const profile = EnemyBehaviorProfile(
        id: 'warning',
        kind: EnemyBehaviorKind.ranged,
        warningSeconds: .1,
        activeSeconds: .05,
        recoverySeconds: .05,
        cooldownSeconds: .1,
        range: 40,
        preferredRange: 10,
        minimumRange: 0,
      );
      final enemy = EnemyComponent(
        enemyId: 'test',
        maxHealth: 1,
        moveSpeed: 0,
        damage: 1,
        behaviorProfile: profile,
        targetPositionProvider: (_) => Vector2(20, 0),
      );
      final overlay = EnemyWarningOverlayComponent(
        enemy: enemy,
        visualFactory: CombatVisualFactory(
          images: {'vfx/enemy/ranged_telegraph_128.png': image},
        ),
      );
      enemy.update(.05);
      overlay.update(0);
      final first = overlay.registryVisual;
      expect(first, isA<EnemyTelegraphVfxComponent>());
      expect(
        overlay.visualLength,
        greaterThanOrEqualTo(40 + enemy.size.x / 2 + 12),
      );
      expect(
        first!.position.x,
        closeTo(overlay.center.x + overlay.visualLength / 2, .001),
      );
      expect(
        first.scale.x * EnemyWarningOverlayComponent.lineActiveLength,
        closeTo(overlay.visualLength, .001),
      );
      overlay.update(0);
      expect(identical(overlay.registryVisual, first), isTrue);
      enemy.update(.1);
      overlay.update(0);
      expect(overlay.registryVisual, isNull);
      expect(overlay.children, isEmpty);
      for (var i = 0; i < 7; i++) {
        enemy.update(.05);
      }
      overlay.update(0);
      expect(overlay.registryVisual, isNot(same(first)));
    },
  );

  test('missing warning image retains fallback without a delegate', () {
    final enemy = EnemyComponent.fromDefinition(
      enemyDefinitionFor(sakkatSpecter)!,
      targetPositionProvider: (_) => Vector2(100, 0),
    );
    enemy.update(.05);
    final overlay = EnemyWarningOverlayComponent(
      enemy: enemy,
      visualFactory: const CombatVisualFactory(images: {}),
    )..update(0);
    expect(overlay.usesRegistryVisual, isFalse);
    expect(overlay.registryVisual, isNull);
  });
}

Future<Image> _testImage() {
  final recorder = PictureRecorder();
  Canvas(recorder).drawRect(const Rect.fromLTWH(0, 0, 1, 1), Paint());
  return recorder.endRecording().toImage(1, 1);
}
