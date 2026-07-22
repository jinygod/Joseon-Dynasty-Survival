import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/components/experience_gem_component.dart';
import 'package:pixel_survivor/game/components/player_component.dart';
import 'package:pixel_survivor/game/components/projectile_component.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/content/ids.dart';
import 'package:pixel_survivor/game/combat/attack_spec.dart';
import 'package:pixel_survivor/game/systems/weapon_system.dart';

void main() {
  group('WeaponSystem', () {
    test('hwando_slash cannot upgrade beyond max level 6', () {
      final system = WeaponSystem();
      const unlockedWeaponIds = {hwandoSlash};

      for (var i = 0; i < 7; i += 1) {
        system.upgrade(hwandoSlash, unlockedWeaponIds);
      }

      expect(system.levelOf(hwandoSlash), 6);
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

    test('direct upgrade cannot add a seventh weapon', () {
      final system = WeaponSystem(
        initialLevels: const {
          hwandoSlash: 1,
          gakgungShot: 1,
          talismanThrow: 1,
          thunderCrashBomb: 1,
          jangseungWard: 1,
          singijeonVolley: 1,
        },
      );
      final unlocked = weaponDefinitions.map((item) => item.id).toSet();

      expect(system.ownedWeaponCount, 6);
      expect(system.canUpgrade(frostFlask, unlocked), isFalse);
      system.upgrade(frostFlask, unlocked);
      expect(system.levelOf(frostFlask), 0);
      expect(system.canUpgrade(hwandoSlash, unlocked), isTrue);
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

    test('element multiplier only affects weapons of that element', () {
      final system = WeaponSystem(
        initialLevels: const {hwandoSlash: 1, talismanThrow: 1},
        random: Random(1),
      );
      final enemy = EnemyComponent(
        enemyId: 'test_enemy',
        maxHealth: 100,
        moveSpeed: 0,
        damage: 1,
        position: Vector2(20, 0),
      );

      final result = system.tick(
        dt: 2,
        origin: Vector2.zero(),
        enemies: [enemy],
        elementDamageMultipliers: const {ElementType.magic: 1.15},
      );

      expect(
        result.damageEvents
            .singleWhere((event) => event.weaponId == hwandoSlash)
            .damage,
        8,
      );
      expect(
        result.attackInstances
            .singleWhere((attack) => attack.spec.id == 'talisman_explosion')
            .spec
            .damage,
        closeTo(9.2, 0.0001),
      );
    });

    test('gakgung mastery emits one lead and two follow-up projectiles', () {
      final strongest = EnemyComponent(
        enemyId: 'strongest',
        maxHealth: 90,
        moveSpeed: 0,
        damage: 1,
        position: Vector2(80, 0),
      );
      final weaker = EnemyComponent(
        enemyId: 'weaker',
        maxHealth: 30,
        moveSpeed: 0,
        damage: 1,
        position: Vector2(40, 0),
      );
      final system = WeaponSystem(initialLevels: const {gakgungShot: 6});

      final result = system.tick(
        dt: 1,
        origin: Vector2.zero(),
        enemies: [weaker, strongest],
      );
      final arrows = result.projectiles
          .where((projectile) => projectile.weaponId == gakgungShot)
          .toList();

      expect(arrows, hasLength(3));
      expect(arrows.first.isMasterLead, isTrue);
      expect(arrows.map((arrow) => arrow.followUpIndex), [0, 1, 2]);
      expect(
        result.areaAttacks.where((area) => area.weaponId == gakgungShot),
        isEmpty,
      );
    });

    test('five legacy weapon masters emit distinct expanded patterns', () {
      final enemies = [
        EnemyComponent(
          enemyId: 'north',
          maxHealth: 200,
          moveSpeed: 0,
          damage: 1,
          position: Vector2(0, -50),
        ),
        EnemyComponent(
          enemyId: 'east',
          maxHealth: 200,
          moveSpeed: 0,
          damage: 1,
          position: Vector2(50, 0),
        ),
      ];
      WeaponTickResult tick(WeaponId id) => WeaponSystem(
        initialLevels: {id: 6},
        random: Random(4),
      ).tick(dt: 2, origin: Vector2.zero(), enemies: enemies);

      final bomb = tick(thunderCrashBomb);
      final ward = tick(jangseungWard);
      final singijeon = tick(singijeonVolley);
      final frost = tick(frostFlask);
      final fan = tick(windThunderFan);

      expect(bomb.areaAttacks, hasLength(5));
      expect(
        bomb.areaAttacks.map((attack) => attack.position.toString()).toSet(),
        hasLength(5),
      );
      expect(
        ward.meleeArcs.where((arc) => arc.weaponId == jangseungWard),
        hasLength(4),
      );
      expect(
        singijeon.projectiles.map((projectile) => projectile.laneIndex).toSet(),
        {0, 1, 2},
      );
      expect(frost.frostFields, hasLength(3));
      expect(
        fan.meleeArcs.map((arc) => arc.direction.toString()).toSet(),
        hasLength(6),
      );
    });

    test('four new weapon masters execute their authored combat rules', () {
      final enemies = [
        EnemyComponent(
          enemyId: 'close',
          maxHealth: 200,
          moveSpeed: 0,
          damage: 1,
          position: Vector2(44, 0),
        ),
        EnemyComponent(
          enemyId: 'line',
          maxHealth: 200,
          moveSpeed: 0,
          damage: 1,
          position: Vector2(120, 8),
        ),
      ];
      WeaponTickResult tick(WeaponId id) => WeaponSystem(
        initialLevels: {id: 6},
        random: Random(7),
      ).tick(dt: 2, origin: Vector2.zero(), enemies: enemies);

      final cannon = tick(matchlockCannon);
      final bells = tick(shamanBells);
      final chain = tick(dokkaebiChain);
      final hawk = tick(hawkSummon);

      expect(cannon.projectiles.single.weaponId, matchlockCannon);
      expect(cannon.projectiles.single.isMasterLead, isTrue);
      expect(cannon.areaAttacks.single.weaponId, matchlockCannon);
      expect(
        bells.meleeArcs.where((arc) => arc.weaponId == shamanBells),
        hasLength(3),
      );
      expect(
        chain.meleeArcs.where((arc) => arc.weaponId == dokkaebiChain),
        hasLength(6),
      );
      expect(
        chain.damageEvents
            .where((event) => event.weaponId == dokkaebiChain)
            .every((event) => event.direction.x < 0),
        isTrue,
      );
      expect(
        hawk.projectiles.where(
          (projectile) => projectile.weaponId == hawkSummon,
        ),
        hasLength(5),
      );
      expect(
        hawk.projectiles.map((projectile) => projectile.laneIndex).toSet(),
        {0, 1, 2, 3, 4},
      );
      expect(cannon.firedWeaponIds, contains(matchlockCannon));
      expect(bells.firedWeaponIds, contains(shamanBells));
      expect(chain.firedWeaponIds, contains(dokkaebiChain));
      expect(hawk.firedWeaponIds, contains(hawkSummon));
    });

    test('level five hwando creates timed arc attacks with knockback', () {
      final enemy = EnemyComponent(
        enemyId: 'bandit',
        maxHealth: 100,
        moveSpeed: 0,
        damage: 1,
        position: Vector2(20, 0),
      );

      final system = WeaponSystem(
        initialLevels: const {hwandoSlash: 5},
        random: Random(1),
      );
      final results = [
        system.tick(dt: 1, origin: Vector2.zero(), enemies: [enemy]),
        system.tick(dt: .05, origin: Vector2.zero(), enemies: [enemy]),
        system.tick(dt: .05, origin: Vector2.zero(), enemies: [enemy]),
      ];
      final arcs = results.expand((result) => result.meleeArcs).toList();
      final damageEvents = results
          .expand((result) => result.damageEvents)
          .toList();

      expect(arcs, hasLength(2));
      expect(damageEvents, hasLength(2));
      expect(damageEvents.every((event) => event.knockback > 0), isTrue);
    });

    test('hwando freezes the nearest in-range enemy direction', () {
      final north = EnemyComponent(
        enemyId: 'north',
        maxHealth: 100,
        moveSpeed: 0,
        damage: 1,
        position: Vector2(0, -20),
      );
      final east = EnemyComponent(
        enemyId: 'east',
        maxHealth: 100,
        moveSpeed: 0,
        damage: 1,
        position: Vector2(30, 0),
      );

      final result = WeaponSystem(initialLevels: const {hwandoSlash: 1}).tick(
        dt: 1,
        origin: Vector2.zero(),
        enemies: [east, north],
        hwandoFallbackDirection: Vector2(-1, 0),
      );

      expect(result.hwandoDirection, Vector2(0, -1));
      expect(result.meleeArcs.single.direction, result.hwandoDirection);
      expect(result.attackInstances.single.direction, result.hwandoDirection);
      expect(result.attackInstances.single.spec.shape, AttackShape.sector);
    });

    test(
      'hwando uses fallback when only dead or out-of-range enemies exist',
      () {
        final dead = EnemyComponent(
          enemyId: 'dead',
          maxHealth: 1,
          moveSpeed: 0,
          damage: 1,
          position: Vector2(2, 0),
        )..takeDamage(1);
        final outside = EnemyComponent(
          enemyId: 'outside',
          maxHealth: 100,
          moveSpeed: 0,
          damage: 1,
          position: Vector2(70, 0),
        );

        final result = WeaponSystem(initialLevels: const {hwandoSlash: 1}).tick(
          dt: 1,
          origin: Vector2.zero(),
          enemies: [dead, outside],
          hwandoFallbackDirection: Vector2(0, -4),
        );

        expect(result.hwandoDirection, Vector2(0, -1));
        expect(result.meleeArcs, hasLength(1));
        expect(result.damageEvents, isEmpty);
      },
    );

    test(
      'dead and out-of-range targets do not redirect queued hwando stages',
      () {
        final north = EnemyComponent(
          enemyId: 'north',
          maxHealth: 1,
          moveSpeed: 0,
          damage: 1,
          position: Vector2(0, -20),
        );
        final outside = EnemyComponent(
          enemyId: 'outside',
          maxHealth: 100,
          moveSpeed: 0,
          damage: 1,
          position: Vector2(200, 0),
        );
        final system = WeaponSystem(initialLevels: const {hwandoSlash: 3});

        final first = system.tick(
          dt: 1,
          origin: Vector2.zero(),
          enemies: [north, outside],
          hwandoFallbackDirection: Vector2(-1, 0),
        );
        north.takeDamage(1);
        system.tick(
          dt: .05,
          origin: Vector2.zero(),
          enemies: [north, outside],
          hwandoFallbackDirection: Vector2(-1, 0),
        );
        final second = system.tick(
          dt: .05,
          origin: Vector2.zero(),
          enemies: [north, outside],
          hwandoFallbackDirection: Vector2(-1, 0),
        );

        expect(
          first.attackInstances.single.direction.x,
          closeTo(-sqrt1_2, 0.000001),
        );
        expect(
          first.attackInstances.single.direction.y,
          closeTo(-sqrt1_2, 0.000001),
        );
        expect(
          second.attackInstances.single.direction.x,
          closeTo(sqrt1_2, 0.000001),
        );
        expect(
          second.attackInstances.single.direction.y,
          closeTo(-sqrt1_2, 0.000001),
        );
      },
    );

    test('hwando can slash along fallback when no enemy exists', () {
      final result = WeaponSystem(initialLevels: const {hwandoSlash: 1}).tick(
        dt: 1,
        origin: Vector2.zero(),
        enemies: const [],
        hwandoFallbackDirection: Vector2(-1, 0),
      );

      expect(result.firedWeaponIds, [hwandoSlash]);
      expect(result.hwandoDirection, Vector2(-1, 0));
      expect(result.meleeArcs.single.direction, Vector2(-1, 0));
    });

    test('hwando effect angle and damage cone share one direction', () {
      final inside = EnemyComponent(
        enemyId: 'inside',
        maxHealth: 100,
        moveSpeed: 0,
        damage: 1,
        position: Vector2(20, 20),
      );
      final outside = EnemyComponent(
        enemyId: 'outside',
        maxHealth: 100,
        moveSpeed: 0,
        damage: 1,
        position: Vector2(-20, -20),
      );

      final result = WeaponSystem(
        initialLevels: const {hwandoSlash: 1},
      ).tick(dt: 1, origin: Vector2.zero(), enemies: [inside, outside]);
      final arc = result.meleeArcs.single;
      final expectedTargets = [
        inside,
        outside,
      ].where(arc.containsEnemy).toSet();

      expect(
        arc.facingAngle,
        closeTo(atan2(arc.direction.y, arc.direction.x), 1e-9),
      );
      expect(
        result.damageEvents.map((event) => event.target).toSet(),
        expectedTargets,
      );
    });

    test('talisman attaches to unique nearby targets before exploding', () {
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

      final system = WeaponSystem(
        initialLevels: const {talismanThrow: 3},
        random: Random(1),
      );
      final attached = system.tick(
        dt: 2,
        origin: Vector2.zero(),
        enemies: enemies,
      );

      expect(attached.damageEvents, isEmpty);
      expect(
        system.attachedTalismans.map((seal) => seal.target).toSet(),
        hasLength(3),
      );

      final exploded = system.tick(
        dt: .6,
        origin: Vector2.zero(),
        enemies: enemies,
      );
      expect(exploded.attackInstances, hasLength(3));
    });

    test('talisman mastery exposes at most three five-color wards', () {
      final enemies = List.generate(
        12,
        (index) => EnemyComponent(
          enemyId: 'enemy_$index',
          maxHealth: 100,
          moveSpeed: 0,
          damage: 1,
          position: Vector2((index ~/ 3) * 100.0, (index % 3) * 3.0),
        ),
      );

      final result = WeaponSystem(
        initialLevels: const {talismanThrow: 6},
      ).tick(dt: 2, origin: Vector2.zero(), enemies: enemies);

      expect(result.fiveColorWards, hasLength(3));
      expect(
        result.fiveColorWards.every(
          (ward) => ward.attack.spec.presentation == AttackPresentation.master,
        ),
        isTrue,
      );
    });

    test('talisman critical chance is frozen through WeaponSystem', () {
      final target = EnemyComponent(
        enemyId: 'bandit',
        maxHealth: 100,
        moveSpeed: 0,
        damage: 1,
        position: Vector2(20, 0),
      );
      final system = WeaponSystem(
        initialLevels: const {talismanThrow: 3},
        random: Random(1),
      );
      system.tick(
        dt: 2,
        origin: Vector2.zero(),
        enemies: [target],
        criticalChance: 1,
      );

      final result = system.tick(
        dt: .6,
        origin: Vector2.zero(),
        enemies: [target],
        criticalChance: 0,
      );

      expect(result.attackInstances.single.isCritical, isTrue);
      expect(result.attackInstances.single.spec.damage, 12);
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

    test('jangseung ward damages and knocks back every nearby enemy', () {
      final nearEnemies = [
        EnemyComponent(
          enemyId: 'a',
          maxHealth: 20,
          moveSpeed: 0,
          damage: 1,
          position: Vector2(30, 0),
        ),
        EnemyComponent(
          enemyId: 'b',
          maxHealth: 20,
          moveSpeed: 0,
          damage: 1,
          position: Vector2(-30, 0),
        ),
      ];
      final farEnemy = EnemyComponent(
        enemyId: 'far',
        maxHealth: 20,
        moveSpeed: 0,
        damage: 1,
        position: Vector2(200, 0),
      );

      final result = WeaponSystem(initialLevels: const {jangseungWard: 1}).tick(
        dt: 1,
        origin: Vector2.zero(),
        enemies: [...nearEnemies, farEnemy],
      );

      expect(
        result.damageEvents.map((event) => event.target).toSet(),
        nearEnemies.toSet(),
      );
      expect(
        result.damageEvents.every((event) => event.knockback == 18),
        isTrue,
      );
    });

    test('singijeon aims its fan toward the densest enemy cluster', () {
      final enemies = [
        for (var y = -20.0; y <= 20; y += 20)
          EnemyComponent(
            enemyId: 'east',
            maxHealth: 20,
            moveSpeed: 0,
            damage: 1,
            position: Vector2(120, y),
          ),
        EnemyComponent(
          enemyId: 'west',
          maxHealth: 20,
          moveSpeed: 0,
          damage: 1,
          position: Vector2(-40, 0),
        ),
      ];

      final result = WeaponSystem(
        initialLevels: const {singijeonVolley: 1},
      ).tick(dt: 3, origin: Vector2.zero(), enemies: enemies);

      expect(result.projectiles, hasLength(4));
      expect(result.projectiles.every((shot) => shot.velocity.x > 0), isTrue);
    });

    test('frost flask creates a tuned persistent field', () {
      final target = EnemyComponent(
        enemyId: 'target',
        maxHealth: 20,
        moveSpeed: 0,
        damage: 1,
        position: Vector2(70, 10),
      );

      final result = WeaponSystem(
        initialLevels: const {frostFlask: 3},
      ).tick(dt: 3, origin: Vector2.zero(), enemies: [target]);

      expect(result.frostFields, hasLength(1));
      expect(result.frostFields.single.position, target.position);
      expect(result.frostFields.single.radius, 80);
      expect(result.frostFields.single.durationSeconds, 3.5);
      expect(result.frostFields.single.slowFraction, .30);
    });

    test('level five wind thunder fan sweeps forward and backward', () {
      final enemies = [
        EnemyComponent(
          enemyId: 'east',
          maxHealth: 30,
          moveSpeed: 0,
          damage: 1,
          position: Vector2(50, 0),
        ),
        EnemyComponent(
          enemyId: 'west',
          maxHealth: 30,
          moveSpeed: 0,
          damage: 1,
          position: Vector2(-50, 0),
        ),
      ];

      final result = WeaponSystem(
        initialLevels: const {windThunderFan: 5},
      ).tick(dt: 2, origin: Vector2.zero(), enemies: enemies);

      expect(result.meleeArcs, hasLength(2));
      expect(
        result.damageEvents.map((event) => event.target).toSet(),
        enemies.toSet(),
      );
      expect(
        result.damageEvents.every((event) => event.knockback == 100),
        isTrue,
      );
    });

    test('tick reports every weapon that actually fires', () {
      final enemy = EnemyComponent(
        enemyId: 'target',
        maxHealth: 1000,
        moveSpeed: 0,
        damage: 0,
        position: Vector2(20, 0),
      );
      final system = WeaponSystem(
        initialLevels: const {
          hwandoSlash: 1,
          gakgungShot: 1,
          talismanThrow: 1,
          thunderCrashBomb: 1,
          jangseungWard: 1,
          singijeonVolley: 1,
          frostFlask: 1,
          windThunderFan: 1,
        },
        random: Random(1),
      );

      final result = system.tick(
        dt: 10,
        origin: Vector2.zero(),
        enemies: [enemy],
      );

      expect(result.firedWeaponIds, [
        hwandoSlash,
        gakgungShot,
        talismanThrow,
        thunderCrashBomb,
        jangseungWard,
        singijeonVolley,
        frostFlask,
        windThunderFan,
      ]);
    });

    test('tick does not report a weapon while its cooldown is active', () {
      final enemy = EnemyComponent(
        enemyId: 'target',
        maxHealth: 1000,
        moveSpeed: 0,
        damage: 0,
        position: Vector2(20, 0),
      );
      final system = WeaponSystem(
        initialLevels: const {hwandoSlash: 1},
        random: Random(1),
      );
      system.tick(dt: 1, origin: Vector2.zero(), enemies: [enemy]);

      final result = system.tick(
        dt: 0.01,
        origin: Vector2.zero(),
        enemies: [enemy],
      );

      expect(result.firedWeaponIds, isEmpty);
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
