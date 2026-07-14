# Run Telemetry Model Implementation Plan

**Goal:** Define the versioned local `RunTelemetry` JSON contract that later playtest recording tasks can safely extend.

**Architecture:** Keep telemetry separate from progression saves. A pure Dart model owns schema version 1 and serializes the run identity, app version, UTC timestamps, outcome, survival duration, level, kills, boss result, and per-weapon kill counts. Storage and game wiring remain later TODOs.

**Tech Stack:** Dart, Flutter test.

---

### Task 1: Define and test schema version 1

**Files:**
- Create: `lib/game/models/run_telemetry.dart`
- Create: `test/game/run_telemetry_test.dart`
- Create: `docs/telemetry/run-telemetry-schema.md`
- Modify: `docs/master-development-todo.md`

1. Add a failing JSON round-trip test with non-empty weapon kill counts and UTC timestamps.
2. Add a failing test that rejects a future schema version.
3. Implement the immutable model, explicit enum encoding, UTC timestamp encoding, and typed map decoding.
4. Document every schema 1 field and compatibility rule.
5. Run the focused tests, then the complete release gate.
6. Mark only `TEL-001` complete with test and documentation evidence.
