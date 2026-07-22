import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/combat/attack_spec.dart';
import 'package:pixel_survivor/game/systems/combat_feedback_controller.dart';

void main() {
  AttackInstance attack({
    required String id,
    required AttackPresentation presentation,
    required int sequenceIndex,
  }) => AttackInstance(
    spec: AttackSpec(
      id: id,
      shape: AttackShape.circle,
      damage: 1,
      range: 0,
      angleRadians: 0,
      radius: 1,
      width: 0,
      windupSeconds: 0,
      activeSeconds: 0,
      lingerSeconds: 0,
      knockback: 0,
      slowFraction: 0,
      traits: const {},
      presentation: presentation,
    ),
    origin: Vector2.zero(),
    direction: Vector2(1, 0),
    sequenceIndex: sequenceIndex,
  );

  test('master feedback caps stacked hit stop and honors disabled shake', () {
    final feedback = CombatFeedbackController(screenShakeEnabled: false);

    feedback.request(const CombatFeedbackRequest.master());
    feedback.request(const CombatFeedbackRequest.master());

    expect(feedback.hitStopRemaining, .035);
    expect(feedback.pendingShakeMagnitude, 0);
  });

  test('tick returns only time left after consuming capped hit stop', () {
    final feedback = CombatFeedbackController(screenShakeEnabled: true)
      ..request(const CombatFeedbackRequest.master());

    expect(feedback.tick(.02), 0);
    expect(feedback.hitStopRemaining, closeTo(.015, .000001));
    expect(feedback.tick(.02), closeTo(.005, .000001));
    expect(feedback.hitStopRemaining, 0);
  });

  test(
    'ordinary strong attacks request capped twenty millisecond hit stop',
    () {
      final feedback = CombatFeedbackController(screenShakeEnabled: true);

      feedback.requestAttack(
        attack(
          id: 'talisman_explosion',
          presentation: AttackPresentation.strong,
          sequenceIndex: 0,
        ),
      );

      expect(feedback.hitStopRemaining, .020);
      expect(feedback.pendingShakeMagnitude, 0);
    },
  );

  test('hwando mastery enhances only its opening and finishing stages', () {
    final feedback = CombatFeedbackController(screenShakeEnabled: true);
    final stages = [
      ('hwando_master_opener', 0),
      ('hwando_master_left', 1),
      ('hwando_master_right', 2),
      ('hwando_master_circle', 3),
      ('hwando_master_finisher', 4),
    ];
    final enhanced = <int>[];

    for (final (id, index) in stages) {
      feedback.requestAttack(
        attack(
          id: id,
          presentation: AttackPresentation.master,
          sequenceIndex: index,
        ),
      );
      if (feedback.hitStopRemaining > 0) enhanced.add(index);
      feedback.tick(1);
      feedback.takePendingShakeMagnitude();
    }

    expect(enhanced, [0, 4]);
  });

  test('feedback timing contract is exact for strong and mastery beats', () {
    final cases = <(AttackInstance, double)>[
      (
        attack(
          id: 'talisman_explosion',
          presentation: AttackPresentation.strong,
          sequenceIndex: 0,
        ),
        .020,
      ),
      (
        attack(
          id: 'hwando_master_opener',
          presentation: AttackPresentation.master,
          sequenceIndex: 0,
        ),
        .035,
      ),
      (
        attack(
          id: 'hwando_master_left',
          presentation: AttackPresentation.master,
          sequenceIndex: 1,
        ),
        0,
      ),
      (
        attack(
          id: 'hwando_master_finisher',
          presentation: AttackPresentation.master,
          sequenceIndex: 4,
        ),
        .035,
      ),
      (
        attack(
          id: 'sealing_slash',
          presentation: AttackPresentation.synergy,
          sequenceIndex: 0,
        ),
        0,
      ),
    ];

    for (final (instance, expectedSeconds) in cases) {
      final feedback = CombatFeedbackController(screenShakeEnabled: true);
      feedback.requestAttack(instance);
      expect(
        feedback.hitStopRemaining,
        expectedSeconds,
        reason: instance.spec.id,
      );
    }
  });
}
