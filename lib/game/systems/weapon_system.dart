import 'dart:math';

import 'package:flame/components.dart';

import '../components/area_attack_component.dart';
import '../components/enemy_component.dart';
import '../components/melee_arc_component.dart';
import '../components/projectile_component.dart';
import '../content/enemy_definitions.dart';
import '../content/ids.dart';
import '../content/weapon_definitions.dart';
import '../content/weapon_level_definitions.dart';
import '../models/damage_event.dart';

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
    if (canUpgrade(weaponId, unlockedWeaponIds)) {
      _levels[weaponId] = levelOf(weaponId) + 1;
    }
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
    double attackSpeedMultiplier = 1,
    double criticalChance = 0,
    double sizeMultiplier = 1,
  }) {
    final aliveEnemies = enemies.where((enemy) => !enemy.isDead).toList();
    if (aliveEnemies.isEmpty) {
      return const WeaponTickResult.empty();
    }

    final damageEvents = <DamageEvent>[];
    final projectiles = <ProjectileComponent>[];
    final meleeArcs = <MeleeArcComponent>[];
    final areaAttacks = <AreaAttackComponent>[];
    final firedWeaponIds = <WeaponId>[];

    final hwandoEventCount = damageEvents.length + meleeArcs.length;
    _fireHwando(
      dt: dt,
      origin: origin,
      enemies: aliveEnemies,
      damageMultiplier: damageMultiplier,
      attackSpeedMultiplier: attackSpeedMultiplier,
      criticalChance: criticalChance,
      sizeMultiplier: sizeMultiplier,
      damageEvents: damageEvents,
      meleeArcs: meleeArcs,
    );
    if (damageEvents.length + meleeArcs.length > hwandoEventCount) {
      firedWeaponIds.add(hwandoSlash);
    }
    final gakgungProjectileCount = projectiles.length;
    _fireGakgung(
      dt: dt,
      origin: origin,
      enemies: aliveEnemies,
      damageMultiplier: damageMultiplier,
      attackSpeedMultiplier: attackSpeedMultiplier,
      criticalChance: criticalChance,
      sizeMultiplier: sizeMultiplier,
      projectiles: projectiles,
    );
    if (projectiles.length > gakgungProjectileCount) {
      firedWeaponIds.add(gakgungShot);
    }
    final talismanDamageCount = damageEvents.length;
    _fireTalisman(
      dt: dt,
      origin: origin,
      enemies: aliveEnemies,
      damageMultiplier: damageMultiplier,
      attackSpeedMultiplier: attackSpeedMultiplier,
      criticalChance: criticalChance,
      sizeMultiplier: sizeMultiplier,
      damageEvents: damageEvents,
    );
    if (damageEvents.length > talismanDamageCount) {
      firedWeaponIds.add(talismanThrow);
    }
    final bombAreaCount = areaAttacks.length;
    _fireBomb(
      dt: dt,
      origin: origin,
      enemies: aliveEnemies,
      damageMultiplier: damageMultiplier,
      attackSpeedMultiplier: attackSpeedMultiplier,
      criticalChance: criticalChance,
      sizeMultiplier: sizeMultiplier,
      areaAttacks: areaAttacks,
    );
    if (areaAttacks.length > bombAreaCount) {
      firedWeaponIds.add(thunderCrashBomb);
    }

    return WeaponTickResult(
      damageEvents: damageEvents,
      projectiles: projectiles,
      meleeArcs: meleeArcs,
      areaAttacks: areaAttacks,
      firedWeaponIds: firedWeaponIds,
    );
  }

  void _fireHwando({
    required double dt,
    required Vector2 origin,
    required List<EnemyComponent> enemies,
    required double damageMultiplier,
    required double attackSpeedMultiplier,
    required double criticalChance,
    required double sizeMultiplier,
    required List<DamageEvent> damageEvents,
    required List<MeleeArcComponent> meleeArcs,
  }) {
    final level = levelOf(hwandoSlash);
    if (level == 0) return;
    final stats = weaponLevelFor(hwandoSlash, level);
    if (!_consumeCooldown(
      hwandoSlash,
      dt,
      stats.cooldownSeconds / _positiveMultiplier(attackSpeedMultiplier),
    )) {
      return;
    }

    final nearest = _nearestEnemy(origin, enemies)!;
    final baseDirection = _direction(origin, nearest.position);
    for (var index = 0; index < stats.projectileCount; index += 1) {
      final offset = stats.projectileCount == 1
          ? 0.0
          : (index == 0 ? -0.18 : 0.18);
      final direction = baseDirection.clone()..rotate(offset);
      final arc = MeleeArcComponent(
        weaponId: hwandoSlash,
        damage: stats.damage * damageMultiplier,
        knockback: stats.knockback,
        position: origin.clone(),
        direction: direction,
        range: stats.range * sizeMultiplier,
      );
      meleeArcs.add(arc);
      for (final enemy in enemies.where(arc.containsEnemy)) {
        damageEvents.add(
          _damageEvent(
            weaponId: hwandoSlash,
            target: enemy,
            origin: origin,
            damage: stats.damage * damageMultiplier,
            knockback: stats.knockback,
            criticalChance: criticalChance,
          ),
        );
      }
    }
  }

  void _fireGakgung({
    required double dt,
    required Vector2 origin,
    required List<EnemyComponent> enemies,
    required double damageMultiplier,
    required double attackSpeedMultiplier,
    required double criticalChance,
    required double sizeMultiplier,
    required List<ProjectileComponent> projectiles,
  }) {
    final level = levelOf(gakgungShot);
    if (level == 0) return;
    final stats = weaponLevelFor(gakgungShot, level);
    if (!_consumeCooldown(
      gakgungShot,
      dt,
      stats.cooldownSeconds / _positiveMultiplier(attackSpeedMultiplier),
    )) {
      return;
    }

    final nearest = _nearestEnemy(origin, enemies)!;
    final baseDirection = _direction(origin, nearest.position);
    for (var index = 0; index < stats.projectileCount; index += 1) {
      final spread = (index - (stats.projectileCount - 1) / 2) * 0.10;
      final direction = baseDirection.clone()..rotate(spread);
      projectiles.add(
        ProjectileComponent(
          weaponId: gakgungShot,
          damage: _rolledDamage(
            stats.damage * damageMultiplier,
            criticalChance,
          ),
          position: origin.clone(),
          velocity: direction * 260,
          pierce: stats.pierce,
          knockback: stats.knockback,
          size: Vector2.all(8 * sizeMultiplier),
        ),
      );
    }
  }

  void _fireTalisman({
    required double dt,
    required Vector2 origin,
    required List<EnemyComponent> enemies,
    required double damageMultiplier,
    required double attackSpeedMultiplier,
    required double criticalChance,
    required double sizeMultiplier,
    required List<DamageEvent> damageEvents,
  }) {
    final level = levelOf(talismanThrow);
    if (level == 0) return;
    final stats = weaponLevelFor(talismanThrow, level);
    if (!_consumeCooldown(
      talismanThrow,
      dt,
      stats.cooldownSeconds / _positiveMultiplier(attackSpeedMultiplier),
    )) {
      return;
    }

    final maxRangeSquared = pow(stats.range * sizeMultiplier, 2);
    final targets =
        enemies
            .where(
              (enemy) =>
                  enemy.position.distanceToSquared(origin) <= maxRangeSquared,
            )
            .toList()
          ..sort(
            (a, b) => a.position
                .distanceToSquared(origin)
                .compareTo(b.position.distanceToSquared(origin)),
          );
    for (final target in targets.take(stats.chainCount)) {
      final spiritMultiplier = target.enemyId == vengefulSpirit ? 1.25 : 1.0;
      damageEvents.add(
        _damageEvent(
          weaponId: talismanThrow,
          target: target,
          origin: origin,
          damage: stats.damage * damageMultiplier * spiritMultiplier,
          knockback: stats.knockback,
          criticalChance: criticalChance,
        ),
      );
    }
  }

  void _fireBomb({
    required double dt,
    required Vector2 origin,
    required List<EnemyComponent> enemies,
    required double damageMultiplier,
    required double attackSpeedMultiplier,
    required double criticalChance,
    required double sizeMultiplier,
    required List<AreaAttackComponent> areaAttacks,
  }) {
    final level = levelOf(thunderCrashBomb);
    if (level == 0) return;
    final stats = weaponLevelFor(thunderCrashBomb, level);
    if (!_consumeCooldown(
      thunderCrashBomb,
      dt,
      stats.cooldownSeconds / _positiveMultiplier(attackSpeedMultiplier),
    )) {
      return;
    }

    for (var index = 0; index < stats.projectileCount; index += 1) {
      final center = _bombCenter(origin, enemies);
      areaAttacks.add(
        AreaAttackComponent(
          weaponId: thunderCrashBomb,
          damage: _rolledDamage(
            stats.damage * damageMultiplier,
            criticalChance,
          ),
          radius: stats.range * sizeMultiplier,
          delaySeconds: 0.65,
          knockback: stats.knockback,
          position: center,
          direction: _direction(origin, center),
        ),
      );
    }
  }

  DamageEvent _damageEvent({
    required WeaponId weaponId,
    required EnemyComponent target,
    required Vector2 origin,
    required double damage,
    required double knockback,
    required double criticalChance,
  }) {
    final isCritical = _random.nextDouble() < criticalChance.clamp(0, 1);
    return DamageEvent(
      target: target,
      damage: damage * (isCritical ? 2 : 1),
      knockback: knockback,
      direction: _direction(origin, target.position),
      weaponId: weaponId,
      isCritical: isCritical,
    );
  }

  double _rolledDamage(double damage, double criticalChance) {
    return damage * (_random.nextDouble() < criticalChance.clamp(0, 1) ? 2 : 1);
  }

  bool _consumeCooldown(WeaponId weaponId, double dt, double interval) {
    final remaining = (_cooldowns[weaponId] ?? 0) - dt;
    if (remaining > 0) {
      _cooldowns[weaponId] = remaining;
      return false;
    }
    _cooldowns[weaponId] = interval;
    return true;
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

  Vector2 _direction(Vector2 origin, Vector2 target) {
    final direction = target - origin;
    if (direction.length2 == 0) {
      return Vector2(1, 0);
    }
    return direction..normalize();
  }

  double _positiveMultiplier(double value) => value > 0 ? value : 1;

  WeaponDefinition? _definitionFor(WeaponId weaponId) {
    for (final definition in weaponDefinitions) {
      if (definition.id == weaponId) return definition;
    }
    return null;
  }
}

class WeaponTickResult {
  const WeaponTickResult({
    this.damageEvents = const [],
    this.projectiles = const [],
    this.meleeArcs = const [],
    this.areaAttacks = const [],
    this.firedWeaponIds = const [],
  });

  const WeaponTickResult.empty()
    : damageEvents = const [],
      projectiles = const [],
      meleeArcs = const [],
      areaAttacks = const [],
      firedWeaponIds = const [];

  final List<DamageEvent> damageEvents;
  final List<ProjectileComponent> projectiles;
  final List<MeleeArcComponent> meleeArcs;
  final List<AreaAttackComponent> areaAttacks;
  final List<WeaponId> firedWeaponIds;
}
