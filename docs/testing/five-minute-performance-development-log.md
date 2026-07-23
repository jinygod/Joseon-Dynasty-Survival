# Production High-risk Performance Development Log

- Scenario: `pixel-survivor-production-update-five-minute-window`
- Seed: `3107`
- Window: 300.000 simulated seconds
- Frames: 18,000 at a peak simulation step of 16667 microseconds
- Samples: 18,000
- Average / maximum active enemies: 15.68 / 51
- Late raw-frame samples: 7,200 after 180 simulated seconds
- Late average / maximum active enemies: 27.24 / 51
- Late average / minimum logical FPS (fixed-dt): 60.00 / 60.00 (minimum 55)
- Peak host test-loop wall time for `game.update` plus lifecycle processing: 6318 microseconds (not frame or render time)
- Peak mounted Flame components: 262
- Peak retained production owners: 13 (limit 128)
- Peak memory proxy (mounted components + retained owners): 272 (limit 512)
- Population budget result: PASS
- Memory-proxy budget result: PASS
- Late raw-frame budget result: PASS

| Population | Peak | Limit |
| --- | ---: | ---: |
| enemy | 51 | 96 |
| projectile | 14 | 128 |
| damageNumber | 24 | 24 |
| combatEffect | 23 | 32 |

This deterministic fixed-dt host result reports logical FPS only. Host wall time is test-loop update+lifecycle time, not frame or render time, and is not a mobile result. Physical memory and render timing are not measured here. Mounted components plus owners retained by production game collections form a bounded leak/pressure proxy; Chrome profile-mode frame, build, and raster timing require the documented procedure.
