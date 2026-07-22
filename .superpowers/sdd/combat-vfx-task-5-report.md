# Combat VFX Task 5 report

## RED

Focused renderer tests were added before the corresponding presentation work.

```text
flutter test test/game/enemy_combat_overlay_component_test.dart \
  test/game/enemy_hazard_component_test.dart \
  test/game/enemy_projectile_component_test.dart
```

Representative expected failures:

```text
dash warning renders a filled lane with readable chevrons
Expected: > 3000 visible pixels
Actual: 404

ranged warning renders a multi-ring reticle at its locked endpoint
Expected: > 150 visible pixels
Actual: 94

poison, shockwave, and scream hazards have distinct silhouettes
Expected: Set length 3
Actual: Set:[4632]

hostile projectile renders a bright outlined core with a tail
Expected: > 150 visible pixels
Actual: 112
```

The backdrop was separately red-tested before its contrast change:

```text
flutter test test/game/stage_backdrop_component_test.dart
decorative stone lines remain quieter than combat warning lanes
Expected: <= 0.2
Actual: 1.0
```

The `1.0` fallback proves the original component did not expose or enforce a
quiet decorative-line opacity contract.

## GREEN

The required Task 5 suite and directly related gameplay regression tests pass:

```text
flutter test test/game/enemy_combat_overlay_component_test.dart \
  test/game/enemy_hazard_component_test.dart \
  test/game/enemy_projectile_component_test.dart \
  test/game/stage_backdrop_component_test.dart \
  test/game/enemy_component_test.dart \
  test/game/enemy_behavior_controller_test.dart \
  test/game/pixel_survivor_game_loop_test.dart
00:03 +115: All tests passed!
```

Full static analysis also passes:

```text
flutter analyze
No issues found!
```

`git diff --check` exits cleanly.

## Presentation and gameplay preservation

- Dash, dive, double-dash, and thrust warnings now use a translucent bordered
  lane with forward chevrons. The start remains the enemy center and the end
  remains the existing locked `telegraphEndpoint`.
- Ranged warnings retain their locked endpoint and draw three reticle rings
  plus crosshair strokes. Directional shields now add three facing guard plates
  while retaining the existing 90-degree sweep arc and warning priority.
- Poison uses fixed puddle lobes and bubbles; shockwave uses exact-radius rings
  and cracks; scream uses four paired wave bands. Rendering never changes the
  existing `radius`, duration, hit interval, damage, or player containment
  logic.
- Enemy projectiles retain their size, velocity, lifetime, collision, and
  single-hit behavior, but now render a bounded tapered tail, dark outline,
  saturated body, and bright core.
- Stage stone lines are warmer, thinner, and capped at 18% opacity so they do
  not read like a combat telegraph. Stage decoration count, fixed seed, priority,
  and collision-free behavior are unchanged.

## Performance bounds

- Warning lanes request 6 chevrons from the shared primitive (hard-capped at
  8); reticles use exactly 3 rings and shields exactly 3 plates.
- Poison uses at most 7 lobes and 4 bubbles. Shockwaves use 3 rings and 8
  shared radial samples (the primitive caps at 24). Screams use exactly 4
  paired bands.
- Projectile tails use 2 shared trail segments (the primitive caps at 3).
- All local decoration counts are fixed; there is no random sampling, growing
  collection, blur filter, screen flash, camera shake, or gameplay allocation.
  The stage continues to use its isolated fixed seed and maximum 40 details.

## Changed files

- `lib/game/components/enemy_combat_overlay_component.dart`
- `lib/game/components/enemy_hazard_component.dart`
- `lib/game/components/enemy_projectile_component.dart`
- `lib/game/components/stage_backdrop_component.dart`
- `test/game/enemy_combat_overlay_component_test.dart`
- `test/game/enemy_hazard_component_test.dart`
- `test/game/enemy_projectile_component_test.dart`
- `test/game/stage_backdrop_component_test.dart`
- `.superpowers/sdd/combat-vfx-task-5-report.md`

## Self-review

- The warning component remains at `AttackPresentationPriority.warning`; enemy
  bodies and shield-block feedback retain their existing relative priorities.
- Existing enemy controller and game-loop tests prove warning direction,
  endpoint, movement, radius containment, projectile hit/removal, and timing
  remain intact.
- No XP, player HUD, damage, collision, population-limit, or stage gameplay
  code was changed.
- All authored render paths are deterministic and have explicit bounded work.

## Concerns

- The new visual tests intentionally validate raster footprint/silhouette, so
  a future renderer anti-aliasing policy change may require threshold review.
  They complement (rather than replace) the existing exact gameplay geometry
  tests.
- No device golden capture was added in this task; the Canvas work is covered
  by deterministic image tests and the focused game-loop regression suite.
