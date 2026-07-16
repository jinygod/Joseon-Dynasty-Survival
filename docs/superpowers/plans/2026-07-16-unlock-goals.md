# Unlock Goals Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist and evaluate exactly 15 gameplay goals that unlock every non-starting release content item and expose UI-ready progress.

**Architecture:** Content definitions remain declarative. `ProgressionSystem` owns pure counter/evaluation logic, `MetaProgressionService` serializes load/settle/query operations, and `SaveState` owns schema migration and sanitization.

**Tech Stack:** Dart 3.12, Flutter 3.44, `flutter_test`, SharedPreferences.

## Global Constraints

- Preserve the ten existing goal IDs.
- Do not modify boss or settings UI files.
- Do not modify `docs/master-development-todo.md`.
- Use tests before production changes and verify through the ASCII-path release gate.

---

### Task 1: Goal catalog contract

**Files:**
- Modify: `lib/game/content/ids.dart`
- Modify: `lib/game/content/unlock_definitions.dart`
- Create: `test/game/unlock_definitions_test.dart`

**Interfaces:**
- Produces: `UnlockRewardType`, stage reward fields, two new cumulative metrics, and 15 definitions.

- [ ] Write catalog tests asserting 15 unique IDs, one reward per goal, valid referenced IDs, and exact coverage of all non-starting content.
- [ ] Run `flutter test test/game/unlock_definitions_test.dart` through an ASCII `subst` path and confirm RED because only 10 goals and no stage reward exist.
- [ ] Add the minimal typed reward/metric fields and five definitions; split `rapid_reload` from `reach_level_10`.
- [ ] Re-run the focused test and confirm GREEN.

### Task 2: Save schema v3

**Files:**
- Modify: `lib/game/systems/save_system.dart`
- Modify: `test/game/save_system_test.dart`

**Interfaces:**
- Produces: `SaveState.unlockedStageIds`, `totalEliteKills`, `victoryCount`; schema v3 JSON round-trip and v0-v2 migration.

- [ ] Add failing tests for v2 migration, v3 round trip, unknown-ID removal, invalid counters, starting-only defaults, and selected-stage fallback.
- [ ] Run focused save tests and confirm RED on schema/version/missing fields.
- [ ] Implement schema v3 fields, known-ID filtering, starting-content union, and safe defaults.
- [ ] Re-run focused save tests and confirm GREEN.

### Task 3: Run and cumulative goal evaluation

**Files:**
- Modify: `lib/game/systems/progression_system.dart`
- Modify: `test/game/progression_system_test.dart`

**Interfaces:**
- Consumes: v3 counters and the catalog.
- Produces: stage rewards, elite/victory accumulation, metric values, and idempotent completion.

- [ ] Add failing tests proving elite accumulation, victory stage unlock, character locks/unlocks, and repeated evaluation stability.
- [ ] Run focused tests and confirm RED.
- [ ] Update `applyRunResult`, reward application, and metric lookup with the minimum implementation.
- [ ] Re-run focused tests and confirm GREEN.

### Task 4: Progress query API and settlement integration

**Files:**
- Modify: `lib/game/models/meta_progress.dart`
- Modify: `lib/game/systems/meta_progression_service.dart`
- Modify: `test/game/meta_progression_service_test.dart`

**Interfaces:**
- Produces: immutable `UnlockGoalProgress` and `loadUnlockProgress()` returning ordered, clamped progress; settlement includes unlock diff.

- [ ] Add failing tests for zero/partial/complete/clamped progress, typed rewards, settlement unlock persistence, and duplicate settlement safety.
- [ ] Run focused tests and confirm RED.
- [ ] Implement the query projection and expose `ProgressionUnlocks` on `RunSettlement`.
- [ ] Re-run focused tests and confirm GREEN.

### Task 5: Verification and evidence

**Files:**
- Create: `docs/superpowers/verification/2026-07-16-unlock-goals.md`

- [ ] Run `tool/release_check.ps1` so format, `dart analyze`, all Flutter tests, and Web build execute through ASCII mapped paths.
- [ ] Record exact commands, exit codes, and any environment limitations in the verification note.
- [ ] Inspect `git diff --check`, `git status`, and the requirement checklist.
- [ ] Commit production/tests and verification evidence in logical commits.
