# Final Contract Fixes Report

Date: 2026-07-22

## Scope

This pass addressed only the two holistic-review blockers against the approved combat-mastery design:

1. Late performance sampling starts at the pressure-phase boundary, 180.0 seconds.
2. Combat feedback follows one centralized request contract: ordinary strong attacks request 20 ms hit-stop; mastery requests 35 ms hit-stop and enhanced shake only at mastery start and finish. Talisman master-ward activation receives one mastery-start request per spawned batch.

No save/schema version, serialized field, accessibility setting, population cap, licensed asset, Android build, deployment, or unrelated gameplay behavior was changed.

## TDD evidence

- The tracker boundary regression first failed with `lateAverageFps` equal to `0.0` when samples were placed at 179, 180, and 190 seconds.
- The feedback regressions first failed because `CombatFeedbackController.requestAttack` and the game-loop hit-stop observation did not exist. The pre-fix game loop also treated every master-presented hwando stage as a 35 ms mastery request and did not route talisman master wards through mastery feedback.
- Minimal production changes then moved `CombatPlaytestTracker.lateRunStartSeconds` to 180.0 and introduced `CombatFeedbackBeat` classification in `CombatFeedbackController`.

## Result

- Commit `6c59815` (`fix: sample late combat metrics from pressure phase`)
  - Samples raw late FPS beginning at exactly 180.0 seconds.
  - Updates telemetry schema documentation without changing schema 2 field names or encoding.
  - Retains schema 1 fallback behavior and deterministic schema 2 map serialization.
- Commit `6704d77` (`fix: enforce combat feedback beats`)
  - Maps ordinary `strong` attacks to a 20 ms, no-shake request under the existing 35 ms global cap.
  - Maps hwando mastery opener and finisher to 35 ms plus capped shake; its three middle stages request neither.
  - Routes a talisman master-ward batch through the same mastery-start contract exactly once.
  - Records mastery activation only on a mastery-start beat and preserves one mastery audio cue per activation.
  - Continues to clear/suppress shake when the accessibility setting is disabled.

## Verification

- Telemetry-focused suite: 30 tests passed across `combat_playtest_tracker_test.dart`, `run_telemetry_test.dart`, and `telemetry_export_service_test.dart`.
- Feedback-focused suite: 118 tests passed across controller, live game loop, hwando executor, talisman executor, weapon system, audio cue, and performance-budget tests.
- `flutter analyze --no-pub`: `No issues found!` through a temporary ASCII junction, used because the analysis server fails to frame its LSP initialization JSON from the Korean repository path. The junction was removed afterward.

Full Android and deployment gates were intentionally not run; the parent final gate owns them.
