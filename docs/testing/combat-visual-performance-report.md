# Combat Visual Performance Report

## Measurement scope

- Measured at commit `290d3166d36c28eebe600faa27be4376a344fe54`.
- Host: Windows 10 Home 10.0.19045, Intel Core i7-10700KF
  (16 logical processors), 15.9 GB RAM.
- Flutter 3.44.4 stable, Dart 3.12.2.
- Deterministic scenario seed: `3107`.
- Host window: 300 simulated seconds, 18,000 fixed-dt logical frames.
- Chrome 150.0.7871.129 is installed, but the app has no supported seed-3107
  launch hook or normalized profile exporter.

The host result is a test-loop measurement of `game.update` plus Flame
lifecycle processing. It is not device FPS, Chrome frame timing, build time,
raster time, GPU time, or a mobile result.

## Before and after

| Metric | Baseline | Current | Interpretation |
| --- | ---: | ---: | --- |
| Host update+lifecycle peak | 6,318 us | 8,126 us | Single-run peak; not render/frame timing and not suitable for a device-FPS claim |
| Average / maximum enemies | 15.68 / 51 | 15.68 / 51 | Deterministic workload preserved |
| Late average / maximum enemies | 27.24 / 51 | 27.24 / 51 | Late workload preserved |
| Logical fixed-dt FPS | 60.00 | 60.00 | Simulation input rate, not rendered FPS |
| Peak mounted components | 262 | 263 | Within the 512 memory-proxy envelope |
| Peak retained owners | 13 | 16 | Complete accounting now includes talisman attachments and tracked registry VFX |
| Peak memory proxy | 272 | 275 | PASS, limit 512 |
| Enemy peak / limit | 51 / 96 | 51 / 96 | PASS |
| Projectile peak / limit | 14 / 128 | 14 / 128 | PASS |
| Damage-number peak / limit | 24 / 24 | 24 / 24 | PASS |
| Combat-effect peak / limit | 23 / 32 | 23 / 32 | PASS |

The higher retained-owner value is primarily an accounting correction: the
previous scalar omitted two live owner collections. The single host-wall-time
peak also varies with desktop scheduling and must not be read as an 28.6%
render regression.

## Chrome profile evidence

Status: **not measured**.

Reason: `seed injection and profile instrumentation unavailable`.

Run-specific evidence:
`build/qa/combat-visual-profile/2026-07-24T061240-seed3107/chrome-frame-profile-not-measured.json`.

Accordingly, frame/build/raster p50, p95, p99, strict frame counts above 33 ms
and 50 ms, first-image timestamps, and component create/remove rates are all
`not measured`. No values were estimated from host logical timing.

## Optimization decision

No spatial partition was added.

There is no measured Chrome p95/p99 hot section attributing time to
projectile-enemy collision traversal or aura traversal. The deterministic host
run remains within every population and memory-proxy budget, and its workload
counts are unchanged. Per the decision rule, collision/aura architecture stays
simple until a supported profile exporter produces evidence that one of those
paths dominates a measured tail.

The completed optimizations remain justified independently: combat population
admission counts are indexed, root-wide enemy counting is narrowed to an
enemy-only identity view, retained owner accounting is complete, the scalar
sampler performs no map allocation, stage art is batched, and authored VFX
sprites are cached at construction.
