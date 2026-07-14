# Weapon Balance Baseline Plan

**Goal:** Complete `BAL-002` with deterministic DPS/kill baselines for implemented weapons and usage-rate aggregation from stored run telemetry.

## Scope

- Simulate levels 1–5 for every weapon that has both level data and runtime attack logic.
- Use a documented 60-second continuous-target scenario with fixed target health.
- Aggregate usage rate, observed DPS, and kills per minute from `RunTelemetry` without mutating telemetry schema.
- Report content definitions that lack level/runtime support instead of fabricating results.

## Steps

- [ ] Write RED tests for deterministic baseline rows, usage aggregation, and unsupported weapon reporting.
- [ ] Implement pure baseline simulation and telemetry aggregation.
- [ ] Generate and document the initial baseline table and assumptions.
- [ ] Run focused tests and the full release gate.
- [ ] Mark `BAL-002`, update the queue/baseline, merge, and clean the worktree.
