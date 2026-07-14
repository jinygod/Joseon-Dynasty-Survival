# Regular Enemy Balance Plan

**Goal:** Complete `BAL-004` by tuning the learning enemy and locking health, damage, speed, and active-cap safety constraints to production data.

## Steps

- [x] Write RED tests for one-hit learning fodder, starter-weapon time to kill, contact survival, movement speed, and wave caps.
- [x] Reduce plague-rat health to one starter hit and implement a pure enemy-pressure analyzer.
- [x] Document initial enemy-role and wave-pressure baselines.
- [x] Run focused tests and the full release gate.
- [x] Mark `BAL-004`, update the queue/baseline, merge, and clean the worktree.

## Verification

- Focused enemy/content suite: 14 tests passed.
- Full release gate: analyzer clean, 162 tests passed, web build passed, Android debug APK built.
