# Multi-seed Five-minute Regression Plan

**Goal:** Complete `BAL-008` by expanding the one-seed boundary check into a deterministic multi-seed wave simulation with invariant reporting.

## Steps

- [x] Write RED tests for 20 seeds, deterministic replay, seed diversity, phase pools, caps, boss count, and elite pressure.
- [x] Implement a pure five-minute wave regression simulator.
- [x] Document simulation assumptions and baseline invariants.
- [x] Run focused tests and the full release gate.
- [x] Mark `BAL-008`, update baseline/queue, merge, and clean the worktree.

## Verification

- Focused wave/run regression suite: 7 tests passed.
- Full release gate: analyzer clean, 172 tests passed, web build passed, Android debug APK built.
