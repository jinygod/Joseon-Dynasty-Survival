import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/experience_gem_component.dart';
import 'package:pixel_survivor/game/components/player_component.dart';
import 'package:pixel_survivor/game/components/projectile_component.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/systems/weapon_system.dart';

void main() {
  group('WeaponSystem', () {
    test('hwando_slash cannot upgrade beyond max level 5', () {
      final system = WeaponSystem();
      const unlockedWeaponIds = {hwandoSlash};

      for (var i = 0; i < 6; i += 1) {
        system.upgrade(hwandoSlash, unlockedWeaponIds);
      }

      expect(system.levelOf(hwandoSlash), 5);
      expect(system.canUpgrade(hwandoSlash, unlockedWeaponIds), isFalse);
    });

    test('locked weapon cannot be upgraded', () {
      final system = WeaponSystem();

      system.upgrade(talismanThrow, {hwandoSlash});

      expect(system.levelOf(talismanThrow), 0);
      expect(system.canUpgrade(talismanThrow, {hwandoSlash}), isFalse);
    });

    test('availableUpgradeIds only includes unlocked upgradeable weapons', () {
      final system = WeaponSystem();

      expect(
        system.availableUpgradeIds({hwandoSlash, talismanThrow}),
        containsAllInOrder([hwandoSlash, talismanThrow]),
      );
      expect(
        system.availableUpgradeIds({hwandoSlash}),
        isNot(contains(talismanThrow)),
      );
    });
  });

  group('ProjectileComponent', () {
    test('update moves position by velocity over time', () {
      final projectile = ProjectileComponent(
        weaponId: gakgungShot,
        damage: 3,
        position: Vector2(10, 20),
        velocity: Vector2(4, -2),
      );

      projectile.update(0.5);

      expect(projectile.position.x, 12);
      expect(projectile.position.y, 19);
    });
  });

  group('ExperienceGemComponent', () {
    test('canBePickedUpBy uses pickup radius distance', () {
      final player = PlayerComponent(
        slotIndex: 0,
        maxHealth: 100,
        moveSpeed: 80,
        position: Vector2.zero(),
      );
      final nearGem = ExperienceGemComponent(
        experienceValue: 2,
        position: Vector2(18, 0),
        pickupRadius: 24,
      );
      final farGem = ExperienceGemComponent(
        experienceValue: 2,
        position: Vector2(25, 0),
        pickupRadius: 24,
      );

      expect(nearGem.canBePickedUpBy(player), isTrue);
      expect(farGem.canBePickedUpBy(player), isFalse);
    });
  });
}
