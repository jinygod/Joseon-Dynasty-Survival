# Audio Voice Policy Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete `AUD-006` with deterministic channel capacity, importance-based admission, and repeat-pitch variation while keeping the backend replaceable.

**Architecture:** A pure policy creates typed playback requests. `GameAudioService` serializes admission decisions, tracks backend playback handles, and applies capacity/preemption rules. The backend remains responsible only for playback mechanics and lifecycle commands.

**Tech Stack:** Dart 3.12.2, Flutter 3.44.4, `flutter_test`; no audio package and no audio files

## Global Constraints

- Do not add audio files or dependencies.
- Do not connect cues to gameplay events.
- Preserve error isolation and idempotent disposal.
- Use deterministic behavior; do not introduce randomness.
- Mark only `AUD-006` complete after the full release gate passes.

---

### Task 1: Define and test the pure playback policy

**Files:**
- Create: `lib/game/audio/audio_playback_policy.dart`
- Create: `test/game/audio_playback_policy_test.dart`

- [x] Write failing tests for total priority mapping, channel limits, pitch cycle, per-cue counters, and fixed music/UI pitch.
- [x] Run the focused test and verify RED because the policy types do not exist.
- [x] Implement `AudioPriority`, cue priority mapping, channel limits, and deterministic request generation.
- [x] Run the focused test and verify GREEN.
- [x] Commit the policy and tests.

### Task 2: Upgrade the backend to playback handles

**Files:**
- Modify: `lib/game/audio/audio_backend.dart`
- Modify: `test/game/silent_audio_backend_test.dart`

- [x] Write a failing test proving silent playback returns a completed stoppable handle.
- [x] Change `AudioBackend.play` to accept `AudioPlaybackRequest` and return `AudioPlaybackHandle`.
- [x] Implement the silent handle without platform bindings.
- [x] Run backend and policy tests and verify GREEN.
- [x] Commit the backend contract change.

### Task 3: Enforce active-voice admission in the service

**Files:**
- Modify: `lib/game/audio/game_audio_service.dart`
- Modify: `test/game/game_audio_service_test.dart`

- [x] Update test backends to the handle contract.
- [x] Write failing tests for completion cleanup, independent limits, equal/lower rejection, higher-priority preemption, oldest-victim selection, concurrent capacity, and stop/completion failure isolation.
- [x] Run service tests and verify RED for missing admission behavior.
- [x] Implement serialized admission, handle tracking, preemption, completion cleanup, and guarded failures.
- [x] Preserve existing delegation, lifecycle ordering, diagnostics, and idempotent disposal tests.
- [x] Run all audio tests and verify GREEN.
- [x] Commit service admission behavior.

### Task 4: Verify and record `AUD-006`

**Files:**
- Modify: `docs/master-development-todo.md`
- Modify: `docs/superpowers/plans/2026-07-15-audio-voice-policy.md`

- [x] Run `powershell -ExecutionPolicy Bypass -File tool/release_check.ps1 -IncludeAndroid`.
- [x] Confirm format is clean, analysis reports no issues, all 227 tests pass, and web plus Android builds succeed.
- [x] Confirm no audio assets, packages, event wiring, settings persistence, or haptics were added.
- [x] Mark only `AUD-006` complete and record exact fresh evidence in the master TODO.
- [x] Mark verified plan steps complete and commit the release evidence.

### Task 5: Integrate into development mainline

- [x] Review the branch diff and confirm it contains only `AUD-006` work.
- [x] Fast-forward merge `codex/audio-voice-policy` into local `master` per the standing development preference.
- [x] Re-run the full release gate on merged `master`.
- [x] Remove the worktree and merged feature branch.
