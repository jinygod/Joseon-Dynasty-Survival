# QA Release Candidate Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete QA-003, QA-006, QA-010, and QA-012 with reproducible performance, visual, policy, and release-report evidence.

**Architecture:** A pure aggregation layer observes the real fixed-step Flame run without coupling the game to filesystem output. Widget goldens own deterministic fixtures. A pure Dart RC generator validates externally supplied gate evidence and derives the release decision from the documented severity policy.

**Tech Stack:** Dart 3.12, Flutter 3.44, Flame 1.x, `flutter_test`, PowerShell release gate.

## Global Constraints

- Do not modify `docs/master-development-todo.md`.
- Do not modify accessibility behavior or Android configuration.
- Production screen changes are limited to the minimum deterministic injection needed by goldens.
- Automated memory evidence is explicitly a component-graph proxy; physical memory is verified manually in profile mode.

---

### Task 1: Five-minute performance development log

**Files:**
- Create: `lib/game/performance/performance_development_log.dart`
- Create: `lib/game/performance/performance_development_reporter.dart`
- Create: `test/game/performance_development_log_test.dart`
- Create: `test/game/five_minute_performance_development_log_test.dart`
- Create: `docs/testing/five-minute-performance-development-log.md`

**Interfaces:**
- Produces: `PerformanceDevelopmentCollector.record`, `PerformanceDevelopmentLog`, and `PerformanceDevelopmentReporter`.

- [ ] Write tests that require peak population, fixed-step, update-cost, proxy, violation, and serialization fields.
- [ ] Run `A:\bin\flutter.bat test test/game/performance_development_log_test.dart` and confirm missing-library RED.
- [ ] Implement immutable sample aggregation and deterministic JSON/Markdown reporting.
- [ ] Run the unit test and confirm GREEN.
- [ ] Add the real fixed-seed 300-second, 18,000-step Flame scenario and confirm it initially fails before its required development-log artifact behavior exists.
- [ ] Generate and document the observed log plus the profile-mode physical-memory procedure.
- [ ] Run both focused performance tests and confirm GREEN.

### Task 2: Major-surface 16:9 goldens

**Files:**
- Create: `test/app/release_surface_golden_test.dart`
- Create: `test/goldens/*.png`
- Modify production app screens only if test-owned deterministic fixtures are insufficient.

**Interfaces:**
- Produces: six named 1280x720 visual contracts.

- [ ] Write golden tests for lobby, character selection, stage selection, HUD, pause, and result.
- [ ] Run without baselines and confirm missing-golden RED.
- [ ] Generate PNG baselines with `A:\bin\flutter.bat test --update-goldens test/app/release_surface_golden_test.dart`.
- [ ] Rerun normal comparison and confirm GREEN with no widget exceptions.

### Task 3: Severity and release-blocking policy

**Files:**
- Create: `docs/testing/release-blocking-policy.md`
- Create: `test/policy/release_blocking_policy_test.dart`

**Interfaces:**
- Produces: P0-P3 definitions and objective block/unblock rules consumed by the RC report.

- [ ] Write a document-contract test for P0-P3, P0/P1 blocking, evidence blocking, accepted P2 fields, and unblock evidence.
- [ ] Run it and confirm missing-document RED.
- [ ] Write the policy with examples, decision ownership, aging, exception, and regression-proof requirements.
- [ ] Rerun and confirm GREEN.

### Task 4: Automated release-candidate report

**Files:**
- Create: `tool/release_candidate_report.dart`
- Create: `test/tool/release_candidate_report_test.dart`
- Create: `docs/testing/release-candidate-reporting.md`
- Create: `docs/testing/release-candidate-report.md`

**Interfaces:**
- Produces: `ReleaseCandidateEvidence`, `ReleaseCandidateReport`, `generateReleaseCandidateReport`, and CLI flags for every required gate.

- [ ] Write tests for READY evidence, failed/missing evidence, open P0/P1 blockers, deterministic Markdown, and CLI validation.
- [ ] Run and confirm missing-tool RED.
- [ ] Implement strict parsing, decision calculation, Markdown rendering, output writing, and nonzero invalid-input exit.
- [ ] Rerun and confirm GREEN.
- [ ] Document the invocation and generate the candidate report from fresh gate evidence.

### Task 5: Release verification and commit

**Files:**
- Create: `docs/superpowers/verification/2026-07-16-qa-release-candidate.md`

**Interfaces:**
- Consumes: all QA artifacts and fresh command outputs.

- [ ] Run Dart format check across `lib test tool`.
- [ ] Run `A:\bin\dart.bat analyze`.
- [ ] Run `A:\bin\flutter.bat test -r compact`.
- [ ] Run `A:\bin\flutter.bat build web`.
- [ ] Audit `git diff --check`, branch scope, and unchanged forbidden files.
- [ ] Record exact evidence, generate the RC report, commit all scoped changes, and verify a clean branch.
