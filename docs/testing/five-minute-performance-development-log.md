# Five-minute Production Performance Development Log

- Scenario: `pixel-survivor-production-update-five-minute-window`
- Seed: `3107`
- Runtime: actual mounted `PixelSurvivorGame` production update, spawn, combat,
  collision, and component lifecycle paths
- Window: 300 simulated seconds / 18,000 updates at 1/60 second
- Observation interval: every frame (18,000 samples)
- Visual assets: production-injected fallback; game logic unchanged
- Average active enemies: 13.48
- Maximum active enemies: 42 / 96
- Late raw-frame window: 180-300 seconds (7,200 samples)
- Late average / minimum simulated FPS: 60.00 / 60.00 (minimum 55)
- Peak host test-loop wall time for update plus lifecycle: 6,757 microseconds
- Peak mounted Flame components: 216
- Peak retained production owners: 15
- Peak memory proxy: 229 / 512
- Retained-owner limit: 128
- Population, memory-proxy, and late-frame result: PASS (zero violation
  samples)

| Population | Peak | Limit |
| --- | ---: | ---: |
| enemy | 42 | 96 |
| projectile | 12 | 128 |
| damageNumber | 24 | 24 |
| combatEffect | 21 | 32 |

This deterministic host test does not claim device frame time, RSS, or heap
measurements. Its wall-clock label is limited to the host test loop, while
mounted components plus owners retained by production collections are the
bounded leak/pressure proxy. Simulated FPS is derived from each raw frame
duration before the game clamps combat `dt`; it is not a device rendering FPS
claim. The test also caps experience-gem components at 128 and merges excess
experience into an existing gem without losing rewards.
