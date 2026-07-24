# Production High-risk Performance Development Log

- Scenario: `pixel-survivor-production-update-five-minute-window`
- Seed: `3107`
- Window: 300.000 simulated seconds
- Frames: 18,000 at a peak simulation step of 16667 microseconds
- Samples: 18,000
- Average / maximum active enemies: 26.66 / 86
- Late raw-frame samples: 7,200 after 180 simulated seconds
- Late average / maximum active enemies: 49.44 / 86
- Late average / minimum logical FPS (fixed-dt): 60.00 / 60.00 (minimum 55)
- Peak host test-loop wall time for `game.update` plus lifecycle processing: 10041 microseconds (not frame or render time)
- Peak mounted Flame components: 363
- Peak retained production owners: 30 (limit 128)
- Peak memory proxy (mounted components + retained owners): 383 (limit 512)
- Population budget result: PASS
- Memory-proxy budget result: PASS
- Late raw-frame budget result: PASS

| Population | Peak | Limit |
| --- | ---: | ---: |
| enemy | 86 | 96 |
| projectile | 19 | 128 |
| damageNumber | 24 | 24 |
| combatEffect | 27 | 32 |

## Fixed-seed comparison

| Metric | Previous single-screen runtime | Finite-world runtime |
| --- | ---: | ---: |
| Average / maximum active enemies | 15.68 / 51 | 26.66 / 86 |
| Late average / maximum active enemies | 27.24 / 51 | 49.44 / 86 |
| Peak mounted components | 263 | 363 |
| Peak retained owners | 16 | 30 |
| Peak memory proxy | 275 | 383 |
| Budget violation samples | 0 | 0 |

The finite-world scenario deliberately sustains more nearby enemies than the
previous single-screen runtime. Sleeping enemies are stored as lightweight
records and do not contribute mounted Flame components. Sleep intentionally
preserves identity, position, health fraction, rank, and deterministic state
seed; transient slow, aura, attachment, and in-progress behavior phases restart
when the enemy is restored. Offscreen active
enemies release their shadow and warning-overlay components, and the
experience-gem synchronizer prevents duplicate pending mounts while enforcing
the configured 96-component active cap.

This deterministic fixed-dt host result reports logical FPS only. Host wall time is test-loop update+lifecycle time, not frame or render time, and is not a mobile result. Physical memory and render timing are not measured here. Mounted components plus owners retained by production game collections form a bounded leak/pressure proxy; Chrome profile-mode frame, build, and raster timing require the documented procedure.
