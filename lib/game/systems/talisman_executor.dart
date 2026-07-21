import 'dart:math';

import 'package:flame/components.dart';

import '../combat/attack_spec.dart';
import '../components/enemy_component.dart';
import '../content/enemy_definitions.dart';
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
  });

  final double dt;
  final int level;
  final double now;
  final Vector2 origin;
  final Iterable<EnemyComponent> enemies;
  final double damageMultiplier;
  final double sizeMultiplier;
  final double attackSpeedMultiplier;
}

class AttachedTalisman {
  const AttachedTalisman({
    required this.target,
    required this.attachedAtSeconds,
    required this.explodeAtSeconds,
    required this.transferDepth,
  });

  final EnemyComponent target;
  final double attachedAtSeconds;
  final double explodeAtSeconds;
  final int transferDepth;
}

class WardSpawnRequest {
  WardSpawnRequest({
    required Vector2 position,
    required this.attack,
    required this.durationSeconds,
    required this.tickSeconds,
    required this.slowFraction,
    required this.presentation,
  }) : _position = position.clone();

  final Vector2 _position;
  final AttackInstance attack;
  final double durationSeconds;
  final double tickSeconds;
  final double slowFraction;
  final AttackPresentation presentation;

  Vector2 get position => _position.clone();
  double get radius => attack.spec.radius;
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
  static const maxAttachedSeals = 24;
  static const maxTransferDepth = 2;
  static const maxMasterWards = 3;
  static const _attachmentDelaySeconds = .6;

  final Map<EnemyComponent, AttachedTalisman> _attached = {};
  double _cooldown = 0;

  List<AttachedTalisman> get attached => List.unmodifiable(_attached.values);

  TalismanTickResult tick(TalismanTickInput input) {
    final removedTargetIds = <String>[];
    _attached.removeWhere((enemy, seal) {
      final remove = enemy.isDead || enemy.isRemoving;
      if (remove) removedTargetIds.add(enemy.enemyId);
      return remove;
    });

    final enemies = input.enemies
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
      attacks.add(_explosionFor(entry.key.position, input, target: entry.key));
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
        attacks.add(_explosionFor(target.position, input, target: target));
      } else {
        _attach(target, input.now, 0);
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
    if (candidates.isNotEmpty) _attach(candidates.first, input.now, depth);
  }

  void _attach(EnemyComponent target, double now, int transferDepth) {
    if (_attached.length >= maxAttachedSeals || _attached.containsKey(target)) {
      return;
    }
    _attached[target] = AttachedTalisman(
      target: target,
      attachedAtSeconds: now,
      explodeAtSeconds: now + _attachmentDelaySeconds,
      transferDepth: transferDepth,
    );
  }

  AttackInstance _explosionFor(
    Vector2 center,
    TalismanTickInput input, {
    EnemyComponent? target,
  }) {
    final stats = weaponLevelFor(talismanThrow, input.level);
    final master = input.level == 6;
    return AttackInstance(
      spec: AttackSpec(
        id: master ? 'talisman_master_explosion' : 'talisman_explosion',
        shape: AttackShape.circle,
        damage:
            stats.damage *
            input.damageMultiplier *
            (target?.enemyId == vengefulSpirit ? 1.25 : 1),
        range: 0,
        angleRadians: 0,
        radius: (28 + input.level * 3) * input.sizeMultiplier,
        width: 0,
        windupSeconds: 0,
        activeSeconds: .08,
        lingerSeconds: .14,
        knockback: stats.knockback,
        slowFraction: 0,
        traits: {AttackTrait.explosion, if (master) AttackTrait.master},
        presentation: master
            ? AttackPresentation.master
            : AttackPresentation.strong,
      ),
      origin: center,
      direction: Vector2(1, 0),
      sequenceIndex: 0,
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
    );
    return WardSpawnRequest(
      position: center,
      attack: attack,
      durationSeconds: duration,
      tickSeconds: .5,
      slowFraction: slow,
      presentation: presentation,
    );
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
}
