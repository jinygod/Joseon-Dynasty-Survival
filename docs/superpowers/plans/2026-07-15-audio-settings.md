# Audio Settings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete `AUD-007` with persistent music volume, effect volume, and vibration preferences that update the pause UI immediately and shape future backend playback requests.

**Architecture:** An immutable settings model and `SharedPreferences` repository feed an observable controller. `GameAudioService` reads the latest settings for every typed playback request, while `GameScreen` owns the controller and supplies it to the pause settings page.

**Tech Stack:** Dart 3.12.2, Flutter 3.44.4, `shared_preferences` 2.2.3, `flutter_test`; no audio or haptics package

## Global Constraints

- Defaults are music `0.7`, effects `0.8`, and vibration enabled.
- UI cues use effect volume.
- Volumes are normalized to `0.0..1.0`; non-finite persisted values recover to their field default.
- Settings storage remains separate from progression `SaveState`.
- Storage and diagnostic failures never escape into gameplay or widget callbacks.
- Do not add audio assets, playback packages, platform haptic calls, or non-audio accessibility settings.

---

### Task 1: Settings model and repository

**Files:**
- Create: `lib/game/audio/audio_settings.dart`
- Create: `lib/game/audio/audio_settings_repository.dart`
- Create: `test/game/audio_settings_repository_test.dart`

**Interfaces:**
- Produces `AudioSettings`, `AudioSettings.defaults`, `copyWith`, and `volumeFor(AudioChannel)`.
- Produces `AudioSettingsRepository.load()` and `save(AudioSettings)`.

- [ ] Write failing tests proving exact defaults, copy clamping, valid persistence round-trip, independent missing/invalid recovery, and out-of-range clamping.
- [ ] Run `flutter test test/game/audio_settings_repository_test.dart` and verify RED because the model and repository do not exist.
- [ ] Implement the immutable model with finite-value normalization and channel mapping: music uses `musicVolume`; SFX and UI use `sfxVolume`.
- [ ] Implement repository keys `audio.musicVolume`, `audio.sfxVolume`, and `audio.vibrationEnabled`; load with `getDouble`/`getBool` and save all fields while checking each boolean write result.
- [ ] Run the focused test and verify GREEN.
- [ ] Commit with `git commit -m "feat: persist audio settings"`.

### Task 2: Observable settings controller

**Files:**
- Create: `lib/game/audio/audio_settings_controller.dart`
- Create: `test/game/audio_settings_controller_test.dart`

**Interfaces:**
- Consumes `AudioSettingsRepository`.
- Produces `AudioSettingsController.settings`, `load`, `setMusicVolume`, `setSfxVolume`, and `setVibrationEnabled`.

- [ ] Write failing tests for load notification, immediate optimistic updates, persistence across controller instances, equal-value no-op, load/save failure isolation, and diagnostic callback isolation.
- [ ] Run `flutter test test/game/audio_settings_controller_test.dart` and verify RED because the controller does not exist.
- [ ] Implement a `ChangeNotifier` controller that publishes normalized snapshots before awaiting `save`, reports `AudioSettingsDiagnostic(operation, error, stackTrace)`, and keeps failures contained.
- [ ] Run controller and repository tests and verify GREEN.
- [ ] Commit with `git commit -m "feat: manage observable audio settings"`.

### Task 3: Apply live volume to playback requests

**Files:**
- Modify: `lib/game/audio/audio_playback_policy.dart`
- Modify: `lib/game/audio/game_audio_service.dart`
- Modify: `test/game/audio_playback_policy_test.dart`
- Modify: `test/game/game_audio_service_test.dart`
- Modify: `test/game/silent_audio_backend_test.dart`

**Interfaces:**
- `AudioPlaybackRequest` gains required `double volume`.
- `AudioPlaybackPolicy.requestFor(AudioCue cue, {required double volume})` returns a normalized request.
- `GameAudioService` accepts `AudioSettings Function()? readSettings` and defaults to `AudioSettings.defaults`.

- [ ] Update request fixtures and write failing tests for volume propagation, music-only mute, SFX/UI mute, live setting changes, and muted SFX not advancing pitch.
- [ ] Run all audio tests and verify RED for the missing request volume and settings reader.
- [ ] Add normalized volume to requests and make policy pitch advancement occur only for admitted non-muted requests.
- [ ] Read settings at each service `play`; return before policy request construction when the mapped volume is zero.
- [ ] Run all audio tests and verify GREEN, preserving capacity, priority, lifecycle, and failure tests.
- [ ] Commit with `git commit -m "feat: apply audio volume preferences"`.

### Task 4: Replace the pause settings placeholder

**Files:**
- Modify: `lib/app/pause_menu_overlay.dart`
- Modify: `lib/app/game_screen.dart`
- Modify: `test/app/pause_menu_overlay_test.dart`
- Modify: `test/app/game_screen_pause_test.dart`
- Modify: `test/app/responsive_layout_test.dart`

**Interfaces:**
- `PauseMenuOverlay` requires an `AudioSettingsController settingsController`.
- `GameScreen` accepts optional `AudioSettingsController audioSettingsController` for ownership-safe injection.

- [ ] Write failing widget tests for 70%/80%/enabled defaults, slider updates, vibration toggle, persistence calls, and controller ownership across screen disposal.
- [ ] Run pause and game-screen tests and verify RED for missing controls and constructor parameters.
- [ ] Replace placeholder copy with two ten-division sliders, percentage labels, a switch, and existing back navigation using `ListenableBuilder`.
- [ ] Create/load a controller in `GameScreen`, pass it to the overlay, and dispose it only when internally owned.
- [ ] Update responsive fixtures and verify the settings card remains within supported safe areas.
- [ ] Run affected widget tests and then the complete test suite; verify GREEN.
- [ ] Commit with `git commit -m "feat: add persistent pause audio settings"`.

### Task 5: Release evidence and milestone tracking

**Files:**
- Modify: `docs/master-development-todo.md`
- Modify: `docs/superpowers/plans/2026-07-15-audio-settings.md`

- [ ] Run `powershell -ExecutionPolicy Bypass -File tool/release_check.ps1 -IncludeAndroid`.
- [ ] Confirm formatting unchanged, analysis has no issues, all tests pass, and web plus Android builds succeed.
- [ ] Confirm no audio assets, playback dependency, haptic call, or broader accessibility setting was added.
- [ ] Mark only `AUD-007` complete with exact fresh evidence and advance the independent queue to `AUD-008`.
- [ ] Mark verified plan steps complete and commit with `git commit -m "docs: complete audio settings milestone"`.

### Task 6: Integrate into development mainline

- [ ] Review `master...codex/audio-settings` and confirm only `AUD-007` work is present.
- [ ] Fast-forward merge into local `master` per the standing development preference.
- [ ] Re-run the complete release gate on merged `master`.
- [ ] Update the plan integration checklist, remove the worktree, and delete the merged branch.
