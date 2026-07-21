import '../combat/attack_spec.dart';
import 'combat_feedback_tuning.dart';

class CombatFeedbackRequest {
  const CombatFeedbackRequest({
    required this.hitStopSeconds,
    required this.shakeMagnitude,
    required this.presentation,
  });

  const CombatFeedbackRequest.master()
    : hitStopSeconds = .035,
      shakeMagnitude = 4,
      presentation = AttackPresentation.master;

  final double hitStopSeconds;
  final double shakeMagnitude;
  final AttackPresentation presentation;
}

class CombatFeedbackController {
  factory CombatFeedbackController({required bool screenShakeEnabled}) =>
      CombatFeedbackController._(screenShakeEnabled);

  CombatFeedbackController._(this._screenShakeEnabled);

  bool _screenShakeEnabled;
  double hitStopRemaining = 0;
  double pendingShakeMagnitude = 0;

  set screenShakeEnabled(bool value) {
    _screenShakeEnabled = value;
    if (!value) pendingShakeMagnitude = 0;
  }

  void request(CombatFeedbackRequest request) {
    hitStopRemaining = (hitStopRemaining + request.hitStopSeconds)
        .clamp(0, CombatFeedbackTuning.maxHitStopSeconds)
        .toDouble();
    if (_screenShakeEnabled) {
      pendingShakeMagnitude = (pendingShakeMagnitude + request.shakeMagnitude)
          .clamp(0, CombatFeedbackTuning.maxScreenShakeMagnitude)
          .toDouble();
    }
  }

  double tick(double dt) {
    final safeDt = dt.isFinite && dt > 0 ? dt : 0.0;
    final consumed = safeDt.clamp(0, hitStopRemaining).toDouble();
    hitStopRemaining = (hitStopRemaining - consumed).clamp(0, double.infinity);
    return safeDt - consumed;
  }

  double takePendingShakeMagnitude() {
    final magnitude = pendingShakeMagnitude;
    pendingShakeMagnitude = 0;
    return magnitude;
  }
}
