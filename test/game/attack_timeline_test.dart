import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/combat/attack_timeline.dart';

void main() {
  test('windup crossing emits one active transition before recovery', () {
    final cursor = AttackTimelineCursor(
      const AttackTiming(
        windupSeconds: .06,
        activeSeconds: .08,
        recoverySeconds: .10,
      ),
    );

    expect(cursor.advance(.059).enteredActive, isFalse);
    expect(cursor.phase, AttackPhase.windup);

    expect(cursor.advance(.001).enteredActive, isTrue);
    expect(cursor.phase, AttackPhase.active);

    expect(cursor.advance(.08).enteredActive, isFalse);
    expect(cursor.phase, AttackPhase.recovery);

    expect(cursor.advance(.10).completed, isTrue);
    expect(cursor.phase, AttackPhase.complete);
  });

  test('large frame delta still emits the active transition exactly once', () {
    final cursor = AttackTimelineCursor(
      const AttackTiming(
        windupSeconds: .06,
        activeSeconds: .08,
        recoverySeconds: .10,
      ),
    );

    final crossing = cursor.advance(.20);

    expect(crossing.enteredActive, isTrue);
    expect(crossing.completed, isFalse);
    expect(cursor.phase, AttackPhase.recovery);
    expect(cursor.advance(.20).enteredActive, isFalse);
    expect(cursor.phase, AttackPhase.complete);
  });

  test('invalid or negative frame deltas cannot advance the attack', () {
    final cursor = AttackTimelineCursor(
      const AttackTiming(
        windupSeconds: .06,
        activeSeconds: .08,
        recoverySeconds: .10,
      ),
    );

    expect(cursor.advance(double.nan).enteredActive, isFalse);
    expect(cursor.advance(-1).enteredActive, isFalse);
    expect(cursor.elapsedSeconds, 0);
    expect(cursor.phase, AttackPhase.windup);
  });
}
