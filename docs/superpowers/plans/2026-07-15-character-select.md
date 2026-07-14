# Character Select Implementation Plan

**Goal:** Complete `UX-006` with save-backed character cards and selected-character run launch.

### Task 1: Character selection presentation

- [x] Write RED tests for locked default state, unlocked selection, and exact launch slot.
- [x] Implement `CharacterSelectScreen` with injected `SaveSystem` and callbacks.
- [x] Verify focused tests and commit.

### Task 2: Navigation and run-slot continuity

- [x] Write RED menu and GameScreen tests for selection navigation and slot use.
- [x] Route MainMenu through character selection.
- [x] Add `playerSlot` to GameScreen and preserve it across restart/retry.
- [x] Verify focused tests and commit.

### Task 3: Release gate and milestone

- [x] Run static analysis, all tests, web build, and Android APK build.
- [x] Mark `UX-006`, update baseline and next queue.
- [x] Merge verified work to master and clean the worktree.
