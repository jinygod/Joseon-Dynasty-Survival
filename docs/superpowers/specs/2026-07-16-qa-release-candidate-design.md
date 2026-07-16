# QA Release Candidate Design

## Scope

This release-candidate gate completes QA-003, QA-006, QA-010, and QA-012 without changing accessibility behavior, Android configuration, or the master development checklist.

## Selected approach

QA-003 uses the real `PixelSurvivorGame` with a fixed random seed, a fixed 1/60-second simulation step, deterministic automatic level-up choices, and a durable player health fixture. A collector records population snapshots, simulation frame steps, measured update cost, and a component-graph memory proxy. The committed development log distinguishes deterministic proxy evidence from physical-memory profiling and includes a manual profile-mode procedure.

QA-006 captures six 1280x720, DPR 1 golden surfaces: lobby, character selection, stage selection, game HUD, pause menu, and run summary. Test-owned controllers and immutable fixtures remove persistence, audio, timer, and navigation variability. Production screens change only if a stable state cannot otherwise be injected.

QA-010 defines P0 through P3, release-blocking rules, required ownership for accepted lower-severity defects, and objective unblock evidence. P0 and P1 always block; missing or failed release evidence also blocks.

QA-012 is a pure Dart report generator. It accepts branch, commit, version, analyze, test, web-build, performance, golden, and open-blocker evidence as explicit inputs; validates required fields; computes READY or BLOCKED; and writes deterministic Markdown when a generation timestamp is supplied.

## Boundaries

- `lib/game/performance/performance_development_log.dart` owns immutable samples and peak aggregation.
- `lib/game/performance/performance_development_reporter.dart` owns JSON/Markdown serialization.
- `test/game/five_minute_performance_development_log_test.dart` owns the accelerated real-game scenario and build artifact.
- `test/app/release_surface_golden_test.dart` and `test/goldens/` own visual baselines.
- `tool/release_candidate_report.dart` owns evidence validation and report generation.
- `docs/testing/` owns human-readable policy, performance evidence, manual memory procedure, RC usage, and the generated candidate report.

## Acceptance

- The accelerated scenario reaches 300 simulated seconds, records 18,000 fixed steps, remains inside every population budget, and reports peaks plus a component-count proxy.
- All six 16:9 golden comparisons pass.
- Policy tests find all four severity levels and explicit block/unblock rules.
- Report-generator tests prove READY, BLOCKED, and invalid-evidence behavior.
- Fresh format, analyze, full test, and web build gates pass through ASCII paths on Windows.
