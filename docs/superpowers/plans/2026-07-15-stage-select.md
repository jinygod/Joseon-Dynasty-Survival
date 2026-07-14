# Stage Select Implementation Plan

**Goal:** Complete `UX-007` with one selectable stage and explicit five-minute progression information.

### Task 1: Stage content and screen

- [ ] Write RED screen tests for title, duration, boss timing, victory condition, and launch selection.
- [ ] Add stage content definitions and `StageSelectScreen`.
- [ ] Verify focused tests and commit.

### Task 2: Navigation and continuity

- [ ] Write RED flow tests for character → stage → game and restart stage continuity.
- [ ] Route character selection through stage selection.
- [ ] Add `stageId` to GameScreen and preserve it across restart/retry.
- [ ] Verify focused tests and commit.

### Task 3: Release gate

- [ ] Run analysis, all tests, web build, and Android APK build.
- [ ] Mark `UX-007`, update baseline/queue, merge to master, and clean worktree.

