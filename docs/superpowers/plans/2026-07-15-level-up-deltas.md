# Level-up Delta Plan

**Goal:** Complete `BAL-007` by showing production-derived current-to-next values for every selectable upgrade and excluding content without runtime effects.

## Steps

- [x] Write RED tests for weapon stat deltas, cumulative augment deltas, and unsupported-content filtering.
- [x] Implement delta formatting from production level data and runtime multipliers.
- [x] Update card tests and document supported choice behavior.
- [x] Run focused tests and the full release gate.
- [x] Mark `BAL-007`, update baseline/queue, merge, and clean the worktree.

## Verification

- Focused level-up/game suite: 24 tests passed.
- Full release gate: analyzer clean, 170 tests passed, web build passed, Android debug APK built.
