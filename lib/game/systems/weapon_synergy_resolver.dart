import 'dart:collection';

import 'package:flame/components.dart';

import '../combat/attack_spec.dart';
import '../components/enemy_component.dart';

const sealingSlash = 'sealing_slash';

class SynergyResolution {
  const SynergyResolution({
    this.attack,
    this.markedTargets = const [],
    this.showFirstActivationNotice = false,
  });

  final AttackInstance? attack;
  final List<EnemyComponent> markedTargets;
  final bool showFirstActivationNotice;
}

class WeaponSynergyResolver {
  static const maxTransferredMarks = 3;
  static const transferRadius = 96.0;
  static const _detonationRadius = 64.0;
  static const _detonationDamage = 18.0;
  static const _rememberedAttacks = 64;

  final Map<EnemyComponent, _SealingMark> _marks = {};
  final LinkedHashMap<int, Set<EnemyComponent>> _detonatedTargetsByAttack =
      LinkedHashMap();
  bool _showedFirstActivationNotice = false;

  List<EnemyComponent> get markedTargets =>
      List<EnemyComponent>.unmodifiable(_marks.keys);

  SynergyResolution onHwandoHit({
    required EnemyComponent target,
    required Iterable<EnemyComponent> nearby,
    required double now,
    required int originatingAttackId,
  }) {
    final liveNearby = nearby
        .where((enemy) => !enemy.isDead && !enemy.isRemoving)
        .toSet();
    _marks.removeWhere(
      (enemy, _) =>
          enemy.isDead || enemy.isRemoving || !liveNearby.contains(enemy),
    );
    if (!liveNearby.contains(target)) return const SynergyResolution();

    final detonatedForAttack = _detonatedTargetsByAttack.putIfAbsent(
      originatingAttackId,
      () => <EnemyComponent>{},
    );
    _trimAttackHistory();
    if (detonatedForAttack.contains(target)) {
      return const SynergyResolution();
    }

    final mark = _marks[target];
    if (mark == null) {
      _marks[target] = _SealingMark(
        markedAtSeconds: now,
        originatingAttackId: originatingAttackId,
      );
      return SynergyResolution(markedTargets: [target]);
    }
    if (mark.originatingAttackId == originatingAttackId) {
      return const SynergyResolution();
    }

    _marks.remove(target);
    detonatedForAttack.add(target);
    final transferred =
        liveNearby
            .where(
              (enemy) =>
                  !identical(enemy, target) && !_marks.containsKey(enemy),
            )
            .where(
              (enemy) =>
                  enemy.position.distanceToSquared(target.position) <=
                  transferRadius * transferRadius,
            )
            .toList(growable: false)
          ..sort(
            (a, b) => a.position
                .distanceToSquared(target.position)
                .compareTo(b.position.distanceToSquared(target.position)),
          );
    final markedTargets = transferred
        .take(maxTransferredMarks)
        .toList(growable: false);
    for (final enemy in markedTargets) {
      _marks[enemy] = _SealingMark(
        markedAtSeconds: now,
        originatingAttackId: originatingAttackId,
      );
    }

    final showNotice = !_showedFirstActivationNotice;
    _showedFirstActivationNotice = true;
    return SynergyResolution(
      attack: AttackInstance(
        spec: AttackSpec(
          id: sealingSlash,
          shape: AttackShape.circle,
          damage: _detonationDamage,
          range: 0,
          angleRadians: 0,
          radius: _detonationRadius,
          width: 0,
          windupSeconds: 0,
          activeSeconds: .08,
          lingerSeconds: .22,
          knockback: 18,
          slowFraction: 0,
          traits: const {AttackTrait.explosion, AttackTrait.synergy},
          presentation: AttackPresentation.synergy,
        ),
        origin: target.position,
        direction: Vector2(1, 0),
        sequenceIndex: originatingAttackId,
      ),
      markedTargets: List<EnemyComponent>.unmodifiable(markedTargets),
      showFirstActivationNotice: showNotice,
    );
  }

  void _trimAttackHistory() {
    while (_detonatedTargetsByAttack.length > _rememberedAttacks) {
      _detonatedTargetsByAttack.remove(_detonatedTargetsByAttack.keys.first);
    }
  }
}

class _SealingMark {
  const _SealingMark({
    required this.markedAtSeconds,
    required this.originatingAttackId,
  });

  final double markedAtSeconds;
  final int originatingAttackId;
}
