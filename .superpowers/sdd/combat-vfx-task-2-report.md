# Combat VFX Task 2 Report

## Changed files

- `lib/game/combat/combat_vfx_primitives.dart`
  - Added stateless, bounded Canvas VFX primitives and deterministic polar
    samples.
- `test/game/combat_vfx_primitives_test.dart`
  - Added focused tier, cap/determinism, and Canvas invocation coverage.
- `.superpowers/sdd/combat-vfx-task-2-report.md`
  - Recorded implementation and verification evidence.

## Red evidence

Command run before the production module existed:

```text
flutter test test/game/combat_vfx_primitives_test.dart
Exit code: 1
Error when reading 'lib/game/combat/combat_vfx_primitives.dart': specified file was not found
Undefined name 'CombatVfxTier'
Method not found: 'radialSamples'
Undefined name 'CombatVfxPrimitives'
```

This was the expected missing-API failure from the new test.

## Green evidence

```text
flutter test test/game/combat_vfx_primitives_test.dart
Exit code: 0
00:00 +3: All tests passed!

flutter analyze lib/game/combat/combat_vfx_primitives.dart test/game/combat_vfx_primitives_test.dart
Exit code: 0
No issues found!
```

## API summary

- `CombatVfxTier { normal, strong, master }` provides visual-only scale and a
  bounded layer count.
- `CombatVfxPalette` carries the caller-selected core, edge, accent, and smoke
  colours.
- `radialSamples(count:)` returns fixed-index `CombatVfxSample` values capped
  at `CombatVfxPrimitives.maxBurstSamples`.
- `CombatVfxPrimitives` exposes `drawTaperedTrail`, `drawRadialBurst`,
  `drawRuneRing`, `drawCrystal`, `drawChevronLane`, and `drawSmokePuff`.
  Every method accepts caller-owned geometry, palette, normalized progress,
  and a capped decoration count.

## Self-review

- The primitives retain no gameplay state and have no component dependencies.
- Every decoration position is derived from index, supplied geometry, and
  normalized progress; there is no random source.
- All public decoration counts have explicit per-effect caps: 3 trail
  segments, 24 burst samples, 12 runes, 8 crystal facets, 8 chevrons, and 10
  smoke puffs.
- Attack trails and burst bodies are filled `Path` ribbons rather than single
  strokes. Remaining strokes are limited to ring/crystal outlines.
- The implementation contains no `saveLayer`, `MaskFilter`, `ImageFilter`, or
  blur call. It uses only direct Canvas draws and a small fixed set of
  translucent layers.

## Concerns

The focused tests validate determinism, caps, and Canvas invocation but do not
yet provide golden-image coverage. The later presentation-component tasks
should add visual golden or device checks once these primitives are composed
with real attack geometry.
