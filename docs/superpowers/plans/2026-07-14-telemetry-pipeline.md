# Local Run Telemetry Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete `TEL-002` through `TEL-007` by collecting actionable run events and safely retaining the latest 50 runs on-device without ever blocking progression saving or navigation.

**Architecture:** `RunStatsTracker` remains the single in-run accumulator and produces an expanded immutable `RunResult`. `RunTelemetryService` converts the result plus runtime package metadata and UTC session times into `RunTelemetry`; `TelemetryRepository` stores a bounded JSON list in `SharedPreferences`. The service catches telemetry-only failures, while progression saving remains outside that error boundary.

**Tech Stack:** Dart 3.12, Flutter 3.44, Flame, `shared_preferences`, `package_info_plus: ^10.2.0`, Flutter test.

## Global Constraints

- Telemetry is local-only; no network upload or identifier tied to a person.
- Keep at most 50 completed runs, oldest first.
- Store UTC ISO-8601 timestamps and app `version+buildNumber` from platform package metadata.
- Count effective damage only: damage beyond remaining health is excluded.
- A telemetry failure must not throw into `GameScreen._handleRunEnded`.
- Every behavior change follows red-green-refactor and the full release gate.

---

### Task 1: Expand run result and telemetry schema

**Files:**
- Create: `lib/game/models/run_choice_record.dart`
- Modify: `lib/game/models/run_result.dart`
- Modify: `lib/game/models/run_telemetry.dart`
- Modify: `test/game/run_telemetry_test.dart`
- Modify: `docs/telemetry/run-telemetry-schema.md`

**Interfaces:**
- Produces: `RunChoiceRecord(type, contentId, selectedAtSeconds, selectedLevel)`.
- Produces: optional backward-compatible schema-1 fields `weaponDamageTotals`, `choices`, `totalDamageTaken`, `lastDamageSource`, and `deathAtSeconds`.
- Produces: `RunTelemetry.fromRunResult(...)` for the persistence service.

- [ ] **Step 1: Write failing round-trip and mapping tests**

Create records with two choices, decimal weapon damage, player damage, and a death timestamp. Assert `toJson`/`fromJson` and `fromRunResult` preserve all fields.

- [ ] **Step 2: Run the focused test and verify RED**

Run: `flutter test test/game/run_telemetry_test.dart -r expanded`

Expected: compilation fails because the new record and fields do not exist.

- [ ] **Step 3: Implement immutable records and backward-compatible decoding**

Missing new JSON fields decode to empty maps/lists, zero damage, and null optional values so existing schema-1 payloads remain readable. Invalid supplied field types still throw `FormatException`.

- [ ] **Step 4: Run the focused test and verify GREEN**

Run: `flutter test test/game/run_telemetry_test.dart -r expanded`

Expected: all telemetry model tests pass.

- [ ] **Step 5: Commit**

```powershell
git add lib/game/models test/game/run_telemetry_test.dart docs/telemetry/run-telemetry-schema.md
git commit -m "feat: expand run telemetry metrics"
```

### Task 2: Collect combat, choice, and player-damage metrics

**Files:**
- Modify: `lib/game/systems/run_stats_tracker.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `test/game/run_stats_tracker_test.dart`
- Modify: `test/game/pixel_survivor_game_loop_test.dart`

**Interfaces:**
- Produces: `recordWeaponDamage`, `recordChoice`, and `recordPlayerDamage` on `RunStatsTracker`.
- Consumes: effective damage calculated around `EnemyComponent.takeDamage` and actual health loss around player damage calls.

- [ ] **Step 1: Write failing accumulator tests**

Assert two hits from the same weapon sum, repeated kill attribution increments, choices keep selection order/time/level, damage received sums, last source updates, and the first lethal damage records `deathAtSeconds`.

- [ ] **Step 2: Run tracker tests and verify RED**

Run: `flutter test test/game/run_stats_tracker_test.dart -r expanded`

Expected: compilation fails on missing metric methods and result fields.

- [ ] **Step 3: Implement minimal tracker accumulation**

Ignore non-positive damage, freeze maps/lists in `RunResult`, and never overwrite the first death time.

- [ ] **Step 4: Write failing game integration tests**

Use the existing debug game helpers to apply a level-up and damage. Assert the resulting choice and damage metrics are present and that weapon overkill records only remaining enemy health.

- [ ] **Step 5: Connect game events and verify GREEN**

Track the last weapon to hit each enemy for kill attribution, remove attribution when the enemy is collected, and record actual player health loss for contact and boss-area damage.

- [ ] **Step 6: Commit**

```powershell
git add lib/game/systems/run_stats_tracker.dart lib/game/pixel_survivor_game.dart test/game
git commit -m "feat: collect run combat telemetry"
```

### Task 3: Persist the latest 50 runs

**Files:**
- Create: `lib/game/systems/telemetry_repository.dart`
- Create: `test/game/telemetry_repository_test.dart`

**Interfaces:**
- Produces: `TelemetryRepository.load()` and `TelemetryRepository.append(RunTelemetry)`.
- Storage key: `run_telemetry_history` containing a JSON array ordered oldest to newest.

- [ ] **Step 1: Write failing repository tests**

Use `SharedPreferences.setMockInitialValues`. Assert JSON round trips, a malformed store loads as empty, malformed individual rows are skipped, and appending run 51 removes run 1 while preserving runs 2 through 51.

- [ ] **Step 2: Run repository tests and verify RED**

Run: `flutter test test/game/telemetry_repository_test.dart -r expanded`

Expected: compilation fails because the repository does not exist.

- [ ] **Step 3: Implement repository and verify GREEN**

Decode only JSON lists and map entries. Catch decoding/schema errors per row. Check the boolean returned by `setString` and throw `StateError` on a rejected write so the service boundary can isolate it.

- [ ] **Step 4: Commit**

```powershell
git add lib/game/systems/telemetry_repository.dart test/game/telemetry_repository_test.dart
git commit -m "feat: retain recent run telemetry"
```

### Task 4: Record completed runs without blocking navigation

**Files:**
- Create: `lib/game/systems/run_telemetry_service.dart`
- Create: `test/game/run_telemetry_service_test.dart`
- Modify: `lib/app/game_screen.dart`
- Modify: `pubspec.yaml`
- Modify: `docs/master-development-todo.md`

**Interfaces:**
- Produces: `RunTelemetryService.record(result, startedAtUtc)` which always completes normally.
- Default dependencies: `PackageInfo.fromPlatform`, `DateTime.now().toUtc`, and `TelemetryRepository.append`.

- [ ] **Step 1: Write failing service tests**

Inject fixed package version/build, clock, and an in-memory append callback. Assert the saved run ID is stable and non-empty, app version is `0.1.0+1`, and result fields map correctly. Inject a throwing append callback and assert `record` completes without throwing.

- [ ] **Step 2: Run service tests and verify RED**

Run: `flutter test test/game/run_telemetry_service_test.dart -r expanded`

Expected: compilation fails because the service does not exist.

- [ ] **Step 3: Add dependency and implement service**

Add `package_info_plus: ^10.2.0`. Build the run ID from UTC start microseconds plus UTC end microseconds. Catch only inside the telemetry service; do not wrap progression saving.

- [ ] **Step 4: Wire `GameScreen` and verify GREEN**

Capture `_runStartedAtUtc` when the screen state is created. After progression save succeeds, await `RunTelemetryService.record`; its internal error isolation guarantees navigation continues.

- [ ] **Step 5: Update documentation and TODO evidence**

Mark `TEL-002` through `TEL-007` complete only after focused tests and the full release gate pass. Advance the next queue to `TEL-008`.

- [ ] **Step 6: Commit and run full gate**

```powershell
git add pubspec.yaml pubspec.lock lib test docs
git commit -m "feat: record local run telemetry"
.\tool\release_check.ps1
```

Expected: analysis clean, all tests pass, web release build succeeds.
