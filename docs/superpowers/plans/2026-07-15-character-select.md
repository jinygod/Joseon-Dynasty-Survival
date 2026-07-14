# Character Select Implementation Plan

**Goal:** Complete `UX-006` with save-backed character cards and selected-character run launch.

### Task 1: Character selection presentation

- [ ] Write RED tests for locked default state, unlocked selection, and exact launch slot.
- [ ] Implement `CharacterSelectScreen` with injected `SaveSystem` and callbacks.
- [ ] Verify focused tests and commit.

### Task 2: Navigation and run-slot continuity

- [ ] Write RED menu and GameScreen tests for selection navigation and slot use.
- [ ] Route MainMenu through character selection.
- [ ] Add `playerSlot` to GameScreen and preserve it across restart/retry.
- [ ] Verify focused tests and commit.

### Task 3: Release gate and milestone

- [ ] Run static analysis, all tests, web build, and Android APK build.
- [ ] Mark `UX-006`, update baseline and next queue.
- [ ] Merge verified work to master and clean the worktree.

