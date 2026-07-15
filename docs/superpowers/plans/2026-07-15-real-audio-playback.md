# Real Audio Playback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add replaceable temporary music and sound effects that play in Chrome and Android and respond to existing volume settings.

**Architecture:** A total `AudioAssetCatalog` maps every typed cue to a local asset. `FlameAudioBackend` adapts Flame players to the existing backend contract, while one app-owned `GameAudioService` is injected into screens and a cue callback bridges deterministic game events to audio.

**Tech Stack:** Flutter 3.41, Flame 1.x, `flame_audio` 2.12.1, Kenney CC0 WAV/OGG assets, Flutter tests.

## Global Constraints

- Temporary sounds must be centrally replaceable without gameplay changes.
- Chrome playback starts from a user gesture and must not depend on forbidden autoplay.
- Persisted music/effects volumes remain authoritative.
- Every imported file has source and license evidence.
- Work is merged locally into `master` after the full Web and Android gate passes.

---

### Task 1: Total audio asset catalog and licensed temporary files

**Files:**
- Create: `lib/game/audio/audio_asset_catalog.dart`
- Create: `test/game/audio_asset_catalog_test.dart`
- Create: `assets/audio/music/*.ogg`
- Create: `assets/audio/sfx/*.ogg`
- Create: `assets/audio/ui/*.ogg`
- Create: `docs/assets/audio-rights-ledger.csv`
- Modify: `pubspec.yaml`

**Interfaces:**
- Produces: `AudioAssetDefinition AudioAssetCatalog.forCue(AudioCue cue)` and `AudioAssetCatalog.assets`.

- [ ] **Step 1: Write the failing catalog test** asserting all `AudioCue.values` have a non-empty unique-or-intentionally-shared path below `audio/`, correct loop metadata, and a corresponding asset file.
- [ ] **Step 2: Run** `flutter test test/game/audio_asset_catalog_test.dart` and confirm failure because the catalog is absent.
- [ ] **Step 3: Add** immutable `AudioAssetDefinition(path, loop)` and an exhaustive switch mapping all 17 cues.
- [ ] **Step 4: Download the approved Kenney CC0 packs, select light temporary clips, copy only selected files, and record every local file in the rights ledger.
- [ ] **Step 5: Register `assets/audio/` and `flame_audio: ^2.12.1` in `pubspec.yaml`, run `flutter pub get`, then rerun the catalog test to green.
- [ ] **Step 6: Commit** with `feat: add replaceable licensed audio catalog`.

### Task 2: Production Flame backend

**Files:**
- Create: `lib/game/audio/flame_audio_backend.dart`
- Create: `test/game/flame_audio_backend_test.dart`
- Modify: `lib/game/audio/game_audio_service.dart`
- Modify: `test/game/game_audio_service_test.dart`

**Interfaces:**
- Consumes: `AudioAssetCatalog.forCue`.
- Produces: `FlameAudioBackend({AudioPlayerAdapter? adapter})` implementing `AudioBackend`.

- [ ] **Step 1: Write failing tests** for cue path/volume/pitch forwarding, looped music, stopping replacement music, pause/resume of active voices, completion cleanup, and idempotent disposal.
- [ ] **Step 2: Run** `flutter test test/game/flame_audio_backend_test.dart test/game/game_audio_service_test.dart` and confirm expected missing-type/behavior failures.
- [ ] **Step 3: Implement** a small injectable player adapter around `FlameAudio.play`/`loop`; wrap stop and completion in `AudioPlaybackHandle`.
- [ ] **Step 4: Change music admission** so a new music cue stops the old music voice and replaces it even at equal priority.
- [ ] **Step 5: Rerun both test files to green and commit** with `feat: implement Flame audio playback backend`.

### Task 3: Weapon and combat cue emission

**Files:**
- Modify: `lib/game/systems/weapon_system.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `test/game/weapon_system_test.dart`
- Modify: `test/game/pixel_survivor_game_loop_test.dart`

**Interfaces:**
- Produces: `WeaponTickResult.firedWeaponIds` and `PixelSurvivorGame(onAudioCue: void Function(AudioCue)?)`.

- [ ] **Step 1: Write failing weapon tests** proving each fired weapon ID is reported once per actual cooldown trigger and never when no attack occurs.
- [ ] **Step 2: Run the focused weapon test** and confirm `firedWeaponIds` is missing.
- [ ] **Step 3: Add fired IDs to `WeaponTickResult`** and append them only at each successful attack creation/damage event.
- [ ] **Step 4: Write failing game tests** for weapon mappings plus critical hit, death, pickup, level-up, boss warning/music, player hit, and outcome cues.
- [ ] **Step 5: Run focused game tests** and confirm cue assertions fail.
- [ ] **Step 6: Add the optional cue callback** and emit cues at the already-authoritative gameplay event sites, avoiding render-frame polling.
- [ ] **Step 7: Rerun focused tests to green and commit** with `feat: connect combat events to audio cues`.

### Task 4: App ownership, UI navigation, and lifecycle

**Files:**
- Modify: `lib/app/pixel_survivor_app.dart`
- Modify: `lib/app/main_menu_screen.dart`
- Modify: `lib/app/character_select_screen.dart`
- Modify: `lib/app/stage_select_screen.dart`
- Modify: `lib/app/game_screen.dart`
- Modify: `lib/app/run_summary_screen.dart`
- Modify: relevant `test/app/*_test.dart` and `test/main_menu_screen_test.dart`

**Interfaces:**
- Consumes: one `GameAudioService` and `AudioSettingsController` owned by `PixelSurvivorApp`.

- [ ] **Step 1: Write failing widget tests** showing the first start tap emits UI confirm before battle music, pause/background lifecycle forwards pause/resume policy, result music matches outcome, and retry/menu actions emit UI cues.
- [ ] **Step 2: Run focused widget tests** and confirm missing injection/calls.
- [ ] **Step 3: Convert `PixelSurvivorApp` to stateful ownership**, load settings once, construct `FlameAudioBackend`, and dispose service/controller once.
- [ ] **Step 4: Pass the service through navigation**, connect UI buttons, connect game callbacks, and preserve injected-test ownership rules.
- [ ] **Step 5: Rerun focused tests to green and commit** with `feat: wire app audio lifecycle and navigation`.

### Task 5: Release verification, documentation, and merge

**Files:**
- Modify: `docs/master-development-todo.md`
- Modify: `docs/testing/local-playtest.md`

**Interfaces:**
- Produces: an audibly testable Web release and merged `master`.

- [ ] **Step 1: Run** `dart format --output=none --set-exit-if-changed lib test`.
- [ ] **Step 2: Run** `flutter analyze` and require zero issues.
- [ ] **Step 3: Run** `flutter test` and require zero failures.
- [ ] **Step 4: Run** `flutter build web --release` and `flutter build apk --debug`.
- [ ] **Step 5: Update AUD-002 through AUD-005 and local playtest guidance** with exact results and Chrome gesture behavior.
- [ ] **Step 6: Commit documentation, fast-forward merge into `master`, rerun the full release gate on `master`, and remove the feature worktree/branch.
- [ ] **Step 7: Refresh the static Chrome build** and hand off the audible test path: click start, hear confirm/battle music, attack, collect XP, pause/resume, and reach result music.
