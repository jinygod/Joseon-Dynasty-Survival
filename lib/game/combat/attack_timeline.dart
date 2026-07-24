import 'package:flutter/foundation.dart';

enum AttackPhase { windup, active, recovery, complete }

@immutable
class AttackTiming {
  const AttackTiming({
    required this.windupSeconds,
    required this.activeSeconds,
    required this.recoverySeconds,
  }) : assert(windupSeconds >= 0),
       assert(activeSeconds >= 0),
       assert(recoverySeconds >= 0);

  final double windupSeconds;
  final double activeSeconds;
  final double recoverySeconds;

  double get activeEndsAt => windupSeconds + activeSeconds;
  double get totalSeconds => activeEndsAt + recoverySeconds;
}

@immutable
class AttackTimelineAdvance {
  const AttackTimelineAdvance({
    required this.enteredActive,
    required this.completed,
  });

  final bool enteredActive;
  final bool completed;
}

class AttackTimelineCursor {
  AttackTimelineCursor(this.timing);

  final AttackTiming timing;
  double _elapsedSeconds = 0;
  bool _didEnterActive = false;

  double get elapsedSeconds => _elapsedSeconds;

  AttackPhase get phase {
    if (_elapsedSeconds >= timing.totalSeconds) return AttackPhase.complete;
    if (_elapsedSeconds >= timing.activeEndsAt) return AttackPhase.recovery;
    if (_elapsedSeconds >= timing.windupSeconds) return AttackPhase.active;
    return AttackPhase.windup;
  }

  AttackTimelineAdvance advance(double dt) {
    final safeDt = dt.isFinite && dt > 0 ? dt : 0.0;
    final wasComplete = phase == AttackPhase.complete;
    final previousSeconds = _elapsedSeconds;
    _elapsedSeconds = (_elapsedSeconds + safeDt).clamp(
      0,
      timing.totalSeconds,
    );
    final enteredActive =
        !_didEnterActive &&
        previousSeconds < timing.windupSeconds &&
        _elapsedSeconds >= timing.windupSeconds;
    if (enteredActive) _didEnterActive = true;
    return AttackTimelineAdvance(
      enteredActive: enteredActive,
      completed: !wasComplete && phase == AttackPhase.complete,
    );
  }
}
