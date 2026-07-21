import 'dart:math';

import 'package:flame/components.dart';

import '../components/area_attack_component.dart';
import '../components/enemy_component.dart';
import '../components/frost_field_component.dart';
import '../components/melee_arc_component.dart';
import '../components/projectile_component.dart';
import '../combat/attack_spec.dart';
import '../content/enemy_definitions.dart';
import '../content/ids.dart';
import '../content/weapon_definitions.dart';
import '../content/weapon_level_definitions.dart';
import '../models/damage_event.dart';
import 'hwando_aim_resolver.dart';
import 'hwando_executor.dart';

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
  final HwandoExecutor _hwandoExecutor = HwandoExecutor();

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
    Map<ElementType, double> elementDamageMultipliers = const {},
    Vector2? hwandoFallbackDirection,
  }) {
    final aliveEnemies = enemies
        .where((enemy) => !enemy.isDead && !enemy.isRemoving)
        .toList();
    final damageEvents = <DamageEvent>[];
    final projectiles = <ProjectileComponent>[];
    final meleeArcs = <MeleeArcComponent>[];
    final areaAttacks = <AreaAttackComponent>[];
    final frostFields = <FrostFieldComponent>[];
    final firedWeaponIds = <WeaponId>[];
    final attackInstances = <AttackInstance>[];

    final hwandoEventCount = damageEvents.length + meleeArcs.length;
    final hwandoDirection = _fireHwando(
      dt: dt,
      origin: origin,
      enemies: aliveEnemies,
      fallbackDirection: hwandoFallbackDirection ?? Vector2(1, 0),
      damageMultiplier:
          damageMultiplier *
          _elementDamageMultiplier(hwandoSlash, elementDamageMultipliers),
      attackSpeedMultiplier: attackSpeedMultiplier,
      criticalChance: criticalChance,
      sizeMultiplier: sizeMultiplier,
      damageEvents: damageEvents,
      meleeArcs: meleeArcs,
      attackInstances: attackInstances,
    );
    if (damageEvents.length + meleeArcs.length > hwandoEventCount) {
      firedWeaponIds.add(hwandoSlash);
    }
    if (aliveEnemies.isEmpty) {
      return WeaponTickResult(
        damageEvents: damageEvents,
        meleeArcs: meleeArcs,
        attackInstances: attackInstances,
        firedWeaponIds: firedWeaponIds,
        hwandoDirection: hwandoDirection,
      );
    }
    final gakgungProjectileCount = projectiles.length;
    _fireGakgung(
      dt: dt,
      origin: origin,
      enemies: aliveEnemies,
      damageMultiplier:
          damageMultiplier *
          _elementDamageMultiplier(gakgungShot, elementDamageMultipliers),
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
      damageMultiplier:
          damageMultiplier *
          _elementDamageMultiplier(talismanThrow, elementDamageMultipliers),
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
      damageMultiplier:
          damageMultiplier *
          _elementDamageMultiplier(thunderCrashBomb, elementDamageMultipliers),
      attackSpeedMultiplier: attackSpeedMultiplier,
      criticalChance: criticalChance,
      sizeMultiplier: sizeMultiplier,
      areaAttacks: areaAttacks,
    );
    if (areaAttacks.length > bombAreaCount) {
      firedWeaponIds.add(thunderCrashBomb);
    }
    final wardDamageCount = damageEvents.length;
    _fireWard(
      dt: dt,
      origin: origin,
      enemies: aliveEnemies,
      damageMultiplier:
          damageMultiplier *
          _elementDamageMultiplier(jangseungWard, elementDamageMultipliers),
      attackSpeedMultiplier: attackSpeedMultiplier,
      criticalChance: criticalChance,
      sizeMultiplier: sizeMultiplier,
      damageEvents: damageEvents,
    );
    if (damageEvents.length > wardDamageCount) {
      firedWeaponIds.add(jangseungWard);
    }

    final singijeonCount = projectiles.length;
    _fireSingijeon(
      dt: dt,
      origin: origin,
      enemies: aliveEnemies,
      damageMultiplier:
          damageMultiplier *
          _elementDamageMultiplier(singijeonVolley, elementDamageMultipliers),
      attackSpeedMultiplier: attackSpeedMultiplier,
      criticalChance: criticalChance,
      sizeMultiplier: sizeMultiplier,
      projectiles: projectiles,
    );
    if (projectiles.length > singijeonCount) {
      firedWeaponIds.add(singijeonVolley);
    }

    final frostCount = frostFields.length;
    _fireFrost(
      dt: dt,
      origin: origin,
      enemies: aliveEnemies,
      damageMultiplier:
          damageMultiplier *
          _elementDamageMultiplier(frostFlask, elementDamageMultipliers),
      attackSpeedMultiplier: attackSpeedMultiplier,
      criticalChance: criticalChance,
      sizeMultiplier: sizeMultiplier,
      frostFields: frostFields,
    );
    if (frostFields.length > frostCount) firedWeaponIds.add(frostFlask);

    final fanArcCount = meleeArcs.length;
    _fireFan(
      dt: dt,
      origin: origin,
      enemies: aliveEnemies,
      damageMultiplier:
          damageMultiplier *
          _elementDamageMultiplier(windThunderFan, elementDamageMultipliers),
      attackSpeedMultiplier: attackSpeedMultiplier,
      criticalChance: criticalChance,
      sizeMultiplier: sizeMultiplier,
      damageEvents: damageEvents,
      meleeArcs: meleeArcs,
    );
    if (meleeArcs.length > fanArcCount) firedWeaponIds.add(windThunderFan);

    return WeaponTickResult(
      damageEvents: damageEvents,
      projectiles: projectiles,
      meleeArcs: meleeArcs,
      areaAttacks: areaAttacks,
      frostFields: frostFields,
      firedWeaponIds: firedWeaponIds,
      attackInstances: attackInstances,
      hwandoDirection: hwandoDirection,
    );
  }

  Vector2? _fireHwando({
    required double dt,
    required Vector2 origin,
    required List<EnemyComponent> enemies,
    required Vector2 fallbackDirection,
    required double damageMultiplier,
    required double attackSpeedMultiplier,
    required double criticalChance,
    required double sizeMultiplier,
    required List<DamageEvent> damageEvents,
    required List<MeleeArcComponent> meleeArcs,
    required List<AttackInstance> attackInstances,
  }) {
    final level = levelOf(hwandoSlash);
    if (level == 0) return null;
    final stats = weaponLevelFor(hwandoSlash, level);
    final baseDirection = HwandoAimResolver.resolve(
      origin: origin,
      enemies: enemies,
      maxRange: stats.range * sizeMultiplier,
      fallbackDirection: fallbackDirection,
    ).direction;
    final emitted = _hwandoExecutor.tick(
      HwandoTickInput(
        dt: dt * _positiveMultiplier(attackSpeedMultiplier),
        level: level,
        origin: origin,
        aimDirection: baseDirection,
        damageMultiplier: damageMultiplier,
        sizeMultiplier: sizeMultiplier,
      ),
    );
    attackInstances.addAll(emitted);
    for (final attack in emitted) {
      final range = attack.spec.shape == AttackShape.circle
          ? attack.spec.radius
          : attack.spec.range;
      final arc = MeleeArcComponent(
        weaponId: hwandoSlash,
        damage: attack.spec.damage,
        knockback: attack.spec.knockback,
        position: attack.origin,
        direction: attack.direction,
        range: range,
        angleRadians: attack.spec.shape == AttackShape.circle
            ? pi * 2
            : attack.spec.angleRadians == 0
            ? pi / 2
            : attack.spec.angleRadians,
      );
      meleeArcs.add(arc);
      for (final enemy in enemies.where(arc.containsEnemy)) {
        damageEvents.add(
          _damageEvent(
            weaponId: hwandoSlash,
            target: enemy,
            origin: attack.origin,
            damage: attack.spec.damage,
            knockback: attack.spec.knockback,
            criticalChance: criticalChance,
          ),
        );
      }
    }
    return emitted.isEmpty ? null : emitted.first.direction;
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

  void _fireWard({
    required double dt,
    required Vector2 origin,
    required List<EnemyComponent> enemies,
    required double damageMultiplier,
    required double attackSpeedMultiplier,
    required double criticalChance,
    required double sizeMultiplier,
    required List<DamageEvent> damageEvents,
  }) {
    final level = levelOf(jangseungWard);
    if (level == 0) return;
    final stats = weaponLevelFor(jangseungWard, level);
    if (!_consumeCooldown(
      jangseungWard,
      dt,
      stats.cooldownSeconds / _positiveMultiplier(attackSpeedMultiplier),
    )) {
      return;
    }
    final rangeSquared = pow(stats.range * sizeMultiplier, 2);
    for (final enemy in enemies) {
      if (enemy.position.distanceToSquared(origin) > rangeSquared) continue;
      damageEvents.add(
        _damageEvent(
          weaponId: jangseungWard,
          target: enemy,
          origin: origin,
          damage: stats.damage * damageMultiplier,
          knockback: stats.knockback,
          criticalChance: criticalChance,
        ),
      );
    }
  }

  void _fireSingijeon({
    required double dt,
    required Vector2 origin,
    required List<EnemyComponent> enemies,
    required double damageMultiplier,
    required double attackSpeedMultiplier,
    required double criticalChance,
    required double sizeMultiplier,
    required List<ProjectileComponent> projectiles,
  }) {
    final level = levelOf(singijeonVolley);
    if (level == 0) return;
    final stats = weaponLevelFor(singijeonVolley, level);
    if (!_consumeCooldown(
      singijeonVolley,
      dt,
      stats.cooldownSeconds / _positiveMultiplier(attackSpeedMultiplier),
    )) {
      return;
    }
    final baseDirection = _densestDirection(origin, enemies);
    for (var index = 0; index < stats.projectileCount; index += 1) {
      final spread = (index - (stats.projectileCount - 1) / 2) * .11;
      final direction = baseDirection.clone()..rotate(spread);
      projectiles.add(
        ProjectileComponent(
          weaponId: singijeonVolley,
          damage: _rolledDamage(
            stats.damage * damageMultiplier,
            criticalChance,
          ),
          position: origin.clone(),
          velocity: direction * 300,
          pierce: stats.pierce,
          knockback: stats.knockback,
          size: Vector2.all(7 * sizeMultiplier),
        ),
      );
    }
  }

  void _fireFrost({
    required double dt,
    required Vector2 origin,
    required List<EnemyComponent> enemies,
    required double damageMultiplier,
    required double attackSpeedMultiplier,
    required double criticalChance,
    required double sizeMultiplier,
    required List<FrostFieldComponent> frostFields,
  }) {
    final level = levelOf(frostFlask);
    if (level == 0) return;
    final stats = weaponLevelFor(frostFlask, level);
    if (!_consumeCooldown(
      frostFlask,
      dt,
      stats.cooldownSeconds / _positiveMultiplier(attackSpeedMultiplier),
    )) {
      return;
    }
    final center = _densestCenter(enemies, stats.range * sizeMultiplier);
    frostFields.add(
      FrostFieldComponent(
        weaponId: frostFlask,
        damage: _rolledDamage(stats.damage * damageMultiplier, criticalChance),
        radius: stats.range * sizeMultiplier,
        durationSeconds: stats.durationSeconds,
        slowFraction: stats.slowFraction,
        knockback: stats.knockback,
        position: center,
      ),
    );
  }

  void _fireFan({
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
    final level = levelOf(windThunderFan);
    if (level == 0) return;
    final stats = weaponLevelFor(windThunderFan, level);
    if (!_consumeCooldown(
      windThunderFan,
      dt,
      stats.cooldownSeconds / _positiveMultiplier(attackSpeedMultiplier),
    )) {
      return;
    }
    final baseDirection = _direction(
      origin,
      _nearestEnemy(origin, enemies)!.position,
    );
    for (var index = 0; index < stats.projectileCount; index += 1) {
      final direction = baseDirection.clone();
      if (index.isOdd) direction.negate();
      final arc = MeleeArcComponent(
        weaponId: windThunderFan,
        damage: stats.damage * damageMultiplier,
        knockback: stats.knockback,
        position: origin.clone(),
        direction: direction,
        range: stats.range * sizeMultiplier,
        angleRadians: pi * .75,
      );
      meleeArcs.add(arc);
      for (final enemy in enemies.where(arc.containsEnemy)) {
        damageEvents.add(
          _damageEvent(
            weaponId: windThunderFan,
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

  Vector2 _densestDirection(Vector2 origin, List<EnemyComponent> enemies) {
    var best = _direction(origin, enemies.first.position);
    var bestScore = -1;
    final minimumDot = cos(pi / 6);
    for (final candidate in enemies) {
      final direction = _direction(origin, candidate.position);
      var score = 0;
      for (final enemy in enemies) {
        if (direction.dot(_direction(origin, enemy.position)) >= minimumDot) {
          score += 1;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        best = direction;
      }
    }
    return best;
  }

  Vector2 _densestCenter(List<EnemyComponent> enemies, double radius) {
    var best = enemies.first;
    var bestScore = -1;
    final radiusSquared = radius * radius;
    for (final candidate in enemies) {
      final score = enemies
          .where(
            (enemy) =>
                enemy.position.distanceToSquared(candidate.position) <=
                radiusSquared,
          )
          .length;
      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }
    return best.position.clone();
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

  double _elementDamageMultiplier(
    WeaponId weaponId,
    Map<ElementType, double> multipliers,
  ) {
    final definition = _definitionFor(weaponId);
    if (definition == null) return 1;
    final multiplier = multipliers[definition.element] ?? 1;
    return multiplier.isFinite && multiplier >= 0 ? multiplier : 1;
  }

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
    this.frostFields = const [],
    this.firedWeaponIds = const [],
    this.attackInstances = const [],
    this.hwandoDirection,
  });

  const WeaponTickResult.empty()
    : damageEvents = const [],
      projectiles = const [],
      meleeArcs = const [],
      areaAttacks = const [],
      frostFields = const [],
      firedWeaponIds = const [],
      attackInstances = const [],
      hwandoDirection = null;

  final List<DamageEvent> damageEvents;
  final List<ProjectileComponent> projectiles;
  final List<MeleeArcComponent> meleeArcs;
  final List<AreaAttackComponent> areaAttacks;
  final List<FrostFieldComponent> frostFields;
  final List<WeaponId> firedWeaponIds;
  final List<AttackInstance> attackInstances;
  final Vector2? hwandoDirection;
}
