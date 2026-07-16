# Settings Accessibility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist and apply six accessibility settings while safely resetting meta progress without deleting settings.

**Architecture:** A versioned `GameSettings` value and repository replace fragmented persistence while compatibility aliases preserve audio callers. The settings screen mutates one controller; game runtime reads the same controller for feedback flags and HUD scale. Progress reset writes only `SaveState.defaults()` through a separately injected `SaveStore`.

**Tech Stack:** Flutter, Dart, Flame, SharedPreferences, flutter_test

## Global Constraints

- Do not modify boss or unlock definitions/services.
- Do not modify `docs/master-development-todo.md`.
- Preserve existing audio API and legacy preference keys.
- Use test-first RED then minimal GREEN for every behavior.

---

### Task 1: Unified settings value and persistence

**Files:**
- Create: `lib/app/game_settings.dart`
- Create: `lib/app/game_settings_repository.dart`
- Modify: `lib/game/audio/audio_settings.dart`
- Modify: `lib/game/audio/audio_settings_repository.dart`
- Test: `test/app/game_settings_repository_test.dart`

**Interfaces:**
- Produces: `GameSettings`, `UiScale`, `GameSettingsStore.load/save`, and compatibility `AudioSettings`/`AudioSettingsStore` names.

- [ ] Write tests for normalization, legacy-key migration, unified JSON precedence, persistence, and a second repository instance restoring all six values.
- [ ] Run `flutter test test/app/game_settings_repository_test.dart` through an ASCII mapped path and confirm missing-type failures.
- [ ] Implement the minimum immutable value and repository, with legacy aliases/wrappers.
- [ ] Re-run the focused test and existing audio repository tests until green.

### Task 2: Unified controller and settings screen

**Files:**
- Create: `lib/app/game_settings_controller.dart`
- Modify: `lib/game/audio/audio_settings_controller.dart`
- Modify: `lib/app/settings_screen.dart`
- Test: `test/app/settings_screen_test.dart`
- Test: `test/app/game_settings_controller_test.dart`

**Interfaces:**
- Consumes: `GameSettingsStore`, `SaveStore`.
- Produces: setters for all six settings and a screen whose reset action writes `SaveState.defaults()` only after two confirmations.

- [ ] Write controller tests for load/save ordering and widget tests for sliders, toggles, UI size, first/second cancellation, confirmation, and settings preservation.
- [ ] Run focused tests and confirm compile/expectation failures caused by missing behavior.
- [ ] Implement the controller compatibility layer and accessible settings UI with injected progress store.
- [ ] Re-run focused and existing audio controller tests until green.

### Task 3: Runtime display settings

**Files:**
- Modify: `lib/app/game_screen.dart`
- Modify: `lib/app/game_hud.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Test: `test/app/game_hud_settings_test.dart`
- Test: `test/game/pixel_survivor_game_settings_test.dart`

**Interfaces:**
- Consumes: `GameSettingsController.settings`.
- Produces: mutable `screenShakeEnabled` and `damageNumbersEnabled` game flags plus `GameHud.uiScale`.

- [ ] Write tests proving disabled flags suppress new shake/damage-number feedback and HUD scale changes its rendered transform.
- [ ] Run focused tests and confirm failures for missing parameters/properties.
- [ ] Add only the runtime guards and listener wiring needed to satisfy the tests.
- [ ] Re-run focused tests and relevant game/HUD regressions until green.

### Task 4: Verification and handoff

**Files:**
- Create: `docs/superpowers/verification/2026-07-16-settings-accessibility.md`

- [ ] Run formatting, `dart analyze`, all `flutter test`, and `flutter build web` from the ASCII path workaround.
- [ ] Record exact commands, exit codes, and any environment limitations in the verification note.
- [ ] Review `git diff`, confirm forbidden files are untouched, and commit the complete branch.
