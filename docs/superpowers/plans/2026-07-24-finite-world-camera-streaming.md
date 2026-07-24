# Finite World, Camera, and Spatial Runtime Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a deterministic 2048×5120 finite combat world with a smooth bounded camera, chunked static art, spatial activity tiers, conserved and animated experience pickup, a compact fixed HUD, and development-only world diagnostics.

**Architecture:** `PixelSurvivorGame` remains the orchestration root but mounts gameplay below a dedicated `CombatWorld`. Pure geometry/configuration units define world bounds, camera motion, chunks, activity zones, spawn placement, and experience conservation. Runtime coordinators translate those pure decisions into Flame component lifecycle changes; Flutter overlays remain screen-space.

**Tech Stack:** Flutter, Flame 1.37.0, Dart 3.12, `flutter_test`, `flame_test`, existing SpriteBatch stage atlases, existing fixed-seed performance reporter.

## Global Constraints

- World size is `2048 × 5120`; chunk size is `512`.
- Initial camera zoom is `0.90`; actor sizes do not change.
- Camera movement never changes combat coordinates or collision geometry.
- HUD, joystick, pause, tutorial, and level-up remain Flutter screen-space overlays.
- Do not implement treasure chests or permanent training.
- Do not add characters, weapons, augments, or balance changes.
- Do not pre-spawn a map-wide enemy population.
- Pool only experience gems unless measurements justify more.
- Do not open an external tunnel.
- Do not run Android or iOS builds.
- During work, run targeted tests and targeted analysis.
- Only at final completion run full `flutter analyze`, full `flutter test`, and `flutter build web`.

---

### Task 1: Finite-world configuration and pure geometry

**Files:**
- Create: `lib/game/world/world_runtime_config.dart`
- Create: `lib/game/world/world_chunk_coordinate.dart`
- Create: `lib/game/world/finite_world_layout.dart`
- Test: `test/game/world_runtime_config_test.dart`
- Test: `test/game/finite_world_layout_test.dart`

**Interfaces:**
- Produces: `WorldRuntimeConfig.standard`
- Produces: `WorldChunkCoordinate.fromWorldPosition(Vector2, {required double chunkSize})`
- Produces: `FiniteWorldLayout.generate({required String stageId, required int seed, required WorldRuntimeConfig config})`
- Produces: immutable `worldBounds`, `chunkBounds`, `landmarkAnchors`, and `reservedChestAnchors`

- [ ] **Step 1: Write failing configuration and chunk-address tests**

```dart
test('standard world is aligned to four by ten chunks', () {
  final config = WorldRuntimeConfig.standard;
  expect(config.worldSize, Vector2(2048, 5120));
  expect(config.chunkSize, 512);
  expect(config.chunkColumns, 4);
  expect(config.chunkRows, 10);
  expect(config.cameraZoom, .90);
  expect(config.maxActiveExperienceGems, 96);
});

test('world position resolves to a clamped stable chunk coordinate', () {
  expect(
    WorldChunkCoordinate.fromWorldPosition(
      Vector2(1025, 2561),
      chunkSize: 512,
    ),
    const WorldChunkCoordinate(2, 5),
  );
});
```

- [ ] **Step 2: Run the tests and verify RED**

Run:

```powershell
flutter test --no-pub --no-test-assets test/game/world_runtime_config_test.dart test/game/finite_world_layout_test.dart
```

Expected: compilation fails because the world types do not exist.

- [ ] **Step 3: Implement the immutable configuration**

```dart
@immutable
class WorldRuntimeConfig {
  const WorldRuntimeConfig({
    required this.worldSize,
    required this.chunkSize,
    required this.cameraZoom,
    required this.cameraDeadZone,
    required this.cameraFollowSharpness,
    required this.zoneHysteresis,
    required this.maxActiveExperienceGems,
  });

  static final standard = WorldRuntimeConfig(
    worldSize: Vector2(2048, 5120),
    chunkSize: 512,
    cameraZoom: .90,
    cameraDeadZone: Vector2(18, 24),
    cameraFollowSharpness: 8,
    zoneHysteresis: 64,
    maxActiveExperienceGems: 96,
  );

  int get chunkColumns => (worldSize.x / chunkSize).round();
  int get chunkRows => (worldSize.y / chunkSize).round();
  Rect get worldBounds => Rect.fromLTWH(0, 0, worldSize.x, worldSize.y);
}
```

- [ ] **Step 4: Implement deterministic finite-world layout**

Use integer salts derived from `(seed, stage salt, chunk x, chunk y)`. Generate
all 40 chunk descriptors, dense boundary decoration anchors, sparse center
landmarks, and non-rendered future chest anchors. Expose unmodifiable
collections and reject positions outside `worldBounds`.

- [ ] **Step 5: Run tests and targeted analysis**

```powershell
flutter test --no-pub --no-test-assets test/game/world_runtime_config_test.dart test/game/finite_world_layout_test.dart
flutter analyze --no-pub lib/game/world test/game/world_runtime_config_test.dart test/game/finite_world_layout_test.dart
```

Expected: all tests pass and analysis reports no issues.

- [ ] **Step 6: Commit**

```powershell
git add lib/game/world test/game/world_runtime_config_test.dart test/game/finite_world_layout_test.dart
git commit -m "feat: define deterministic finite combat world"
```

---

### Task 2: Explicit CombatWorld and component ownership

**Files:**
- Create: `lib/game/world/combat_world.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `lib/game/performance/game_population_index.dart`
- Modify: `test/game/pixel_survivor_game_loop_test.dart`
- Modify: `test/game/game_population_index_test.dart`

**Interfaces:**
- Consumes: `WorldRuntimeConfig`
- Produces: `CombatWorld.worldComponents`
- Produces: `PixelSurvivorGame.addWorldComponent(Component)`
- Produces: `PixelSurvivorGame.worldChildrenOfType<T>()`

- [ ] **Step 1: Write failing ownership tests**

```dart
gameTester.testGameWidget(
  'actors and stage mount below CombatWorld',
  verify: (game, _) async {
    expect(game.world, isA<CombatWorld>());
    expect(game.activePlayers.single.parent, same(game.world));
    expect(
      game.world.children.whereType<EnemyComponent>(),
      isNotEmpty,
    );
    expect(game.children.whereType<EnemyComponent>(), isEmpty);
  },
);
```

Add a population-index test proving nested world child add/remove events update
the production counts exactly once.

- [ ] **Step 2: Run ownership tests and verify RED**

```powershell
flutter test --no-pub --no-test-assets test/game/pixel_survivor_game_loop_test.dart --plain-name "actors and stage mount below CombatWorld"
flutter test --no-pub --no-test-assets test/game/game_population_index_test.dart
```

Expected: the first test fails because actors currently mount at the game root.

- [ ] **Step 3: Implement `CombatWorld`**

```dart
class CombatWorld extends World {
  CombatWorld({this.onChildLifecycle});

  void Function(Component, ChildrenChangeType)? onChildLifecycle;

  @override
  void onChildrenChanged(Component child, ChildrenChangeType type) {
    super.onChildrenChanged(child, type);
    onChildLifecycle?.call(child, type);
  }
}
```

Construct `PixelSurvivorGame` with `super(world: CombatWorld())`, bind the
lifecycle callback after construction, and route gameplay additions through
`world.add`. Camera, world, and debug screen overlays remain root-owned.

- [ ] **Step 4: Replace root-world queries**

Replace gameplay uses of `children.whereType<T>()`, `children.where(...)`, and
`children.toList()` with focused `world.children` helpers. Preserve root
lifecycle cleanup for the camera and world themselves. Update tests to query
world-owned actors through public game accessors rather than implementation
details where possible.

- [ ] **Step 5: Run focused lifecycle and combat tests**

```powershell
flutter test --no-pub --no-test-assets test/game/game_population_index_test.dart test/game/pixel_survivor_game_loop_test.dart test/game/game_performance_budget_test.dart
flutter analyze --no-pub lib/game/pixel_survivor_game.dart lib/game/world/combat_world.dart
```

Expected: all focused tests pass; population counts do not double-register.

- [ ] **Step 6: Commit**

```powershell
git add lib/game/world/combat_world.dart lib/game/pixel_survivor_game.dart lib/game/performance/game_population_index.dart test/game
git commit -m "refactor: move combat actors into Flame world"
```

---

### Task 3: Smooth bounded tracking camera

**Files:**
- Create: `lib/game/world/combat_camera_controller.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `lib/game/components/player_component.dart`
- Create: `test/game/combat_camera_controller_test.dart`
- Modify: `test/game/player_component_test.dart`
- Modify: `test/game/pixel_survivor_game_settings_test.dart`

**Interfaces:**
- Consumes: `WorldRuntimeConfig`, `CameraComponent`, player position, shake offset
- Produces: `CombatCameraController.update(double dt)`
- Produces: `CombatCameraController.basePosition`
- Produces: `CombatCameraController.clampCenter(Vector2 desired, Rect visibleRect)`

- [ ] **Step 1: Write failing camera geometry tests**

```dart
test('small target motion remains inside dead zone', () {
  final rig = CombatCameraController.test(
    config: WorldRuntimeConfig.standard,
    initialPosition: Vector2(1024, 2560),
  );
  rig.follow(Vector2(1030, 2568), dt: 1 / 60);
  expect(rig.basePosition, Vector2(1024, 2560));
});

test('camera center clamps so visible rect remains inside world', () {
  final center = CombatCameraController.clampCenter(
    desired: Vector2.zero(),
    visibleSize: Vector2(433.333, 937.778),
    worldBounds: const Rect.fromLTWH(0, 0, 2048, 5120),
  );
  expect(center.x, closeTo(216.6665, .001));
  expect(center.y, closeTo(468.889, .001));
});
```

- [ ] **Step 2: Run camera tests and verify RED**

```powershell
flutter test --no-pub --no-test-assets test/game/combat_camera_controller_test.dart
```

Expected: compilation fails because the controller does not exist.

- [ ] **Step 3: Implement follow math**

Use frame-independent smoothing:

```dart
final alpha = 1 - math.exp(-config.cameraFollowSharpness * safeDt);
basePosition.add((desiredAfterDeadZone - basePosition) * alpha);
```

Clamp using the camera's virtual viewport size divided by zoom. Compose
screen-shake after base motion, clamp the final center, and write the viewfinder
once per frame.

- [ ] **Step 4: Integrate world bounds and zoom**

Set `camera.viewfinder.zoom = config.cameraZoom` once during load. Start the
camera at the player position without an opening interpolation. Replace player
movement bounds `size` with `config.worldSize`. Keep actor render sizes
unchanged.

- [ ] **Step 5: Add collision invariance integration test**

Move the camera to two different centers while leaving identical world actors
and assert `AttackGeometry.contains`, projectile overlap, and contact damage
produce identical results.

- [ ] **Step 6: Run camera, movement, and combat geometry tests**

```powershell
flutter test --no-pub --no-test-assets test/game/combat_camera_controller_test.dart test/game/player_component_test.dart test/game/attack_geometry_test.dart test/game/pixel_survivor_game_settings_test.dart
```

- [ ] **Step 7: Commit**

```powershell
git add lib/game/world/combat_camera_controller.dart lib/game/pixel_survivor_game.dart lib/game/components/player_component.dart test/game
git commit -m "feat: add smooth bounded player camera"
```

---

### Task 4: Deterministic chunk batches and natural boundaries

**Files:**
- Modify: `lib/game/content/stage_visual_spec.dart`
- Modify: `lib/game/components/stage_tile_batch_component.dart`
- Create: `lib/game/world/stage_chunk_streamer.dart`
- Create: `lib/game/components/world_boundary_component.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `test/game/stage_visual_spec_test.dart`
- Modify: `test/game/stage_tile_batch_component_test.dart`
- Create: `test/game/stage_chunk_streamer_test.dart`
- Create: `test/game/world_boundary_component_test.dart`

**Interfaces:**
- Consumes: `FiniteWorldLayout`, `camera.visibleWorldRect`, preloaded stage images
- Produces: `StageLayout.buildChunk(...)`
- Produces: `StageChunkStreamer.updateStreaming(Rect sleepingZone)`
- Produces: `WorldBoundaryComponent` with presentation-only batches

- [ ] **Step 1: Write failing chunk determinism tests**

```dart
test('same seed and coordinate produce identical chunk placements', () {
  final first = StageLayout.buildChunk(
    spec,
    seed: 3107,
    coordinate: const WorldChunkCoordinate(2, 5),
    chunkSize: 512,
    worldBounds: const Rect.fromLTWH(0, 0, 2048, 5120),
  );
  final second = StageLayout.buildChunk(
    spec,
    seed: 3107,
    coordinate: const WorldChunkCoordinate(2, 5),
    chunkSize: 512,
    worldBounds: const Rect.fromLTWH(0, 0, 2048, 5120),
  );
  expect(first.tiles, second.tiles);
  expect(first.props, second.props);
});
```

Assert edge chunks have more boundary props than center chunks and every batch
is limited to one chunk.

- [ ] **Step 2: Run chunk tests and verify RED**

```powershell
flutter test --no-pub --no-test-assets test/game/stage_chunk_streamer_test.dart test/game/world_boundary_component_test.dart
```

- [ ] **Step 3: Implement chunk-local stage layout and batches**

Add stable chunk salts and edge-aware placement. Build a `SpriteBatch` per
asset per loaded chunk. `StageChunkStreamer` mounts chunks intersecting the
sleeping zone plus one-chunk prefetch margin and removes other static chunks.

- [ ] **Step 4: Implement natural finite boundary**

Build repeated wall/tree/rock/building prop placements from existing atlases.
Boundary collision remains a single world-rectangle clamp; decorative props do
not create hundreds of hitboxes.

- [ ] **Step 5: Remove screen-sized backdrop ownership**

Replace `StageBackdropComponent(viewportSize: size)` and the single viewport
layout with chunk streaming. Keep the existing full courtyard art only as a
bounded center-landmark layer when the moonlit stage requires it.

- [ ] **Step 6: Run stage and asset tests**

```powershell
flutter test --no-pub --no-test-assets test/game/stage_visual_spec_test.dart test/game/stage_tile_batch_component_test.dart test/game/stage_chunk_streamer_test.dart test/game/world_boundary_component_test.dart test/game/stage_visual_asset_contract_test.dart
```

- [ ] **Step 7: Commit**

```powershell
git add lib/game/content/stage_visual_spec.dart lib/game/components lib/game/world lib/game/pixel_survivor_game.dart test/game
git commit -m "feat: stream deterministic stage chunks"
```

---

### Task 5: Activity zones, sleeping enemies, and spatial spawning

**Files:**
- Create: `lib/game/world/world_activity_zone.dart`
- Create: `lib/game/world/world_chunk_repository.dart`
- Create: `lib/game/world/spatial_spawn_planner.dart`
- Modify: `lib/game/components/enemy_component.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Create: `test/game/world_activity_zone_test.dart`
- Create: `test/game/world_chunk_repository_test.dart`
- Create: `test/game/spatial_spawn_planner_test.dart`
- Modify: `test/game/enemy_component_test.dart`
- Modify: `test/game/pixel_survivor_game_loop_test.dart`

**Interfaces:**
- Produces: `WorldActivityZones.fromVisibleRect(...)`
- Produces: `WorldActivityTier classify(Vector2 position, {WorldActivityTier? previous})`
- Produces: `SleepingEnemyRecord`
- Produces: `WorldChunkRepository.sleepEnemy`, `restoreEnemiesNear`, `recycleFarRecords`
- Produces: `SpatialSpawnPlanner.positionFor(SpatialSpawnRequest)`

- [ ] **Step 1: Write failing zone and hysteresis tests**

```dart
test('position transitions visible active sleeping recycle', () {
  final zones = WorldActivityZones.fromVisibleRect(
    const Rect.fromLTWH(800, 2200, 433, 938),
    worldBounds: const Rect.fromLTWH(0, 0, 2048, 5120),
    hysteresis: 64,
  );
  expect(zones.classify(Vector2(900, 2500)), WorldActivityTier.visible);
  expect(zones.classify(Vector2(600, 1800)), WorldActivityTier.active);
  expect(zones.classify(Vector2(100, 800)), WorldActivityTier.sleeping);
});
```

Add tests proving a 32-unit boundary oscillation does not repeatedly change
tier and recycled records preserve visit pressure.

- [ ] **Step 2: Run pure tests and verify RED**

```powershell
flutter test --no-pub --no-test-assets test/game/world_activity_zone_test.dart test/game/world_chunk_repository_test.dart test/game/spatial_spawn_planner_test.dart
```

- [ ] **Step 3: Implement sleeping records**

```dart
@immutable
class SleepingEnemyRecord {
  const SleepingEnemyRecord({
    required this.enemyId,
    required this.position,
    required this.healthFraction,
    required this.rank,
    required this.stateSeed,
  });
}
```

Snapshot normal enemies when they enter sleeping tier, remove their overlay and
shadow owners, and restore them with clamped health when their chunk approaches
active tier. Do not sleep or recycle bosses.

- [ ] **Step 4: Implement bounded active enemy update**

`EnemyComponent` receives an activity tier. Visible enemies use normal updates.
Active enemies accumulate time and run AI at a maximum 0.05-second step.
Sleeping enemies are not mounted. Rendering returns early outside visible tier.
Gameplay state transitions are controlled centrally, not by per-enemy camera
queries.

Projectiles, hazards, and transient VFX are never serialized as sleeping
records. They continue normal updates inside the active zone and are removed
once they leave it or reach their existing lifetime. Experience gems follow the
separate conservation rules in Task 6.

- [ ] **Step 5: Implement spatial spawn planner**

Feed existing `WaveDirector` requests into deterministic candidate sampling
around the visible-zone perimeter. Bias toward recent player motion and
low-pressure chunks. Reject out-of-world and too-close positions. Restore
sleeping records before requesting fresh spawns in revisited chunks.

- [ ] **Step 6: Run enemy, spawn, and loop tests**

```powershell
flutter test --no-pub --no-test-assets test/game/world_activity_zone_test.dart test/game/world_chunk_repository_test.dart test/game/spatial_spawn_planner_test.dart test/game/enemy_component_test.dart test/game/pixel_survivor_game_loop_test.dart test/game/wave_director_test.dart
```

- [ ] **Step 7: Commit**

```powershell
git add lib/game/world lib/game/components/enemy_component.dart lib/game/pixel_survivor_game.dart test/game
git commit -m "feat: add spatial enemy activity lifecycle"
```

---

### Task 6: Conserved experience compression and gem lifecycle

**Files:**
- Create: `lib/game/world/experience_ledger.dart`
- Create: `lib/game/world/experience_gem_coordinator.dart`
- Modify: `lib/game/components/experience_gem_component.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Create: `test/game/experience_ledger_test.dart`
- Create: `test/game/experience_gem_coordinator_test.dart`
- Modify: `test/game/weapon_system_test.dart`
- Modify: `test/game/pixel_survivor_game_loop_test.dart`

**Interfaces:**
- Produces: `ExperienceLedger.totalOwnedExperience`
- Produces: `ExperienceGemCoordinator.drop`, `compressOutside`, `restoreNear`, `beginPickup`
- Produces: `ExperienceGemState { idle, magnet, orbit, consume, released }`
- Produces: single-use `ExperiencePickupToken`

- [ ] **Step 1: Write failing conservation tests**

```dart
test('merge compress restore preserves exact experience total', () {
  final coordinator = ExperienceGemCoordinator.test(maxActiveGems: 3);
  coordinator.drop(5, Vector2(100, 100));
  coordinator.drop(7, Vector2(104, 102));
  coordinator.drop(11, Vector2(1800, 4800));
  final before = coordinator.totalOwnedExperience;
  coordinator.mergeNearby();
  coordinator.compressOutside(const Rect.fromLTWH(0, 0, 500, 500));
  coordinator.restoreNear(const Rect.fromLTWH(1500, 4500, 500, 500));
  expect(coordinator.totalOwnedExperience, before);
});

test('consume token grants experience once', () {
  final token = ExperiencePickupToken(17);
  expect(token.consume(), 17);
  expect(token.consume(), 0);
});
```

- [ ] **Step 2: Run conservation tests and verify RED**

```powershell
flutter test --no-pub --no-test-assets test/game/experience_ledger_test.dart test/game/experience_gem_coordinator_test.dart
```

- [ ] **Step 3: Implement integer ownership ledger**

Track dropped, mounted, compressed, magnetized, and granted totals. All
transfers atomically subtract one owner before adding the next. Restoration
subtracts chunk compression before mounting components.

- [ ] **Step 4: Implement gem state machine test first**

Add tests for:

- idle float does not change world ownership;
- pickup duration stays within 0.18–0.30 seconds;
- magnet acceleration is monotonic;
- orbit covers 90–180 degrees;
- death cancels without granting;
- paused engine preserves state;
- release resets all mutable fields.

Run and confirm failure before editing `ExperienceGemComponent`.

- [ ] **Step 5: Implement cached gem rendering and animation**

Cache `Path`, `Paint`, and reusable vectors on the component. Replace per-frame
render allocations. Use scalar polar interpolation for orbit. The completion
callback receives the single-use token and returns the component to a bounded
pool or removes it.

- [ ] **Step 6: Integrate coordinated drops and pickup audio batching**

Replace `_addExperienceGem` and `_collectExperienceGems` with the coordinator.
Use a short pickup cadence window so a group emits one primary audio cue and a
bounded accent count. Keep the current audio backend valid when pitch control
is unavailable.

- [ ] **Step 7: Run experience and dense pickup tests**

```powershell
flutter test --no-pub --no-test-assets test/game/experience_ledger_test.dart test/game/experience_gem_coordinator_test.dart test/game/weapon_system_test.dart test/game/pixel_survivor_game_loop_test.dart
```

- [ ] **Step 8: Commit**

```powershell
git add lib/game/world lib/game/components/experience_gem_component.dart lib/game/pixel_survivor_game.dart test/game
git commit -m "feat: conserve and animate experience pickups"
```

---

### Task 7: Compact HUD and development-only world diagnostics

**Files:**
- Modify: `lib/app/game_hud.dart`
- Modify: `lib/app/virtual_joystick.dart`
- Modify: `lib/app/game_hud_source.dart`
- Create: `lib/app/world_debug_overlay.dart`
- Create: `lib/game/world/world_debug_snapshot.dart`
- Create: `lib/game/components/world_debug_renderer.dart`
- Modify: `lib/app/game_screen.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `test/app/game_hud_test.dart`
- Modify: `test/app/virtual_joystick_test.dart`
- Create: `test/app/world_debug_overlay_test.dart`
- Create: `test/game/world_debug_snapshot_test.dart`

**Interfaces:**
- Consumes: existing `GameHudSource`
- Produces: `WorldDebugSource.debugSnapshot`
- Produces: `WorldDebugSnapshot`
- Preserves: `hud-pause`, `hud-status`, `virtual-joystick`, and `virtual-joystick-base` keys

- [ ] **Step 1: Write failing compact HUD tests**

```dart
testWidgets('portrait status panel is no taller than 64 pixels', (tester) async {
  await tester.pumpWidget(MaterialApp(home: GameHud(source: source)));
  expect(
    tester.getSize(find.byKey(const Key('hud-status'))).height,
    lessThanOrEqualTo(64),
  );
  expect(find.textContaining('/'), findsWidgets);
  expect(find.byKey(const Key('hud-health-bar')), findsNothing);
});
```

Assert pause, timer, level, experience, kills, and weapon slots remain present.
Assert the joystick idle alpha is 0.22 and active alpha remains 0.55.

- [ ] **Step 2: Run widget tests and verify RED**

```powershell
flutter test --no-pub --no-test-assets test/app/game_hud_test.dart test/app/virtual_joystick_test.dart
```

- [ ] **Step 3: Rebuild the compact status bar**

Use one translucent navy panel, one thin ivory border, gold level emphasis, a
thin experience bar, compact time/kills, and up to three weapon slots. Remove
the persistent health, combat notice, and kill-streak rows. Preserve boss bar,
pause semantics, safe-area behavior, and accessibility labels.

- [ ] **Step 4: Restyle joystick without changing input semantics**

Keep full-screen floating touch-origin input. Use idle opacity 0.22, active
opacity 0.55, ivory base, gold thumb, and navy outline.

- [ ] **Step 5: Write and implement debug snapshot tests**

`WorldDebugSnapshot` includes world/camera/zone rectangles, chunk size, active
and sleeping enemies, active gems, compressed XP, projectiles, VFX, mounted
components, create/remove rates, FPS/frame p95, and zoom.

Build the Flutter debug panel and world-space line renderer only when
`kDebugMode && debugWorldOverlayEnabled`. Bind the development toggle to
`LogicalKeyboardKey.f3`; the handler is compiled but returns without adding
debug components in release policy tests.

- [ ] **Step 6: Run HUD, overlay, and accessibility tests**

```powershell
flutter test --no-pub --no-test-assets test/app/game_hud_test.dart test/app/virtual_joystick_test.dart test/app/accessibility_surfaces_test.dart test/app/game_screen_pause_test.dart test/app/level_up_overlay_test.dart test/app/world_debug_overlay_test.dart test/game/world_debug_snapshot_test.dart
```

- [ ] **Step 7: Commit**

```powershell
git add lib/app lib/game/world lib/game/components/world_debug_renderer.dart lib/game/pixel_survivor_game.dart test/app test/game
git commit -m "feat: simplify HUD and add world diagnostics"
```

---

### Task 8: Performance measurement and Chrome development verification

**Files:**
- Modify: `lib/game/performance/performance_development_log.dart`
- Modify: `lib/game/performance/performance_development_reporter.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `test/game/five_minute_performance_development_log_test.dart`
- Modify: `test/game/performance_development_log_test.dart`
- Modify: `docs/testing/five-minute-performance-development-log.md`
- Modify: `docs/testing/combat-visual-profile-procedure.md`

**Interfaces:**
- Produces: p95 frame time, sleeping count, active gem count, compressed XP,
  creates/removes per second, runtime image loads, camera-motion samples
- Preserves: existing JSON and Markdown artifact keys

- [ ] **Step 1: Lock the actual pre-change baseline**

Update the pre-change retained-owner expectation from 44 to the observed 46
only after adding an explicit baseline note. Preserve all other observed seed
3107 values.

- [ ] **Step 2: Write failing reporter tests**

Create samples with known ordered frame durations and lifecycle counters.
Assert nearest-rank p95, create/remove rates, peak sleeping enemies, and runtime
image-load violations serialize to JSON and Markdown.

- [ ] **Step 3: Run reporter tests and verify RED**

```powershell
flutter test --no-pub --no-test-assets test/game/performance_development_log_test.dart
```

- [ ] **Step 4: Implement metrics without per-frame sorting**

Collect bounded frame-time samples, sort only while finishing the report, and
calculate nearest-rank p95. Increment lifecycle counters from world child
events. Count image-loader calls after combat start.

- [ ] **Step 5: Run fixed-seed five-minute comparison**

```powershell
flutter test --no-pub --no-test-assets test/game/five_minute_performance_development_log_test.dart
```

Record actual before/after values without fabricating physical-device FPS.

- [ ] **Step 6: Run local Chrome development check**

Run local Chrome only, with no tunnel:

```powershell
flutter run -d chrome
```

Use hot reload while checking:

- camera follow and direction reversal;
- all four world edges;
- chunk transitions;
- dense pickup animation;
- HUD and joystick;
- debug overlay toggling;
- browser frame chart during sustained movement.

Update the profiling document with the exact observed local results and note
which checks still require a physical phone.

- [ ] **Step 7: Commit**

```powershell
git add lib/game/performance lib/game/pixel_survivor_game.dart test/game docs/testing
git commit -m "perf: measure finite world runtime pressure"
```

---

### Task 9: Integration review and final verification

**Files:**
- Modify only files required by review findings
- Test: all project tests

**Interfaces:**
- Consumes: all prior tasks
- Produces: final verified milestone and report

- [ ] **Step 1: Run targeted milestone integration tests**

```powershell
flutter test --no-pub --no-test-assets test/game/combat_camera_controller_test.dart test/game/stage_chunk_streamer_test.dart test/game/world_activity_zone_test.dart test/game/experience_gem_coordinator_test.dart test/app/game_hud_test.dart test/app/world_debug_overlay_test.dart
```

- [ ] **Step 2: Review the integrated diff once**

Review for:

- screen-space/world-space ownership errors;
- camera-dependent collision or aim;
- world-edge exposure;
- sleeping-state loss or duplicate enemies;
- experience conservation or duplicate grants;
- image loads during combat;
- stale background or asset paths;
- treasure/permanent-training scope creep.

For each defect, write a failing regression test, run it to verify RED, apply
the minimal fix, and verify GREEN.

- [ ] **Step 3: Run final analysis**

```powershell
flutter analyze
```

Expected: exit code 0 with no issues.

- [ ] **Step 4: Run the full test suite**

```powershell
flutter test
```

Expected: exit code 0 with all tests passing. If the known Windows shader
compiler crashes, preserve the complete error and do not describe the suite as
passing; retrying with `--no-test-assets` is diagnostic evidence only.

- [ ] **Step 5: Build web once**

```powershell
flutter build web
```

Expected: exit code 0 and a fresh `build/web`. If `impellerc` crashes, report
the build as blocked by the toolchain; copying cached shaders does not count as
a successful clean build.

- [ ] **Step 6: Produce the completion report**

Report:

- former camera/world structure;
- final world size and chunk dimensions;
- visible/active/sleeping/recycle thresholds;
- camera dead zone, smoothing, clamping, and zoom;
- experience merge/compress/restore/consume conservation;
- HUD changes;
- fixed-seed before/after metrics;
- Chrome observations;
- physical-phone checklist;
- exact final verification results and any toolchain failures.

- [ ] **Step 7: Commit final review fixes and documentation**

```powershell
git add -A
git commit -m "feat: complete finite world camera milestone"
```
