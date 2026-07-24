# Task 3 — Smooth bounded player camera

## Summary

Added `CombatCameraController` to own dead-zone following, frame-rate-safe
exponential smoothing, visible-world clamping, and final shake composition.
`PixelSurvivorGame` now starts the player and camera at `(1024, 2560)`, sets
the configured `0.90` zoom once in `onLoad`, and bounds player movement by the
runtime world size.

## TDD evidence

### RED

`flutter test --no-pub --no-test-assets test/game/combat_camera_controller_test.dart`
initially failed to compile because
`lib/game/world/combat_camera_controller.dart` did not exist. The expected
missing `CombatCameraController` errors were reported.

The new game settings test also failed before integration: it observed the
existing viewfinder zoom `1.0` while the configured value is `0.90`.

### GREEN

Focused verification passed:

```text
flutter test --no-pub --no-test-assets test/game/combat_camera_controller_test.dart test/game/player_component_test.dart test/game/attack_geometry_test.dart test/game/pixel_survivor_game_settings_test.dart
43 tests passed.
```

Focused analysis passed with no issues:

```text
dart analyze lib/game/world/combat_camera_controller.dart lib/game/pixel_survivor_game.dart lib/game/components/player_component.dart test/game/combat_camera_controller_test.dart test/game/player_component_test.dart test/game/pixel_survivor_game_settings_test.dart
```

## Implementation notes

- Flame 1.37’s documented `CameraComponent.viewport.virtualSize` is used to
  derive visible world size as `virtualSize / viewfinder.zoom`.
- The dead zone treats config dimensions as total dimensions (halves: `9x12`).
- Invalid or negative frame time is treated as zero; positive time is capped at
  `0.05` seconds. Invalid geometry deterministically returns the world center.
- Shake is now calculated as a scalar offset only. The controller smooths and
  clamps the base center, applies bounded shake, clamps again, and writes the
  viewfinder once per normal game update. Disabling shake immediately writes
  the current base without modifying combat coordinates.
- Pure invariance coverage evaluates attack containment, projectile overlap,
  and contact range at two camera centers while verifying world vectors remain
  unchanged.

## Files

- `lib/game/world/combat_camera_controller.dart`
- `lib/game/pixel_survivor_game.dart`
- `test/game/combat_camera_controller_test.dart`
- `test/game/pixel_survivor_game_settings_test.dart`

## Self-review and concerns

No unrelated VFX or Task 2 files were modified. The camera controller uses
the active player as its target only after player creation, avoiding an opening
interpolation. No full suite or build was run, per task scope.

## Reviewer follow-up

### RED

The focused settings test exposed both reported spawn regressions before the
compatibility fix:

- `regular wave spawns around the world-centered player` found no enemy near
  the world-centered player through the ordinary wave-spawn path.
- `debug-requested boss preserves top-of-viewport intent near player` expected
  a `306` world-unit offset from the player, but the viewport-origin boss was
  `2652.386` units away.
- The replacement game-level combat-invariance and actual-camera resize/edge
  cases were added alongside these regressions. The ordinary wave debug hook
  was separately observed RED as an undefined API before implementation.

### Fix

Ordinary wave spawns retain the existing `SpawnRingGeometry` offset but now
anchor it to the nearest mounted, living player, falling back to world center.
Bosses retain the old top-of-viewport offset relative to that same anchor. Both
positions are point-clamped to runtime world bounds. No wave timing, radius,
count, balance, or spatial-planner behavior changed.

The former null-camera invariance test was replaced with a real
`PixelSurvivorGame.camera.viewfinder` test at two distinct centers. It directly
exercises `AttackGeometry.contains`, `ProjectileComponent.overlapsEnemy`, and
`CombatSystem.applyContactDamage`, and verifies actor/projectile world positions
remain fixed. Resize coverage now drives the real tracked target to both world
edges and checks `camera.visibleWorldRect` before and after viewport resize.

### GREEN

The reviewer-focused settings file passed all 7 tests. The complete Task 3
focused command passed all 46 tests, and focused analysis reported no issues.
Because the host C: drive was full, final verification invoked the cached
Flutter tools snapshot and Dart executable directly; the test and analysis
semantics and arguments were unchanged.

### Concerns

The C: drive had zero free bytes during final verification. No user files or
caches were deleted; direct cached tool invocation avoided the Flutter wrapper's
engine-stamp write. No full suite or build was run.

## Projectile culling follow-up

### RED

`projectiles near world-centered player survive viewport culling` mounted a
non-expired, stationary `ProjectileComponent` and
`EnemyProjectileComponent` near `(1024, 2560)`, with collision targets safely
separated, then ran the real game update/resolution path. Against the prior
viewport-sized bounds, the player projectile was removed and its parent became
`null`.

### Fix and GREEN

`_isPositionOutsideBounds` now compares against
`worldConfig.worldBounds` plus the existing `64` world-unit margin. Lifetime,
velocity, collision, population caps, and active-zone behavior are unchanged.
The isolated regression passed after the fix. The full Task 3 focused suite
passed 47 tests, focused analysis reported no issues, and `git diff --check`
passed.
