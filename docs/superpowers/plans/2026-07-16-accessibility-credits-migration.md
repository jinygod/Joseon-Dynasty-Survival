# Accessibility, Credits, and Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver META-005, META-006, META-009, and META-010 with accessible state semantics, overflow-safe large text, ledger-backed credits, and save migration regressions.

**Architecture:** Add one reusable status badge and one pure credits ledger model. Integrate them locally into compendium/settings and strengthen responsive layouts without changing app-wide state ownership.

**Tech Stack:** Flutter, Dart, flutter_test, SharedPreferences test fixtures.

## Global Constraints

- Do not modify `docs/master-development-todo.md`, QA, or Android files.
- UI scale 1.15 and system text scale 2.0 must not overflow tested HUD/cards/screens.
- Credits data comes from `docs/assets/asset-rights-ledger.csv` and `docs/assets/audio-rights-ledger.csv`.

---

### Task 1: Accessible status and responsive surfaces

**Files:** Create `lib/app/accessible_status_badge.dart`; modify compendium, records, HUD; test in `test/app/accessibility_surfaces_test.dart`.

- [ ] Write widget tests requiring icon+label+outline states and large-text overflow safety.
- [ ] Run focused tests and observe missing widget/overflow RED.
- [ ] Implement the badge and local Wrap/flexible/constraint changes.
- [ ] Re-run focused tests to GREEN.

### Task 2: Ledger-backed credits

**Files:** Create `lib/app/credits_ledger.dart`, `lib/app/credits_licenses_screen.dart`; modify settings; test `test/app/credits_licenses_screen_test.dart`.

- [ ] Write parser and screen/navigation tests first.
- [ ] Observe RED for missing APIs.
- [ ] Implement CSV parsing, grouped UI, empty state, and settings navigation.
- [ ] Re-run focused tests to GREEN.

### Task 3: Migration matrix

**Files:** Create `test/game/save_migration_regression_test.dart`.

- [ ] Add versionless/v1/v2/v3 save and settings fixtures with generation-appropriate preservation assertions.
- [ ] Observe any missing preservation RED and make only required local save fixes.
- [ ] Run save/settings focused tests to GREEN.

### Task 4: Final gates

- [ ] Format changed Dart files and run `git diff --check`.
- [ ] Run full `dart analyze`, `flutter test --concurrency=1`, and `flutter build web --release`.
- [ ] Commit the verified implementation on `codex/accessibility-credits`.
