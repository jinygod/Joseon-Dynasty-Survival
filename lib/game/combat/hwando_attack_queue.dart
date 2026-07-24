import 'package:flutter/foundation.dart';

import 'attack_presentation_contract.dart';
import 'attack_spec.dart';
import 'attack_timeline.dart';

@immutable
class HwandoStrikeActivation {
  const HwandoStrikeActivation({required this.attack, required this.contract});

  final AttackInstance attack;
  final AttackPresentationContract contract;
}

class HwandoAttackQueue {
  final List<_PendingHwandoAttack> _pending = [];

  int get pendingCount => _pending.length;

  void enqueue(AttackInstance attack) {
    final contract = AttackPresentationContract.fromAttack(attack);
    _pending.add(
      _PendingHwandoAttack(
        attack: attack,
        contract: contract,
        cursor: AttackTimelineCursor(contract.timing),
      ),
    );
  }

  List<HwandoStrikeActivation> advance(double dt) {
    final activations = <HwandoStrikeActivation>[];
    for (final pending in _pending) {
      final result = pending.cursor.advance(dt);
      if (result.enteredActive) {
        activations.add(
          HwandoStrikeActivation(
            attack: pending.attack,
            contract: pending.contract,
          ),
        );
      }
    }
    _pending.removeWhere(
      (pending) => pending.cursor.phase == AttackPhase.complete,
    );
    return List.unmodifiable(activations);
  }

  void clear() => _pending.clear();
}

class _PendingHwandoAttack {
  const _PendingHwandoAttack({
    required this.attack,
    required this.contract,
    required this.cursor,
  });

  final AttackInstance attack;
  final AttackPresentationContract contract;
  final AttackTimelineCursor cursor;
}
