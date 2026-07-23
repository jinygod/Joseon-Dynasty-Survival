import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/projectile_component.dart';
import 'package:pixel_survivor/game/content/combat_visual_factory.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';

void main() {
  test(
    'Singijeon composes a cached registry visual without loading on mount',
    () {
      final projectile = ProjectileComponent(
        weaponId: singijeonVolley,
        damage: 3,
        position: Vector2.zero(),
        velocity: Vector2(1, 0),
        visualFactory: const CombatVisualFactory(images: {}),
      );

      expect(projectile.usesRegistryVisual, isTrue);
      expect(projectile.startsImageLoadOnMount, isFalse);
      expect(projectile.ownsDamageResolution, isFalse);
      expect(projectile.gameplayOwnsDamageResolution, isTrue);
    },
  );
}
