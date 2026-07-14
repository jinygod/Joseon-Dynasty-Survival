# Boss Balance Plan

**Goal:** Complete `BAL-005` by making the first boss durable, readable, and capable of enraging inside the nominal encounter.

## Steps

- [x] Write RED tests for health, telegraph windows, attack cycle, and enrage timing.
- [x] Tune boss health, charge warning, enrage time, and enrage multiplier.
- [x] Document the boss timing baseline and rationale.
- [x] Run focused tests and the full release gate.
- [x] Mark `BAL-005`, update the queue/baseline, merge, and clean the worktree.

## Verification

- Focused boss suite: 6 tests passed.
- Full release gate: analyzer clean, 165 tests passed, web build passed, Android debug APK built.
