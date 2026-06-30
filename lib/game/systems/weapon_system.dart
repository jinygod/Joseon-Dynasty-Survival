import 'dart:math';

import 'package:flame/components.dart';

import '../components/enemy_component.dart';
import '../components/projectile_component.dart';
import '../content/ids.dart';
import '../content/weapon_definitions.dart';

class WeaponSystem {
  WeaponSystem({Map<WeaponId, int>? initialLevels, Random? random})
    : _random = random ?? Random() {
    if (initialLevels != null) {
      _levels.addAll(initialLevels);
    }
  }

  final Map<WeaponId, int> _levels = {};
  final Map<WeaponId, double> _cooldowns = {};
  final Random _random;

  Map<WeaponId, int> get levels => Map.unmodifiable(_levels);

  int levelOf(WeaponId weaponId) => _levels[weaponId] ?? 0;

  bool canUpgrade(WeaponId weaponId, Set<WeaponId> unlockedWeaponIds) {
    final definition = _definitionFor(weaponId);
    if (definition == null || !unlockedWeaponIds.contains(weaponId)) {
      return false;
    }

    return levelOf(weaponId) < definition.maxLevel;
  }

  void upgrade(WeaponId weaponId, Set<WeaponId> unlockedWeaponIds) {
    if (!canUpgrade(weaponId, unlockedWeaponIds)) {
      return;
    }

    _levels[weaponId] = levelOf(weaponId) + 1;
  }

  List<WeaponId> availableUpgradeIds(Set<WeaponId> unlockedWeaponIds) {
    return weaponDefinitions
        .where((definition) => canUpgrade(definition.id, unlockedWeaponIds))
        .map((definition) => definition.id)
        .toList(growable: false);
  }

  WeaponTickResult tick({
    required double dt,
    required Vector2 origin,
    required Iterable<EnemyComponent> enemies,
    double damageMultiplier = 1,
  }) {
    final aliveEnemies = enemies.where((enemy) => !enemy.isDead).toList();
    final projectiles = <ProjectileComponent>[];
    if (aliveEnemies.isEmpty) {
      return const WeaponTickResult.empty();
    }

    if (_consumeCooldown(hwandoSlash, dt, 0.7)) {
      _damageNearestEnemy(
        origin: origin,
        enemies: aliveEnemies,
        damage: _scaledDamage(6 + levelOf(hwandoSlash) * 2, damageMultiplier),
        maxRange: 52,
      );
    }

    if (_consumeCooldown(gakgungShot, dt, 1.1)) {
      final projectile = _projectileTowardNearestEnemy(
        weaponId: gakgungShot,
        origin: origin,
        enemies: aliveEnemies,
        damage: _scaledDamage(5 + levelOf(gakgungShot) * 2, damageMultiplier),
        speed: 220,
      );
      if (projectile != null) {
        projectiles.add(projectile);
      }
    }

    if (_consumeCooldown(talismanThrow, dt, 1.5)) {
      final projectile = _projectileTowardNearestEnemy(
        weaponId: talismanThrow,
        origin: origin,
        enemies: aliveEnemies,
        damage: _scaledDamage(
          7 + levelOf(talismanThrow) * 2,
          damageMultiplier,
        ),
        speed: 120,
        size: Vector2.all(10),
      );
      if (projectile != null) {
        projectiles.add(projectile);
      }
    }

    if (_consumeCooldown(thunderCrashBomb, dt, 2.4)) {
      damageEnemiesNear(
        center: _bombCenter(origin, aliveEnemies),
        enemies: aliveEnemies,
        damage: _scaledDamage(
          8 + levelOf(thunderCrashBomb) * 3,
          damageMultiplier,
        ),
        radius: 72,
      );
    }

    return WeaponTickResult(projectiles: projectiles);
  }

  double _scaledDamage(num baseDamage, double damageMultiplier) {
    return baseDamage * damageMultiplier;
  }

  void damageEnemiesNear({
    required Vector2 center,
    required Iterable<EnemyComponent> enemies,
    required double damage,
    required double radius,
  }) {
    final radiusSquared = radius * radius;
    for (final enemy in enemies) {
      if (!enemy.isDead &&
          enemy.position.distanceToSquared(center) <= radiusSquared) {
        enemy.takeDamage(damage);
      }
    }
  }

  bool _consumeCooldown(WeaponId weaponId, double dt, double interval) {
    if (levelOf(weaponId) <= 0) {
      return false;
    }

    final remaining = (_cooldowns[weaponId] ?? 0) - dt;
    if (remaining > 0) {
      _cooldowns[weaponId] = remaining;
      return false;
    }

    _cooldowns[weaponId] = interval;
    return true;
  }

  void _damageNearestEnemy({
    required Vector2 origin,
    required List<EnemyComponent> enemies,
    required double damage,
    required double maxRange,
  }) {
    final nearest = _nearestEnemy(origin, enemies);
    if (nearest == null ||
        nearest.position.distanceToSquared(origin) > maxRange * maxRange) {
      return;
    }

    nearest.takeDamage(damage);
  }

  ProjectileComponent? _projectileTowardNearestEnemy({
    required WeaponId weaponId,
    required Vector2 origin,
    required List<EnemyComponent> enemies,
    required double damage,
    required double speed,
    Vector2? size,
  }) {
    final nearest = _nearestEnemy(origin, enemies);
    if (nearest == null) {
      return null;
    }

    final direction = nearest.position - origin;
    if (direction.length2 == 0) {
      direction.setValues(1, 0);
    } else {
      direction.normalize();
    }

    return ProjectileComponent(
      weaponId: weaponId,
      damage: damage,
      position: origin.clone(),
      velocity: direction * speed,
      size: size,
    );
  }

  Vector2 _bombCenter(Vector2 origin, List<EnemyComponent> enemies) {
    final nearest = _nearestEnemy(origin, enemies);
    if (nearest != null && _random.nextBool()) {
      return nearest.position.clone();
    }

    return enemies[_random.nextInt(enemies.length)].position.clone();
  }

  EnemyComponent? _nearestEnemy(Vector2 origin, List<EnemyComponent> enemies) {
    EnemyComponent? nearest;
    var nearestDistance = double.infinity;
    for (final enemy in enemies) {
      final distance = enemy.position.distanceToSquared(origin);
      if (distance < nearestDistance) {
        nearest = enemy;
        nearestDistance = distance;
      }
    }

    return nearest;
  }

  WeaponDefinition? _definitionFor(WeaponId weaponId) {
    for (final definition in weaponDefinitions) {
      if (definition.id == weaponId) {
        return definition;
      }
    }

    return null;
  }
}

class WeaponTickResult {
  const WeaponTickResult({this.projectiles = const []});

  const WeaponTickResult.empty() : projectiles = const [];

  final List<ProjectileComponent> projectiles;
}
