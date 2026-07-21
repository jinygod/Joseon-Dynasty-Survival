import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/systems/combat_feedback_controller.dart';

void main() {
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
}
