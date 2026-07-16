import 'dart:math' as math;

import '../content/boss_definitions.dart';

enum BossPhase {
  approach,
  charge,
  coneSlash,
  summon,
  warning,
  attack,
  recovery,
  enraged,
  defeated,
}

enum BossActionType {
  chargeWarning,
  charge,
  coneWarning,
  coneDamage,
  summon,
  warning,
  execute,
}

class BossAction {
  const BossAction({required this.type, this.pattern});

  final BossActionType type;
  final BossPatternDefinition? pattern;
}

class BossController {
  BossController({BossDefinition? definition, bool? legacyActions})
    : definition = definition ?? fallenGeneralBossDefinition,
      _legacyActions = legacyActions ?? definition == null;

  static const enrageSeconds = 25.0;
  static const chargeWarningSeconds = 0.75;
  static const coneWarningSeconds = 0.60;
  static const normalPatternCycleSeconds = 3.0;
  static const maxAcceptedDt = 30.0;
  static const maxSubsteps = 10;
  static const maxComponentDt = 0.10;
  static const _substepSeconds = 0.10;
  static const _approachSeconds = 0.50;

  final BossDefinition definition;
  final bool _legacyActions;

  BossPhase _internalPhase = BossPhase.approach;
  double _encounterSeconds = 0;
  double _phaseSeconds = 0;
  int _patternIndex = 0;
  BossPatternDefinition? _currentPattern;
  bool _summonConsumed = false;
  bool _isDefeated = false;
  double _lastAcceptedDt = 0;
  int _lastSubstepCount = 0;

  bool get isEnraged => _encounterSeconds >= definition.enrage.afterSeconds;
  double get movementMultiplier =>
      isEnraged ? definition.enrage.movementMultiplier : 1;
  double get patternTimeMultiplier =>
      isEnraged ? definition.enrage.patternTimeMultiplier : 1;
  double get lastAcceptedDt => _lastAcceptedDt;
  int get lastSubstepCount => _lastSubstepCount;
  BossPatternDefinition? get currentPattern => _currentPattern;

  BossPhase get phase {
    if (_isDefeated) return BossPhase.defeated;
    if (_legacyActions) {
      if (isEnraged) return BossPhase.enraged;
      final pattern = _currentPattern;
      if (pattern != null &&
          (_internalPhase == BossPhase.warning ||
              _internalPhase == BossPhase.attack)) {
        return switch (pattern.kind) {
          BossPatternKind.charge => BossPhase.charge,
          BossPatternKind.cone || BossPatternKind.radial => BossPhase.coneSlash,
          BossPatternKind.summon => BossPhase.summon,
        };
      }
      return BossPhase.approach;
    }
    if (isEnraged &&
        (_internalPhase == BossPhase.approach ||
            _internalPhase == BossPhase.recovery)) {
      return BossPhase.enraged;
    }
    return _internalPhase;
  }

  List<BossAction> tick({required double dt, required double healthFraction}) {
    _lastAcceptedDt = 0;
    _lastSubstepCount = 0;
    if (_isDefeated || healthFraction <= 0) {
      _isDefeated = true;
      return const [];
    }
    if (!dt.isFinite || dt <= 0) return const [];

    final acceptedDt = math.min(dt, maxAcceptedDt);
    _lastAcceptedDt = acceptedDt;
    _encounterSeconds += acceptedDt;
    var remaining = math.min(acceptedDt, _substepSeconds * maxSubsteps);
    final actions = <BossAction>[];
    while (remaining > 0 && _lastSubstepCount < maxSubsteps) {
      final step = math.min(_substepSeconds, remaining);
      _lastSubstepCount += 1;
      final emittedAction = _advance(
        step * patternTimeMultiplier,
        healthFraction.clamp(0, 1).toDouble(),
        actions,
      );
      remaining -= step;
      if (emittedAction) break;
    }
    return actions;
  }

  bool _advance(double dt, double healthFraction, List<BossAction> actions) {
    _phaseSeconds += dt;
    switch (_internalPhase) {
      case BossPhase.approach:
        if (_phaseSeconds < _approachSeconds) return false;
        final pattern = _nextEligiblePattern(healthFraction);
        if (pattern == null) {
          _phaseSeconds = 0;
          return false;
        }
        _currentPattern = pattern;
        _internalPhase = BossPhase.warning;
        _phaseSeconds = 0;
        actions.add(
          BossAction(type: _warningActionType(pattern), pattern: pattern),
        );
        return true;
      case BossPhase.warning:
        final pattern = _currentPattern!;
        if (_phaseSeconds < pattern.warningSeconds) return false;
        _internalPhase = BossPhase.attack;
        _phaseSeconds = 0;
        if (pattern.kind == BossPatternKind.summon) _summonConsumed = true;
        actions.add(
          BossAction(type: _executeActionType(pattern), pattern: pattern),
        );
        return true;
      case BossPhase.attack:
        if (_phaseSeconds < _attackSeconds(_currentPattern!)) return false;
        _internalPhase = BossPhase.recovery;
        _phaseSeconds = 0;
        return false;
      case BossPhase.recovery:
        final pattern = _currentPattern!;
        if (_phaseSeconds < pattern.recoverySeconds) return false;
        _advancePatternIndex();
        _currentPattern = null;
        _internalPhase = BossPhase.approach;
        _phaseSeconds = 0;
        return false;
      case BossPhase.charge:
      case BossPhase.coneSlash:
      case BossPhase.summon:
      case BossPhase.enraged:
      case BossPhase.defeated:
        return false;
    }
  }

  BossActionType _warningActionType(BossPatternDefinition pattern) {
    if (!_legacyActions) return BossActionType.warning;
    return switch (pattern.kind) {
      BossPatternKind.charge => BossActionType.chargeWarning,
      BossPatternKind.cone ||
      BossPatternKind.radial => BossActionType.coneWarning,
      BossPatternKind.summon => BossActionType.warning,
    };
  }

  BossActionType _executeActionType(BossPatternDefinition pattern) {
    if (!_legacyActions) return BossActionType.execute;
    return switch (pattern.kind) {
      BossPatternKind.charge => BossActionType.charge,
      BossPatternKind.cone ||
      BossPatternKind.radial => BossActionType.coneDamage,
      BossPatternKind.summon => BossActionType.summon,
    };
  }

  double _attackSeconds(BossPatternDefinition pattern) {
    if (pattern.kind == BossPatternKind.charge) {
      return math.max(0.12, pattern.chargeSeconds);
    }
    return 0.12;
  }

  BossPatternDefinition? _nextEligiblePattern(double healthFraction) {
    for (var checked = 0; checked < definition.patterns.length; checked += 1) {
      final pattern = definition.patterns[_patternIndex];
      final threshold = pattern.healthThreshold;
      final summonUnavailable =
          pattern.kind == BossPatternKind.summon && _summonConsumed;
      final healthUnavailable = threshold != null && healthFraction > threshold;
      if (!summonUnavailable && !healthUnavailable) return pattern;
      _advancePatternIndex();
    }
    return null;
  }

  void _advancePatternIndex() {
    _patternIndex = (_patternIndex + 1) % definition.patterns.length;
  }
}
