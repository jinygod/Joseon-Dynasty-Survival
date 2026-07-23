import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/combat/attack_spec.dart';
import 'package:pixel_survivor/game/combat/attack_visual_event.dart';
import 'package:pixel_survivor/game/components/area_vfx_component.dart';
import 'package:pixel_survivor/game/components/enemy_telegraph_vfx_component.dart';
import 'package:pixel_survivor/game/components/projectile_vfx_component.dart';
import 'package:pixel_survivor/game/components/registry_vfx_component.dart';
import 'package:pixel_survivor/game/components/status_marker_vfx_component.dart';
import 'package:pixel_survivor/game/content/combat_visual_factory.dart';
import 'package:pixel_survivor/game/content/attack_visual_registry.dart';

void main() {
  const factory = CombatVisualFactory(images: {});

  AttackVisualEvent eventFor(String effectId) {
    return AttackVisualEvent.fromAttack(
      AttackInstance(
        spec: AttackSpec(
          id: effectId,
          shape: AttackShape.circle,
          damage: 0,
          range: 0,
          angleRadians: 0,
          radius: 0,
          width: 0,
          windupSeconds: 0,
          activeSeconds: 1,
          lingerSeconds: 0,
          knockback: 0,
          slowFraction: 0,
          traits: const {},
          presentation: AttackPresentation.normal,
        ),
        origin: Vector2.zero(),
        direction: Vector2(1, 0),
        sequenceIndex: 0,
      ),
    );
  }

  AttackVisualSpec specFor(CombatVisualCategory category) {
    return AttackVisualSpec(
      effectId: 'test_${category.name}',
      category: category,
      status: AttackVisualStatus.temporary,
      layers: const [],
      rotateWithDirection: false,
    );
  }

  test('factory dispatches each visual category', () {
    expect(
      factory.createFromSpec(
        eventFor('test_projectile'),
        specFor(CombatVisualCategory.projectile),
      ),
      isA<ProjectileVfxComponent>(),
    );
    expect(
      factory.createFromSpec(
        eventFor('test_area'),
        specFor(CombatVisualCategory.area),
      ),
      isA<AreaVfxComponent>(),
    );
    expect(
      factory.createFromSpec(
        eventFor('test_telegraph'),
        specFor(CombatVisualCategory.telegraph),
      ),
      isA<EnemyTelegraphVfxComponent>(),
    );
    expect(
      factory.createFromSpec(
        eventFor('test_status'),
        specFor(CombatVisualCategory.status),
      ),
      isA<StatusMarkerVfxComponent>(),
    );
  });

  for (final category in <CombatVisualCategory>[
    CombatVisualCategory.projectile,
    CombatVisualCategory.area,
    CombatVisualCategory.telegraph,
    CombatVisualCategory.status,
  ]) {
    test('${category.name} VFX expires and calls its callback once', () {
      var expired = 0;
      final event = eventFor('test_${category.name}');
      final spec = specFor(category);
      final RegistryVfxComponent component = switch (category) {
        CombatVisualCategory.projectile => ProjectileVfxComponent(
          event: event,
          spec: spec,
          images: const {},
          onExpired: () => expired += 1,
        ),
        CombatVisualCategory.area => AreaVfxComponent(
          event: event,
          spec: spec,
          images: const {},
          onExpired: () => expired += 1,
        ),
        CombatVisualCategory.telegraph => EnemyTelegraphVfxComponent(
          event: event,
          spec: spec,
          images: const {},
          onExpired: () => expired += 1,
        ),
        CombatVisualCategory.status => StatusMarkerVfxComponent(
          event: event,
          spec: spec,
          images: const {},
          onExpired: () => expired += 1,
        ),
        CombatVisualCategory.hwando => throw StateError('not a registry VFX'),
      };

      component.update(event.duration + .001);
      component.update(1);

      expect(component.isRemoving, isTrue);
      expect(expired, 1);
    });
  }
}
