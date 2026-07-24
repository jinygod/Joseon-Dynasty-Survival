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
