# Stage Select Implementation Plan

**Goal:** Complete `UX-007` with one selectable stage and explicit five-minute progression information.

### Task 1: Stage content and screen

- [x] Write RED screen tests for title, duration, boss timing, victory condition, and launch selection.
- [x] Add stage content definitions and `StageSelectScreen`.
- [x] Verify focused tests and commit.

### Task 2: Navigation and continuity

- [x] Write RED flow tests for character → stage → game and restart stage continuity.
- [x] Route character selection through stage selection.
- [x] Add `stageId` to GameScreen and preserve it across restart/retry.
- [x] Verify focused tests and commit.

### Task 3: Release gate

- [x] Run analysis, all tests, web build, and Android APK build.
- [x] Mark `UX-007`, update baseline/queue, merge to master, and clean worktree.
