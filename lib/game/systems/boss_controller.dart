import 'dart:math' as math;

import '../content/boss_definitions.dart';

enum BossPhase { approach, warning, attack, recovery, enraged, defeated }

enum BossActionType { warning, execute }

class BossAction {
  const BossAction({required this.type, required this.pattern});

  final BossActionType type;
  final BossPatternDefinition pattern;
}

class BossController {
  BossController({BossDefinition? definition})
    : definition = definition ?? fallenGeneralBossDefinition;

  static const enrageSeconds = 25.0;
  static const chargeWarningSeconds = 0.75;
  static const coneWarningSeconds = 0.60;
  static const normalPatternCycleSeconds = 3.0;
  static const _approachSeconds = 0.50;

  final BossDefinition definition;

  BossPhase _phase = BossPhase.approach;
  double _encounterSeconds = 0;
  double _phaseSeconds = 0;
  int _patternIndex = 0;
  BossPatternDefinition? _currentPattern;
  bool _summonConsumed = false;
  bool _isDefeated = false;

  bool get isEnraged => _encounterSeconds >= definition.enrage.afterSeconds;
  double get movementMultiplier =>
      isEnraged ? definition.enrage.movementMultiplier : 1;
  double get patternTimeMultiplier =>
      isEnraged ? definition.enrage.patternTimeMultiplier : 1;
  BossPhase get phase => _isDefeated ? BossPhase.defeated : _phase;
  BossPatternDefinition? get currentPattern => _currentPattern;

  List<BossAction> tick({required double dt, required double healthFraction}) {
    if (_isDefeated || healthFraction <= 0) {
      _isDefeated = true;
      return const [];
    }
    if (!dt.isFinite || dt <= 0) return const [];

    final actions = <BossAction>[];
    var remaining = dt;
    while (remaining > 0) {
      final step = math.min(0.05, remaining);
      _encounterSeconds += step;
      _advance(
        step * patternTimeMultiplier,
        healthFraction.clamp(0, 1).toDouble(),
        actions,
      );
      remaining -= step;
    }
    return actions;
  }

  void _advance(double dt, double healthFraction, List<BossAction> actions) {
    _phaseSeconds += dt;
    switch (_phase) {
      case BossPhase.approach:
        if (_phaseSeconds < _approachSeconds) return;
        final pattern = _nextEligiblePattern(healthFraction);
        if (pattern == null) {
          _phaseSeconds = 0;
          return;
        }
        _currentPattern = pattern;
        _phase = BossPhase.warning;
        _phaseSeconds = 0;
        actions.add(BossAction(type: BossActionType.warning, pattern: pattern));
      case BossPhase.warning:
        final pattern = _currentPattern!;
        if (_phaseSeconds < pattern.warningSeconds) return;
        _phase = BossPhase.recovery;
        _phaseSeconds = 0;
        if (pattern.kind == BossPatternKind.summon) _summonConsumed = true;
        actions.add(BossAction(type: BossActionType.execute, pattern: pattern));
      case BossPhase.recovery:
        final pattern = _currentPattern!;
        if (_phaseSeconds < pattern.recoverySeconds) return;
        _advancePatternIndex();
        _currentPattern = null;
        _phase = BossPhase.approach;
        _phaseSeconds = 0;
      case BossPhase.attack:
      case BossPhase.enraged:
      case BossPhase.defeated:
        return;
    }
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
