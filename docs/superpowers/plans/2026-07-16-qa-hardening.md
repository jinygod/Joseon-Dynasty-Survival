# QA Hardening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete QA-002, QA-005, and QA-007 with one runtime population-budget contract, a complete player-flow integration test, and a deterministic 20-run lifecycle leak test.

**Architecture:** A new immutable game performance budget defines limits and snapshots for enemies, projectiles, damage numbers, and combat effects. `PixelSurvivorGame` applies those limits only at its existing spawn boundaries and emits isolated rejection diagnostics. Widget tests drive the real Lobby, Flame `GameWidget`, level-up overlay, settlement screen, retry navigation, disposal, audio, controller listeners, and HUD timers.

**Tech Stack:** Dart 3.12.2, Flutter 3.44.4, Flame, `flutter_test`, `flame_test`.

## Global Constraints

- Start from master commit `db45241` in `.worktrees/qa-hardening` on `codex/qa-hardening`.
- Do not modify collection UI, content definitions, settings screens, or `docs/master-development-todo.md`.
- Production ownership is limited to new `lib/game/*budget*` code and local cap/diagnostic changes in `PixelSurvivorGame`; test-only support may instrument listeners, audio, timers, and navigation.
- Use deterministic accelerated runs while traversing the actual game and widget lifecycle.
- Verify focused tests, all tests, static analysis, and Web build through ASCII paths.

---

### Task 1: Runtime population budget contract

**Files:**
- Create: `lib/game/game_performance_budget.dart`
- Create: `test/game/game_performance_budget_test.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `lib/game/systems/combat_feedback_tuning.dart`
- Modify: `test/game/combat_feedback_tuning_test.dart`

**Interfaces:**
- Produces: `GamePopulationKind`, `GamePerformanceBudget.limitFor`, `GamePerformanceSnapshot`, and `GamePerformanceDiagnostic`.
- `PixelSurvivorGame.performanceSnapshot` reports current populations and rejected additions; optional `onPerformanceDiagnostic` receives a diagnostic without being allowed to break gameplay.

- [ ] **Step 1: Write failing budget tests**

  Assert the exact positive limits, boundary admission behavior, immutable snapshot counts, over-budget detection, and a game stress case that attempts more projectiles, damage numbers, and effects than the contract permits.

- [ ] **Step 2: Run the focused tests and verify RED**

  Run `Z:\bin\flutter.bat test test/game/game_performance_budget_test.dart test/game/combat_feedback_tuning_test.dart` from `Q:\`.

  Expected: compilation fails because the budget API does not exist.

- [ ] **Step 3: Implement the minimum budget and runtime guards**

  Define limits of 96 enemies, 128 projectiles, 24 damage numbers, and 32 combat effects. Replace feedback-limit duplication with the central contract. Limit wave/minion enemy admission and weapon projectile admission; reuse the contract for the existing damage-number/effect counters. Record each rejected population and call the optional diagnostic callback inside `try/catch`.

- [ ] **Step 4: Run focused tests and verify GREEN**

  Run the same command and confirm every budget and existing feedback assertion passes.

### Task 2: Full player-flow integration regression

**Files:**
- Create: `test/app/release_flow_integration_test.dart`

**Interfaces:**
- Consumes: existing Lobby, character/stage selection, GameScreen, Flame game, level-up overlay, settlement, and retry APIs.
- Produces: one regression covering menu → character → stage → game → level-up → result → retry.

- [ ] **Step 1: Add the end-to-end widget test**

  Mount a real `LobbyScreen` with in-memory save/settings stores and completed tutorial state. Select and confirm the saved character and stage, deploy, await the real Flame game, trigger experience through `gainExperience`, choose a real level-up card, advance to the boss boundary, resolve victory, await real settlement navigation, tap `result-retry`, and assert a distinct mounted `PixelSurvivorGame` begins with reset run state.

- [ ] **Step 2: Run the integration test**

  Run `Z:\bin\flutter.bat test test/app/release_flow_integration_test.dart` from `Q:\` and correct only genuine flow/testability defects within the authorized scope.

### Task 3: Twenty-run lifecycle leak regression

**Files:**
- Create: `test/app/repeated_run_lifecycle_test.dart`

**Interfaces:**
- Consumes: the same real GameScreen/Flame lifecycle, injected settings controller, `GameAudioService`, and recording audio backend.
- Produces: deterministic evidence that 20 run replacements do not retain mounted game components, settings listeners, audio voices, periodic HUD timers, or navigation state.

- [ ] **Step 1: Write the repeated-run lifecycle test**

  Track controller `addListener`/`removeListener`, recording audio handles, and each old game instance. For 20 iterations, mount the real game, await readiness, advance through the boss victory path, settle, and retry (or return to menu after run 20). After each replacement, assert the old game is unmounted and has no mounted descendants; at final teardown assert listener balance returns to the app baseline, all audio is disposed/stopped, no exceptions were captured, and `pumpWidget(SizedBox.shrink())` leaves no periodic timer failure.

- [ ] **Step 2: Run the lifecycle test and verify RED/GREEN**

  Run `Z:\bin\flutter.bat test test/app/repeated_run_lifecycle_test.dart` from `Q:\`. If it exposes a leak in an owned `PixelSurvivorGame` lifecycle path, add the smallest production cleanup after preserving the failing reproduction, then rerun to green.

### Task 4: Verification evidence and commit

**Files:**
- Create: `docs/superpowers/verification/2026-07-16-qa-hardening.md`

**Interfaces:**
- Produces: exact RED/GREEN and release-gate evidence for QA-002, QA-005, and QA-007.

- [ ] **Step 1: Run fresh verification**

  From the ASCII-mapped worktree run formatting, focused QA tests, `Z:\bin\dart.bat analyze`, `Z:\bin\flutter.bat test -r compact`, and `Z:\bin\flutter.bat build web`.

- [ ] **Step 2: Record evidence and inspect scope**

  Record exit codes/test totals and the Korean-path shader failure plus ASCII-path recovery. Run `git diff --check`, verify forbidden paths are unchanged, and inspect the complete diff.

- [ ] **Step 3: Commit**

  Commit the verified implementation, tests, plan, and evidence with an intentional QA-hardening message, then report the SHA and clean worktree state.
