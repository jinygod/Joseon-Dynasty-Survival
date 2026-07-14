# Playtest Feedback and Export Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete `TEL-008` through `TEL-012` with validated result-screen feedback, weapon performance, single-run JSON copy, all-history JSON file export, automated coverage, and a tester handoff guide.

**Architecture:** Add backward-compatible feedback to `RunTelemetry`, update it by run ID in `TelemetryRepository`, and isolate clipboard/share APIs in `TelemetryExportService`. Convert `RunSummaryScreen` to stateful local form state with callback interfaces. `GameScreen` connects callbacks to the telemetry services without moving persistence into widgets.

**Tech Stack:** Dart 3.12, Flutter 3.44, `shared_preferences`, `share_plus: ^13.2.0`, Flutter Clipboard, Flutter test.

## Global Constraints

- Local-only telemetry; no personal identifiers or network upload.
- Ratings are integers 1–5, retry intent is required, comment is optional and at most 200 trimmed characters.
- Existing schema-1 rows without feedback remain readable.
- Export uses UTF-8 JSON and no Android storage permission.
- Restart/menu actions remain usable if feedback, clipboard, or share operations fail.

---

### Task 1: Feedback model and repository update

**Files:**
- Create: `lib/game/models/run_feedback.dart`
- Modify: `lib/game/models/run_telemetry.dart`
- Modify: `lib/game/systems/telemetry_repository.dart`
- Modify: `test/game/run_telemetry_test.dart`
- Modify: `test/game/telemetry_repository_test.dart`

**Interfaces:**
- Produces: `RunFeedback(funRating, difficultyRating, retryIntent, comment)` with JSON methods.
- Produces: `RunTelemetry.copyWith(feedback:)` and optional `feedback` JSON field.
- Produces: `TelemetryRepository.updateFeedback(runId, feedback) -> Future<bool>`.

- [ ] **Step 1: Write failing feedback model tests**

Assert round trip, ratings outside 1–5 throw `ArgumentError`, comments are trimmed, comments over 200 characters throw, and old telemetry without feedback decodes null.

- [ ] **Step 2: Verify RED**

Run: `flutter test test/game/run_telemetry_test.dart -r expanded`

Expected: compilation fails because `RunFeedback` and the telemetry field do not exist.

- [ ] **Step 3: Implement immutable validated feedback and telemetry copy**

Keep schema version 1 because the nullable field is backward compatible. Serialize feedback only as a JSON object or null.

- [ ] **Step 4: Write failing repository update tests**

Append two runs, update the second by ID, and assert order and first row remain unchanged. Updating an unknown ID returns false and performs no write.

- [ ] **Step 5: Implement update and verify GREEN**

Run both focused test files and expect all tests to pass.

- [ ] **Step 6: Commit**

```powershell
git add lib/game/models lib/game/systems/telemetry_repository.dart test/game
git commit -m "feat: store run playtest feedback"
```

### Task 2: JSON copy and file export service

**Files:**
- Create: `lib/game/systems/telemetry_export_service.dart`
- Create: `test/game/telemetry_export_service_test.dart`
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`

**Interfaces:**
- Produces: `copyRun(runId) -> Future<bool>` and `exportAll() -> Future<bool>`.
- Injects: repository loader, clipboard writer, and JSON-file sharer for deterministic tests.

- [ ] **Step 1: Write failing service tests**

Assert copied JSON decodes to the requested run including feedback, missing run returns false without writing, all-history export uses `run-telemetry.json` and `application/json`, and empty history returns false without sharing.

- [ ] **Step 2: Verify RED**

Run: `flutter test test/game/telemetry_export_service_test.dart -r expanded`

Expected: compilation fails because the service does not exist.

- [ ] **Step 3: Add `share_plus: ^13.2.0` and implement adapters**

Use indented `JsonEncoder.withIndent('  ')`. The default clipboard adapter calls `Clipboard.setData`; the default share adapter sends one in-memory UTF-8 JSON file with `SharePlus.instance.share`.

- [ ] **Step 4: Verify GREEN and commit**

```powershell
git add pubspec.yaml pubspec.lock lib/game/systems/telemetry_export_service.dart test/game/telemetry_export_service_test.dart
git commit -m "feat: export local run telemetry"
```

### Task 3: Result-screen feedback and weapon performance UI

**Files:**
- Modify: `lib/app/run_summary_screen.dart`
- Modify: `test/game/run_summary_progression_test.dart`

**Interfaces:**
- Consumes callbacks: `onFeedbackSubmitted(RunFeedback)`, `onCopyRunJson()`, and `onExportAllJson()` returning `Future<bool>`.
- Produces a saved state and `SnackBar` status without owning storage.

- [ ] **Step 1: Write failing weapon metrics widget test**

Provide levels, damage, and kills for two weapons. Assert each localized name and formatted `Lv`, rounded damage, and kill value appears.

- [ ] **Step 2: Write failing feedback validation/submission test**

Assert submit is disabled initially, choose fun 4, difficulty 3, retry Yes, enter a trimmed comment, submit, and verify the exact `RunFeedback` callback and saved confirmation.

- [ ] **Step 3: Write failing copy/export action test**

Tap each button, assert callbacks fire once, and assert success SnackBars are visible. Add a false-return case for the no-data message.

- [ ] **Step 4: Implement stateful form and metric rows**

Use compact choice chips/segmented controls suitable for the 560px constrained result view. Dispose the comment controller and guard async `setState`/SnackBars with `mounted`.

- [ ] **Step 5: Verify GREEN and commit**

Run: `flutter test test/game/run_summary_progression_test.dart -r expanded`

```powershell
git add lib/app/run_summary_screen.dart test/game/run_summary_progression_test.dart
git commit -m "feat: add result playtest feedback"
```

### Task 4: Game-screen integration, guide, and milestone gate

**Files:**
- Modify: `lib/game/systems/run_telemetry_service.dart`
- Modify: `lib/app/game_screen.dart`
- Modify: `test/game/run_telemetry_service_test.dart`
- Modify: `test/app/game_screen_telemetry_test.dart`
- Modify: `docs/testing/local-playtest.md`
- Create: `docs/testing/playtest-run-log.csv`
- Modify: `docs/master-development-todo.md`

**Interfaces:**
- Changes: `RunTelemetryService.record(...) -> Future<RunTelemetry?>` while preserving failure isolation.
- `GameScreen` wires repository feedback update and export actions for the exact saved `runId`.

- [ ] **Step 1: Write failing service return and screen callback tests**

Assert a successful record returns the exact telemetry and a failure returns null. In the screen test, finish a run and verify the summary receives enabled telemetry actions tied to the recorded run ID.

- [ ] **Step 2: Implement integration and verify focused tests**

If initial telemetry recording returns null, show the summary normally with copy/export feedback actions reporting unavailable instead of throwing.

- [ ] **Step 3: Write tester guide and CSV template**

Document install/setup, fixed 5-minute protocol, local-data notice, feedback questions, JSON export handoff, and anonymous run ID/file naming. CSV columns: tester code, build, device, run ID, outcome, fun, difficulty, retry, notes.

- [ ] **Step 4: Run full gate**

Run: `.\tool\release_check.ps1`

Expected: analysis clean, all tests pass, web release build succeeds.

- [ ] **Step 5: Mark `TEL-008` through `TEL-012` complete and commit**

Advance the next Codex queue to `UX-001`, record the new test count, and commit documentation evidence only after Step 4 succeeds.
