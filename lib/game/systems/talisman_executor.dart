import 'dart:math';

import 'package:flame/components.dart';

import '../combat/attack_spec.dart';
import '../components/enemy_component.dart';
import '../content/weapon_definitions.dart';
import '../content/weapon_level_definitions.dart';

class TalismanTickInput {
  const TalismanTickInput({
    required this.dt,
    required this.level,
    required this.now,
    required this.origin,
    required this.enemies,
    required this.damageMultiplier,
    required this.sizeMultiplier,
    this.attackSpeedMultiplier = 1,
    this.criticalChance = 0,
  });

  final double dt;
  final int level;
  final double now;
  final Vector2 origin;
  final Iterable<EnemyComponent> enemies;
  final double damageMultiplier;
  final double sizeMultiplier;
  final double attackSpeedMultiplier;
  final double criticalChance;
}

class AttachedTalisman {
  const AttachedTalisman({
    required this.target,
    required this.attachedAtSeconds,
    required this.explodeAtSeconds,
    required this.transferDepth,
    required this.isCritical,
  });

  final EnemyComponent target;
  final double attachedAtSeconds;
  final double explodeAtSeconds;
  final int transferDepth;
  final bool isCritical;
}

class WardSpawnRequest {
  WardSpawnRequest({required this.attack, required this.tickSeconds});

  final AttackInstance attack;
  final double tickSeconds;

  Vector2 get position => attack.origin;
  double get radius => attack.spec.radius;
  double get durationSeconds => attack.spec.lingerSeconds;
  double get slowFraction => attack.spec.slowFraction;
  AttackPresentation get presentation => attack.spec.presentation;
}

class TalismanTickResult {
  const TalismanTickResult({
    this.attached = const [],
    this.attacks = const [],
    this.wards = const [],
    this.removedTargetIds = const [],
  });

  final List<AttachedTalisman> attached;
  final List<AttackInstance> attacks;
  final List<WardSpawnRequest> wards;
  final List<String> removedTargetIds;
}

class TalismanExecutor {
  TalismanExecutor({Random? random}) : _random = random ?? Random();

  static const maxAttachedSeals = 24;
  static const maxTransferDepth = 2;
  static const maxMasterWards = 3;
  static const _attachmentDelaySeconds = .6;

  final Map<EnemyComponent, AttachedTalisman> _attached = {};
  final Random _random;
  double _cooldown = 0;

  List<AttachedTalisman> get attached => List.unmodifiable(_attached.values);

  TalismanTickResult tick(TalismanTickInput input) {
    final removedTargetIds = <String>[];
    final inputEnemies = input.enemies.toSet();
    _attached.removeWhere((enemy, seal) {
      final remove =
          enemy.isDead || enemy.isRemoving || !inputEnemies.contains(enemy);
      if (remove) removedTargetIds.add(enemy.enemyId);
      return remove;
    });

    final enemies = inputEnemies
        .where((enemy) => !enemy.isDead && !enemy.isRemoving)
        .toList(growable: false);
    final attacks = <AttackInstance>[];
    final wards = <WardSpawnRequest>[];
    final expired = _attached.entries
        .where((entry) => entry.value.explodeAtSeconds <= input.now)
        .toList(growable: false);
    for (final entry in expired) {
      _attached.remove(entry.key);
      removedTargetIds.add(entry.key.enemyId);
      attacks.add(
        _explosionFor(
          entry.key.position,
          input,
          isCritical: entry.value.isCritical,
        ),
      );
      if (input.level >= 5) {
        wards.add(_wardFor(entry.key.position, input, master: false));
      }
      if (input.level >= 4 && entry.value.transferDepth < maxTransferDepth) {
        _transferFrom(entry.key, entry.value.transferDepth + 1, input, enemies);
      }
    }

    _cooldown = max(0, _cooldown - max(0, input.dt));
    final canFire = input.level > 0 && _cooldown <= 0 && enemies.isNotEmpty;
    if (canFire) {
      final stats = weaponLevelFor(talismanThrow, input.level);
      _cooldown =
          stats.cooldownSeconds / _positive(input.attackSpeedMultiplier);
      _attachOrStrikeNearest(input, enemies, attacks);
    }
    if (input.level == 6 && canFire) {
      wards.addAll(
        _masterWardCenters(enemies)
            .take(maxMasterWards)
            .map((center) => _wardFor(center, input, master: true)),
      );
    }

    return TalismanTickResult(
      attached: List.unmodifiable(_attached.values),
      attacks: List.unmodifiable(attacks),
      wards: List.unmodifiable(wards),
      removedTargetIds: List.unmodifiable(removedTargetIds),
    );
  }

  void _attachOrStrikeNearest(
    TalismanTickInput input,
    List<EnemyComponent> enemies,
    List<AttackInstance> attacks,
  ) {
    final stats = weaponLevelFor(talismanThrow, input.level);
    final maxRangeSquared = pow(stats.range * input.sizeMultiplier, 2);
    final candidates =
        enemies
            .where(
              (enemy) =>
                  !_attached.containsKey(enemy) &&
                  enemy.position.distanceToSquared(input.origin) <=
                      maxRangeSquared,
            )
            .toList()
          ..sort(
            (a, b) => a.position
                .distanceToSquared(input.origin)
                .compareTo(b.position.distanceToSquared(input.origin)),
          );
    final count = stats.chainCount;
    for (final target in candidates.take(count)) {
      if (input.level < 3) {
        attacks.add(
          _explosionFor(
            target.position,
            input,
            isCritical: _rollCritical(input.criticalChance),
          ),
        );
      } else {
        _attach(target, input.now, 0, input.criticalChance);
      }
    }
  }

  void _transferFrom(
    EnemyComponent source,
    int depth,
    TalismanTickInput input,
    List<EnemyComponent> enemies,
  ) {
    if (_attached.length >= maxAttachedSeals) return;
    final stats = weaponLevelFor(talismanThrow, input.level);
    final maxRangeSquared = pow(stats.range * input.sizeMultiplier, 2);
    final candidates =
        enemies
            .where(
              (enemy) =>
                  !identical(enemy, source) &&
                  !_attached.containsKey(enemy) &&
                  enemy.position.distanceToSquared(source.position) <=
                      maxRangeSquared,
            )
            .toList()
          ..sort(
            (a, b) => a.position
                .distanceToSquared(source.position)
                .compareTo(b.position.distanceToSquared(source.position)),
          );
    if (candidates.isNotEmpty) {
      _attach(candidates.first, input.now, depth, input.criticalChance);
    }
  }

  void _attach(
    EnemyComponent target,
    double now,
    int transferDepth,
    double criticalChance,
  ) {
    if (_attached.length >= maxAttachedSeals || _attached.containsKey(target)) {
      return;
    }
    _attached[target] = AttachedTalisman(
      target: target,
      attachedAtSeconds: now,
      explodeAtSeconds: now + _attachmentDelaySeconds,
      transferDepth: transferDepth,
      isCritical: _rollCritical(criticalChance),
    );
  }

  AttackInstance _explosionFor(
    Vector2 center,
    TalismanTickInput input, {
    required bool isCritical,
  }) {
    final stats = weaponLevelFor(talismanThrow, input.level);
    return AttackInstance(
      spec: AttackSpec(
        id: 'talisman_explosion',
        shape: AttackShape.circle,
        damage: stats.damage * input.damageMultiplier,
        range: 0,
        angleRadians: 0,
        radius: (28 + input.level * 3) * input.sizeMultiplier,
        width: 0,
        windupSeconds: 0,
        activeSeconds: .08,
        lingerSeconds: .14,
        knockback: stats.knockback,
        slowFraction: 0,
        traits: const {AttackTrait.explosion},
        presentation: AttackPresentation.strong,
      ),
      origin: center,
      direction: Vector2(1, 0),
      sequenceIndex: 0,
      isCritical: isCritical,
    );
  }

  WardSpawnRequest _wardFor(
    Vector2 center,
    TalismanTickInput input, {
    required bool master,
  }) {
    final stats = weaponLevelFor(talismanThrow, input.level);
    final radius = (master ? 72.0 : 38.0) * input.sizeMultiplier;
    final duration = master ? stats.durationSeconds : 2.0;
    final slow = master ? stats.slowFraction : .18;
    final presentation = master
        ? AttackPresentation.master
        : AttackPresentation.strong;
    final attack = AttackInstance(
      spec: AttackSpec(
        id: master ? 'talisman_master_ward' : 'talisman_small_ward',
        shape: AttackShape.circle,
        damage: stats.damage * input.damageMultiplier * (master ? .55 : .35),
        range: 0,
        angleRadians: 0,
        radius: radius,
        width: 0,
        windupSeconds: 0,
        activeSeconds: .1,
        lingerSeconds: duration,
        knockback: master ? stats.knockback * .25 : 0,
        slowFraction: slow,
        traits: {AttackTrait.explosion, if (master) AttackTrait.master},
        presentation: presentation,
      ),
      origin: center,
      direction: Vector2(1, 0),
      sequenceIndex: 0,
      isCritical: _rollCritical(input.criticalChance),
    );
    return WardSpawnRequest(attack: attack, tickSeconds: .5);
  }

  List<Vector2> _masterWardCenters(List<EnemyComponent> enemies) {
    const clusterRadiusSquared = 72.0 * 72.0;
    final remaining = List<EnemyComponent>.of(enemies);
    final centers = <Vector2>[];
    while (remaining.isNotEmpty && centers.length < maxMasterWards) {
      EnemyComponent? densest;
      var density = -1;
      for (final candidate in remaining) {
        final count = remaining
            .where(
              (enemy) =>
                  enemy.position.distanceToSquared(candidate.position) <=
                  clusterRadiusSquared,
            )
            .length;
        if (count > density) {
          density = count;
          densest = candidate;
        }
      }
      final neighbors = remaining
          .where(
            (enemy) =>
                enemy.position.distanceToSquared(densest!.position) <=
                clusterRadiusSquared,
          )
          .toList(growable: false);
      final center = Vector2.zero();
      for (final enemy in neighbors) {
        center.add(enemy.position);
      }
      center.scale(1 / neighbors.length);
      centers.add(center);
      remaining.removeWhere(neighbors.contains);
    }
    return centers;
  }

  double _positive(double value) => value.isFinite && value > 0 ? value : 1;

  bool _rollCritical(double chance) =>
      _random.nextDouble() < chance.clamp(0, 1);
}
