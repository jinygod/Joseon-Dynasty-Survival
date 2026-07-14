enum BossPhase { approach, charge, coneSlash, summon, enraged, defeated }

enum BossActionType { chargeWarning, charge, coneWarning, coneDamage, summon }

class BossAction {
  const BossAction({required this.type});

  final BossActionType type;
}

class BossController {
  static const _enrageSeconds = 60.0;
  static const _enrageMultiplier = 1.35;

  BossPhase _patternPhase = BossPhase.approach;
  double _encounterSeconds = 0;
  double _phaseSeconds = 0;
  bool _coneWarningEmitted = false;
  bool _hasSummoned = false;
  bool _summonedThisTick = false;
  bool _isDefeated = false;

  bool get isEnraged => _encounterSeconds >= _enrageSeconds;
  double get movementMultiplier => isEnraged ? _enrageMultiplier : 1;
  double get patternTimeMultiplier => isEnraged ? _enrageMultiplier : 1;
  BossPhase get phase {
    if (_isDefeated) return BossPhase.defeated;
    if (_summonedThisTick) return BossPhase.summon;
    if (isEnraged) return BossPhase.enraged;
    return _patternPhase;
  }

  List<BossAction> tick({required double dt, required double healthFraction}) {
    _summonedThisTick = false;
    if (_isDefeated || healthFraction <= 0) {
      _isDefeated = true;
      return const [];
    }

    final safeDt = dt < 0 ? 0.0 : dt;
    _encounterSeconds += safeDt;
    _phaseSeconds += safeDt * patternTimeMultiplier;
    final actions = <BossAction>[];

    if (!_hasSummoned && healthFraction <= 0.4) {
      _hasSummoned = true;
      _summonedThisTick = true;
      actions.add(const BossAction(type: BossActionType.summon));
    }

    switch (_patternPhase) {
      case BossPhase.approach:
        if (_phaseSeconds >= 1.0) {
          actions.add(const BossAction(type: BossActionType.chargeWarning));
          _patternPhase = BossPhase.charge;
          _phaseSeconds = 0;
        }
      case BossPhase.charge:
        if (_phaseSeconds >= 0.5) {
          actions.add(const BossAction(type: BossActionType.charge));
          _patternPhase = BossPhase.coneSlash;
          _phaseSeconds = 0;
          _coneWarningEmitted = false;
        }
      case BossPhase.coneSlash:
        if (!_coneWarningEmitted && _phaseSeconds >= 0.65) {
          _coneWarningEmitted = true;
          actions.add(const BossAction(type: BossActionType.coneWarning));
        }
        if (_phaseSeconds >= 1.25) {
          actions.add(const BossAction(type: BossActionType.coneDamage));
          _patternPhase = BossPhase.approach;
          _phaseSeconds = 0;
          _coneWarningEmitted = false;
        }
      case BossPhase.summon:
      case BossPhase.enraged:
      case BossPhase.defeated:
        break;
    }

    return actions;
  }
}
