# Combat Rhythm Log Plan

**Goal:** Complete `BAL-001` by defining one tested timeline and one stable snapshot format that every balance simulation can reuse.

## Design

- Divide the run into learning (0–60), build (60–180), pressure (180–270), and boss (270–330) phases.
- Keep phase definitions independent from Flutter and Flame so deterministic simulations can consume them.
- Record 15-second snapshots with enemy pressure, player progression, damage, kills, weapon output, and boss state.
- Use stable phase IDs and JSON field names so results can be compared across balance revisions.

## Steps

- [ ] Write RED tests for exact phase boundaries, contiguous coverage, validation, and JSON output.
- [ ] Implement combat rhythm phase definitions and snapshot serialization.
- [ ] Document sampling rules, metrics, and pass/fail interpretation for later balance tasks.
- [ ] Run focused tests and the full release gate.
- [ ] Mark `BAL-001`, update the queue/baseline, merge, and clean the worktree.
