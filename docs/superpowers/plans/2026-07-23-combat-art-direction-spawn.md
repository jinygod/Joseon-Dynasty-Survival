# Combat Art, Facing, and Spawn Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace prominent combat placeholders while making enemy facing and
spawn direction natural across the full playfield.

**Architecture:** Keep simulation geometry unchanged and add raster
presentation at the component boundary. Put rectangular perimeter math in a
small pure helper, mirror enemy rendering from existing facing state, and load
generated images through the existing cached Flame image path.

**Tech Stack:** Flutter, Flame, Dart canvas rendering, PNG assets, Flutter test

## Global Constraints

- Do not copy commercial game assets, UI, characters, or exact effects.
- Damage geometry, timing, and balance remain unchanged.
- Generated image assets must be recorded in the asset-rights ledger.
- Visual asset failure must retain a functional fallback.

---

### Task 1: Full-perimeter spawn geometry

**Files:**
- Create: `lib/game/systems/spawn_ring_geometry.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Test: `test/game/spawn_ring_geometry_test.dart`

**Interfaces:**
- Produces: `SpawnRingGeometry.offsetForAngle(Vector2 viewport, double angle,
  {double margin = 24}) -> Vector2`

- [ ] Write tests asserting diagonal angles have two non-zero coordinates,
  cardinal angles remain outside the rectangle, and every sampled angle lies
  on the expanded perimeter.
- [ ] Run `flutter test test/game/spawn_ring_geometry_test.dart` and confirm it
  fails because the helper does not exist.
- [ ] Implement ray/rectangle intersection and select a random angle for each
  regular spawn.
- [ ] Re-run the focused test and confirm it passes.

### Task 2: Enemy horizontal facing

**Files:**
- Modify: `lib/game/components/enemy_component.dart`
- Test: `test/game/enemy_component_test.dart`

**Interfaces:**
- Produces: `EnemyComponent.facesLeft` and mirrored sprite rendering.

- [ ] Add a test that calls `debugFace` with positive and negative horizontal
  vectors and asserts `facesLeft` changes.
- [ ] Run the focused test and confirm it fails because `facesLeft` is absent.
- [ ] Add the getter and mirror the render canvas around the component center
  before drawing the sprite.
- [ ] Re-run the focused test and confirm it passes.

### Task 3: Generated hwando and courtyard assets

**Files:**
- Create: `assets/images/effects/hwando_slash_ribbon_hd.png`
- Create: `assets/images/stages/joseon_courtyard_ground_tile_hd.png`
- Create: `docs/assets/prompts/combat-art-refresh.md`
- Modify: `docs/assets/asset-rights-ledger.csv`
- Modify: `lib/game/content/asset_catalog.dart`
- Test: `test/game/asset_catalog_test.dart`

**Interfaces:**
- Produces asset keys `hwando_slash_ribbon_hd` and
  `joseon_courtyard_ground_tile_hd`.

- [ ] Add failing catalog assertions for both runtime paths.
- [ ] Generate original raster assets from the provided quality references,
  remove the slash chroma key, and inspect the outputs.
- [ ] Register the paths and rights evidence.
- [ ] Re-run the catalog test and confirm it passes.

### Task 4: Raster-backed combat presentation

**Files:**
- Modify: `lib/game/components/attack_effect_component.dart`
- Modify: `lib/game/components/stage_backdrop_component.dart`
- Test: `test/game/attack_effect_component_test.dart`
- Test: `test/game/stage_backdrop_component_test.dart`

**Interfaces:**
- Consumes the two catalog assets from Task 3.
- Produces cached optional images and deterministic destination rectangles
  derived from existing attack and viewport geometry.

- [ ] Add tests for hwando raster eligibility and bounded stage tile counts.
- [ ] Run focused tests and confirm they fail for the missing presentation API.
- [ ] Load images once through Flame's image cache, render the hwando ribbon
  using frozen heading/range, and repeat the ground tile across the viewport.
- [ ] Re-run focused tests and confirm they pass.

### Task 5: Verification and delivery

**Files:**
- Update golden files only if deterministic test surfaces intentionally change.

- [ ] Run `flutter analyze` and expect no issues.
- [ ] Run `flutter test --reporter compact` and expect all tests to pass.
- [ ] Run `flutter build web --release` and expect `build/web`.
- [ ] Run `flutter build apk --debug` and expect the debug APK.
- [ ] Commit, push the feature branch, and verify the external play URL serves
  the new `main.dart.js` hash.

