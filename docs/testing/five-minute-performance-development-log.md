# Five-minute Production Performance Development Log

- Scenario: `pixel-survivor-production-update-five-minute-window`
- Seed: `3107`
- Runtime: actual mounted `PixelSurvivorGame` production update, spawn, combat,
  collision, and component lifecycle paths
- Window: 300 simulated seconds / 18,000 updates at 1/60 second
- Observation interval: every frame (18,000 samples)
- Visual assets: production-injected fallback; game logic unchanged
- Peak host test-loop wall time for update plus lifecycle: 7,859 microseconds
- Peak mounted Flame components: 211
- Peak retained production owners: 17
- Peak memory proxy: 226 / 512
- Retained-owner limit: 128
- Population and memory-proxy result: PASS (zero violation samples)

| Population | Peak | Limit |
| --- | ---: | ---: |
| enemy | 34 | 96 |
| projectile | 6 | 128 |
| damageNumber | 24 | 24 |
| combatEffect | 18 | 32 |

This deterministic host test does not claim device frame time, RSS, or heap
measurements. Its wall-clock label is limited to the host test loop, while
mounted components plus owners retained by production collections are the
bounded leak/pressure proxy. The test also caps experience-gem components at
128 and merges excess experience into an existing gem without losing rewards.
