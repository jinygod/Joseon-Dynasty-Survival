import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
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

    test('tick applies damage multiplier to weapon damage', () {
      final system = WeaponSystem(initialLevels: const {hwandoSlash: 1});
      final enemy = EnemyComponent(
        enemyId: 'test_enemy',
        maxHealth: 20,
        moveSpeed: 0,
        damage: 1,
        position: Vector2(20, 0),
      );

      final result = system.tick(
        dt: 1,
        origin: Vector2.zero(),
        enemies: [enemy],
        damageMultiplier: 2,
      );

      expect(result.damageEvents.single.damage, 16);
      expect(enemy.currentHealth, 20);
    });

    test('level five hwando creates two arc attacks with knockback', () {
      final enemy = EnemyComponent(
        enemyId: 'bandit',
        maxHealth: 100,
        moveSpeed: 0,
        damage: 1,
        position: Vector2(20, 0),
      );

      final result = WeaponSystem(
        initialLevels: const {hwandoSlash: 5},
        random: Random(1),
      ).tick(dt: 1, origin: Vector2.zero(), enemies: [enemy]);

      expect(result.meleeArcs, hasLength(2));
      expect(result.damageEvents, hasLength(2));
      expect(result.damageEvents.every((event) => event.knockback > 0), isTrue);
    });

    test('talisman chains to unique nearby targets', () {
      final enemies = List.generate(
        3,
        (index) => EnemyComponent(
          enemyId: 'vengeful_spirit',
          maxHealth: 20,
          moveSpeed: 0,
          damage: 1,
          position: Vector2(20.0 + index * 15, 0),
        ),
      );

      final result = WeaponSystem(
        initialLevels: const {talismanThrow: 3},
        random: Random(1),
      ).tick(dt: 2, origin: Vector2.zero(), enemies: enemies);

      expect(
        result.damageEvents.map((event) => event.target).toSet(),
        hasLength(3),
      );
    });

    test('bomb creates delayed area attack instead of immediate damage', () {
      final enemy = EnemyComponent(
        enemyId: 'bandit',
        maxHealth: 20,
        moveSpeed: 0,
        damage: 1,
        position: Vector2(20, 0),
      );

      final result = WeaponSystem(
        initialLevels: const {thunderCrashBomb: 1},
        random: Random(1),
      ).tick(dt: 3, origin: Vector2.zero(), enemies: [enemy]);

      expect(result.areaAttacks.single.delaySeconds, greaterThan(0));
      expect(result.damageEvents, isEmpty);
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

    test('expires after its lifetime elapses', () {
      final projectile = ProjectileComponent(
        weaponId: gakgungShot,
        damage: 3,
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        lifetime: 0.2,
      );

      projectile.update(0.1);

      expect(projectile.isExpired, isFalse);

      projectile.update(0.1);

      expect(projectile.isExpired, isTrue);
    });

    test('detects overlap with enemies using component sizes', () {
      final projectile = ProjectileComponent(
        weaponId: gakgungShot,
        damage: 3,
        position: Vector2.zero(),
        velocity: Vector2.zero(),
        size: Vector2.all(8),
      );
      final nearEnemy = EnemyComponent(
        enemyId: 'test_enemy',
        maxHealth: 10,
        moveSpeed: 0,
        damage: 1,
        position: Vector2(12, 0),
        size: Vector2.all(18),
      );
      final farEnemy = EnemyComponent(
        enemyId: 'test_enemy',
        maxHealth: 10,
        moveSpeed: 0,
        damage: 1,
        position: Vector2(14, 0),
        size: Vector2.all(18),
      );

      expect(projectile.overlapsEnemy(nearEnemy), isTrue);
      expect(projectile.overlapsEnemy(farEnemy), isFalse);
    });

    test('pierces configured targets once each', () {
      final projectile = ProjectileComponent(
        weaponId: gakgungShot,
        damage: 10,
        position: Vector2.zero(),
        velocity: Vector2(100, 0),
        pierce: 2,
      );
      final enemyA = EnemyComponent(
        enemyId: 'bandit',
        maxHealth: 10,
        moveSpeed: 0,
        damage: 1,
      );
      final enemyB = EnemyComponent(
        enemyId: 'bandit',
        maxHealth: 10,
        moveSpeed: 0,
        damage: 1,
      );
      final enemyC = EnemyComponent(
        enemyId: 'bandit',
        maxHealth: 10,
        moveSpeed: 0,
        damage: 1,
      );

      expect(projectile.registerHit(enemyA), isTrue);
      expect(projectile.registerHit(enemyA), isFalse);
      expect(projectile.registerHit(enemyB), isTrue);
      expect(projectile.isSpent, isFalse);
      expect(projectile.remainingPierces, 0);
      expect(projectile.registerHit(enemyC), isTrue);
      expect(projectile.isSpent, isTrue);
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
