# Production High-risk Performance Development Log

- Scenario: `pixel-survivor-production-update-five-minute-window`
- Seed: `3107`
- Window: 300.000 simulated seconds
- Frames: 18,000 at a peak simulation step of 16667 microseconds
- Samples: 18,000
- Average / maximum active enemies: 13.66 / 45
- Late raw-frame samples: 7,200 after 180 simulated seconds
- Late average / maximum active enemies: 23.77 / 45
- Late average / minimum simulated FPS: 60.00 / 60.00 (minimum 55)
- Peak host test-loop wall time for `game.update` plus lifecycle processing: 8249 microseconds
- Peak mounted Flame components: 253
- Peak retained production owners: 14 (limit 128)
- Peak memory proxy (mounted components + retained owners): 263 (limit 512)
- Population budget result: PASS
- Memory-proxy budget result: PASS
- Late raw-frame budget result: PASS

| Population | Peak | Limit |
| --- | ---: | ---: |
| enemy | 45 | 96 |
| projectile | 14 | 128 |
| damageNumber | 20 | 24 |
| combatEffect | 17 | 32 |

Physical memory and device frame time are not measured by this deterministic host test. Mounted components plus owners retained by production game collections form a bounded leak/pressure proxy; profile-mode RSS, heap, and raster timing require the documented manual device procedure.
