# Five-minute Performance Development Log

## Automated worst-window evidence

- Scenario: `production-admission-fixed-seed-worst-window`
- Seed: `3107`
- Window: 300.000 simulated seconds
- Frames and samples: 18,000 at a fixed 16,667-microsecond simulation step
- Peak measured harness update cost on the generating host: 3,257 microseconds
- Peak memory proxy: 283 modeled mounted Flame components
- Population budget result: PASS

| Population | Peak | Limit |
| --- | ---: | ---: |
| enemy | 92 | 96 |
| projectile | 128 | 128 |
| damageNumber | 24 | 24 |
| combatEffect | 32 | 32 |

The automated harness runs the production `WaveDirector` and the same `GamePerformanceBudget.admitCount` used by runtime enemy admission. Fixed lifetime queues deliberately keep projectile, damage-number, and combat-effect requests under pressure until their production limits are reached. The test streams all 18,000 observations into the collector; it does not retain a frame-sized object graph.

`peakUpdateCostMicros` is host evidence, not a portable pass threshold. Machine load, test mode, and shader behavior make it non-deterministic. The fixed simulation step, peak populations, budget result, and component-count proxy are the deterministic regression contract. Each focused run also writes JSON and Markdown copies under `build/qa/`.

## Why memory is a proxy

Stable physical RSS or Dart heap readings are unavailable in the headless widget-test process. Garbage-collection timing, engine caches, shader compilation, and host processes can move those readings without a game regression. The automated metric therefore uses persistent owners plus admitted population counts as a mounted-component graph proxy. A rising proxy or a value beyond the population contract blocks the candidate.

## Manual physical-memory procedure

1. Build and install a profile build on the target low-memory Android device: `flutter run --profile`.
2. Open Flutter DevTools Memory and record RSS and Dart heap after a 60-second lobby idle baseline.
3. Start the moonlit office stage with the rookie constable and play through 300 seconds, recording frame timing and memory at 0, 60, 120, 180, 240, 270, and 300 seconds.
4. Return to the lobby, wait 60 seconds, force a Dart GC from DevTools, and record the post-run heap and RSS.
5. Repeat three times from a cold app start. Attach screenshots and exported DevTools data to the candidate record.
6. Block release if any run has sustained frame time above 16.67 ms for five consecutive seconds, Android low-memory termination, an out-of-memory event, or post-run heap that rises by more than 10% on each successive run after forced GC.
