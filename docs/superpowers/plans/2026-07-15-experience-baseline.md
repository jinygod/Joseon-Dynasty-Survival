# Experience Progression Baseline Plan

**Goal:** Complete `BAL-003` by validating the current experience curve against the five-minute wave economy and the 8–12 level-up target.

## Design

- Derive expected spawned experience from wave rates, enemy weights, and elite multipliers for seconds 0–299.
- Model beginner, expected, and strong effective acquisition rates without pretending every spawned enemy is killed and collected.
- Feed integer earned experience through the production `RunProgressionSystem`.
- Fail regression tests if the average exits 8–12 level-ups or the curve stops increasing monotonically.

## Steps

- [ ] Write RED tests for curve totals, deterministic profile results, and the target band.
- [ ] Implement the pure five-minute experience simulator.
- [ ] Document assumptions and the initial baseline.
- [ ] Run focused tests and the full release gate.
- [ ] Mark `BAL-003`, update the queue/baseline, merge, and clean the worktree.
