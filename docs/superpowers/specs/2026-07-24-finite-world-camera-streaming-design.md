# Finite World, Tracking Camera, and Spatial Runtime Design

**Date:** 2026-07-24  
**Status:** Approved design, pending written-spec review  
**Project:** Flutter + Flame Joseon folk-fantasy survivor  
**Target branch:** `codex/integrated-mobile-preview`

## Goal

Replace the screen-sized combat field with a deterministic finite world and a
smooth player-following camera, while keeping combat geometry in world
coordinates, reducing off-screen runtime cost, improving experience-gem
collection feedback, and simplifying the mobile HUD.

This milestone does not implement treasure chests, permanent training, new
characters, new weapons, or new augments.

## Existing Structure

`PixelSurvivorGame` extends `FlameGame` and therefore already owns Flame's
default `World` and `CameraComponent`. However, combat components are currently
added to the `FlameGame` root. The camera renders its `World`, while root
components are rendered outside the world transform. In practice, the current
runtime treats `game.size` as both viewport size and world size.

The following systems are coupled to viewport size:

- `PlayerComponent.applyInput(..., bounds: size)` clamps the player to the
  visible game size.
- `SpawnRingGeometry.offsetForAngle(size, ...)` places enemies around the
  screen-sized rectangle.
- projectile cleanup compares positions with `size`.
- stage layout is built for the initial viewport rectangle.
- boss and starting-player positions use the viewport center.

The HUD, joystick, pause menu, tutorial, and level-up selection are Flutter
overlays registered by `GameWidget`. They are already screen-space elements and
must remain outside the world transform.

Experience gems are active `PositionComponent`s. At 128 active gems, new
experience is added to the first mounted gem regardless of distance or chunk.
Pickup immediately grants experience and removes the component. The current
render method allocates a `Path` and several `Paint` objects each frame.

The fixed-seed five-minute host baseline for seed `3107` is:

- average / maximum active enemies: `27.5967 / 93`
- late average / maximum active enemies: `53.0243 / 93`
- peak mounted components: `447`
- peak retained owners: `46`
- peak memory proxy: `480`
- peak populations: enemies `93`, projectiles `26`, damage numbers `24`,
  combat effects `24`
- peak host update+lifecycle sample: `10,085 µs`

The pre-existing test expects 44 retained owners while the current integrated
runtime produces 46. The implementation must record 46 as the baseline rather
than attributing that drift to the new world work.

## Chosen Architecture

Use an explicit combat `World` and preserve `PixelSurvivorGame` as the
orchestrator. World components are mounted below the `World`; camera and Flutter
overlays remain outside it.

Introduce focused runtime units:

- `WorldRuntimeConfig`: immutable world, camera, chunk, zone, and gem limits.
- `CombatWorld`: owns world-space components and reports lifecycle changes to
  the population index.
- `FiniteWorldLayout`: deterministic chunk, boundary, landmark, and reserved
  future-object positions.
- `CombatCameraController`: dead-zone follow, exponential smoothing, world
  clamping, and screen-shake composition.
- `WorldActivityController`: classifies positions as visible, active,
  sleeping, or recycle.
- `WorldChunkRepository`: visit state, compressed experience, and lightweight
  sleeping-enemy records.
- `SpatialSpawnPlanner`: chooses spawn positions using the player's location,
  travel direction, world bounds, and chunk visit pressure.
- `ExperienceGemCoordinator`: merge, compress, restore, magnetize, consume, and
  optionally recycle experience gems.
- `WorldDebugSnapshot`: immutable development-only metrics consumed by a
  Flutter overlay and a lightweight world debug renderer.

The design deliberately avoids an ECS rewrite and does not add a third-party
camera or spatial-index package.

## World Dimensions and Coordinates

The finite world is `2048 × 5120` world units.

Rationale:

- both dimensions align to the existing 128-unit tile grid;
- the world is exactly `4 × 10` chunks at 512 units per chunk;
- against a 390×844 portrait viewport it spans approximately 5.25 screens
  horizontally and 6.07 screens vertically before zoom adjustment;
- at the configured zoom it remains within the requested four-to-five visible
  widths and five-to-seven visible heights;
- move speeds of 115–140 units/second allow a vertical traversal in roughly
  37–45 seconds, leaving enough time for route choice and revisiting during a
  five-minute run.

The world rectangle starts at `(0, 0)`. The initial player position is the
world center `(1024, 2560)`. Player, enemy, projectile, experience, VFX,
landmark, reserved future chest, and background-object positions are world
coordinates.

Collision and combat calculations never use camera or screen coordinates.

## Deterministic Chunked Stage

Chunk size is 512 units. `FiniteWorldLayout` derives each chunk from:

```text
stageVisualSeed XOR stage seed salt XOR stable chunk coordinate salt
```

The same stage, seed, and chunk coordinate always produce the same layout.
Runtime string hashes are not used.

Each chunk builds static tile, decal, and prop batches from existing stage
atlases. A chunk owns at most one batch per asset. Chunk batches are created
when the chunk enters the sleeping/streaming radius and are removed outside it.
The entire world is never assembled as one high-resolution image or one global
batch.

Placement policy:

- central chunks use sparse decals and minimal props;
- edge chunks concentrate walls, buildings, trees, and rocks;
- world-boundary chunks create a visually continuous impassable border;
- a small fixed set of landmark anchors uses denser existing props;
- future chest anchors are stored as lightweight data only and render nothing.

The existing portrait Joseon courtyard backdrop may be used as a temporary
center landmark layer for the moonlit stage, but it cannot define world bounds
or be stretched across the whole map.

## Player Boundary

Player movement clamps the full collision body to `worldBounds`, not
`game.size`. Knockback and other direct movement paths use the same finite-world
clamp after integration.

Enemies may briefly use a small outer navigation margin while entering combat,
but spawn placement must be inside the playable boundary. Projectiles and
temporary VFX are recycled or removed relative to the world and activity zones,
not the viewport rectangle.

## Camera Configuration and Follow

Camera values live in `WorldRuntimeConfig`.

Initial values:

- zoom: `0.90`
- dead zone: `18 × 24` world units
- follow sharpness: `8.0`
- fixed target offset: zero

Zoom 0.90 shows approximately 11.1% more world area than zoom 1.0. Player and
monster render sizes remain unchanged.

`CombatCameraController` performs these steps once per update:

1. read the mounted living player's world position;
2. calculate the target delta outside the dead zone;
3. apply frame-rate-independent exponential interpolation;
4. clamp the base camera center so the complete visible rectangle remains
   inside world bounds;
5. add the bounded screen-shake offset;
6. clamp the final center again and write `camera.viewfinder.position`.

The controller exposes the base position separately from shake. Fast direction
changes within the dead zone do not move the camera. Pause and level-up engine
pauses freeze both player and camera without changing coordinates.

## Activity Zones

Zones are derived from `camera.visibleWorldRect` and clamped to the finite world.

- **Visible zone:** visible rectangle inflated by 128 units. Components render
  and receive normal-rate updates.
- **Active zone:** visible zone inflated by one current visible-width/height.
  Enemies remain mounted but render-disabled when off-screen; their AI is
  stepped at a bounded reduced rate.
- **Sleeping zone:** active zone inflated by 1.5 visible-widths/heights. Normal
  enemies are converted to lightweight `SleepingEnemyRecord`s in their chunks.
  The record retains enemy id, world position, health fraction, rank, and a
  stable state seed. High-cost component updates stop.
- **Recycle zone:** outside the sleeping zone. Ordinary sleeping records may be
  returned to spatial spawn pressure. Bosses and persistent landmark records
  are never recycled.

Zone transitions use hysteresis at least 64 units wide to avoid repeatedly
mounting and unmounting objects near a boundary.

`EnemyComponent` is not responsible for deciding its own zone. The central
controller performs classification at a limited interval and applies an
immutable activity tier. This avoids every enemy independently recomputing all
camera rectangles each frame.

## Spatial Spawning

`WaveDirector` remains the source of elapsed-time pressure, enemy type, boss
timing, and combat balance. Only spawn-position selection changes.

`SpatialSpawnPlanner`:

- samples candidate points just beyond the visible zone and inside the active
  zone;
- rejects points outside world bounds or too close to the player;
- weakly favors the player's recent movement direction;
- favors chunks with lower visit/spawn pressure;
- avoids exact reuse of recent spawn points;
- uses the game seed and a monotonic spawn sequence for reproducibility.

Returning to an old area first restores sleeping enemies, then allows low-rate
new spawns. Recycled regions retain chunk visit and spawn pressure so they do
not become completely empty or repopulate identically in one frame.

No initial population of hundreds of enemy components is allowed.

## Experience Storage and Conservation

`WorldChunkState` owns:

- active experience identifiers associated with mounted gems;
- `compressedExperience`, an integer that is not simultaneously owned by a
  mounted gem;
- sleeping enemy records;
- visit and spawn pressure counters.

Experience conservation invariant:

```text
dropped total
= mounted gem values
+ magnet/consume gem values
+ compressed chunk values
+ already granted experience
```

Close gems of compatible grade merge into the nearest or highest-value gem.
When the active-gem limit would be exceeded, the coordinator first performs
local merges, then compresses off-screen values by chunk. It never adds overflow
to an unrelated first gem.

When a chunk approaches the active zone, compressed experience is restored into
a bounded number of value-tier gems at deterministic positions. Restoration
atomically subtracts the compressed value before mounting gems. Collection
marks a gem as consumed before invoking the experience callback, preventing
duplicate grants.

The initial maximum active gem count is 96 and lives in
`WorldRuntimeConfig`. The value is subject to measured adjustment.

## Experience Pickup Animation

`ExperienceGemComponent` uses an explicit state machine:

```text
idle -> magnet -> orbit -> consume -> released
```

- idle: cached visual geometry with a subtle vertical float;
- magnet: accelerating interpolation toward the current player position;
- orbit: a short 90–180 degree polar arc;
- consume: slight scale-up followed by fast scale-down and fade;
- released: invoke the single-use grant callback, reset state, then return to
  the coordinator or remove.

Total animation duration is clamped to 0.18–0.30 seconds. Polar calculations
use scalar fields and cached vectors. `Path` and `Paint` objects are not created
per gem per frame.

If the player dies before completion, the gem returns to idle at its current
world position without granting experience. A level-up overlay pauses the
engine, preserving the animation state. The consumed guard survives lifecycle
callbacks and prevents duplicate experience.

Pickup audio is aggregated into a short cadence window. The first pickup emits
the normal cue; subsequent pickups within the window increase one of a small
number of brightness/pitch steps without creating one simultaneous voice per
gem. The audio backend interface remains backward compatible if pitch control
is unavailable.

## Pooling Policy

Pooling is evidence-driven.

- Experience gems receive a small bounded reusable pool because they are
  frequently created and removed and have a simple reset contract.
- Chunk background batches are cached only while inside the streaming radius;
  they are rebuilt deterministically rather than retained for the whole map.
- Enemies and projectiles are not pooled in this milestone unless creation and
  removal metrics show a measurable hotspot and the current Flame lifecycle
  supports a safe complete reset.
- Visual particles continue to use existing bounded population limits.

Every pooled gem must reset position, value, animation state, callback,
opacity, scale, angle, and ownership token before reuse.

## HUD

The HUD stays a Flutter `GameWidget` overlay and never becomes a child of
`World` or `Viewfinder`.

The persistent top bar is reduced to approximately 64 logical pixels and keeps:

- pause control;
- elapsed time;
- player level;
- current/required experience and progress bar;
- kill count;
- up to three current weapon slots.

The existing always-visible health block, combat notice, and kill-streak rows
are removed from the persistent status panel for this milestone. Boss health
remains a conditional separate bar.

Visual style:

- translucent deep navy fill;
- one thin ivory outline;
- gold for level and primary emphasis;
- Joseon ornament only at small corners or separators;
- no thick nested frames;
- no bright cyan or purple panel decoration.

The joystick preserves floating touch-origin behavior. Idle opacity decreases
from 0.35 to 0.22; active opacity remains readable. The base and thumb use
ivory/gold/navy rather than cyan.

Pause, tutorial, and level-up overlays preserve their current Flutter
screen-space ownership, keys, actions, and responsive layouts.

## Development Debugging

Debug visualization is created only when `kDebugMode` and a runtime toggle are
both true.

World renderer:

- finite world boundary;
- current camera rectangle;
- visible, active, and sleeping zone rectangles;
- 512-unit chunk boundaries.

Screen-space Flutter metrics:

- active enemies;
- sleeping enemies;
- active gems;
- compressed experience;
- active projectiles;
- active VFX;
- mounted component count;
- component creates/removes per second;
- FPS and frame-time rolling average/p95;
- camera zoom.

Release builds do not construct or render either debug surface.

## Performance Instrumentation

Extend the deterministic performance collector and Chrome profile procedure to
record:

- average FPS;
- frame-time p95;
- active and sleeping enemies;
- active gems and compressed experience;
- mounted component count;
- creates and removes per second;
- runtime image-load attempts after initial preload;
- camera-motion frame-time samples;
- active projectiles and VFX.

The same seed `3107`, five-minute duration, movement script, viewport, and wave
configuration are used before and after. Host fixed-dt results are reported
separately from Chrome build/raster timing and never described as physical
mobile FPS.

All stage, enemy, gem, projectile, and VFX images required by the run are
preloaded before combat. A runtime load-attempt counter must remain zero during
the measured combat window.

## Testing Strategy

Use test-first development for each unit.

Pure unit tests:

- finite-world dimensions and chunk addressing;
- deterministic chunk layouts and boundary density;
- camera dead-zone interpolation and world clamping;
- activity-zone classification and hysteresis;
- spawn candidates remain valid and deterministic;
- experience merge/compress/restore conservation;
- duplicate consume callbacks are rejected;
- gem state transitions fit the duration budget;
- sleeping enemy records preserve required state;
- debug snapshots calculate population counts.

Flame integration tests:

- all gameplay actors mount below `CombatWorld`;
- player movement clamps to world bounds;
- camera follows player without changing player coordinates;
- camera never exposes outside-world space;
- attacks and collision results are invariant under camera movement;
- off-screen active enemies remain present;
- sleeping enemies stop high-cost updates and restore near the player;
- viewport HUD is unaffected by camera movement;
- level-up and pause state do not corrupt gem pickup.

Flutter widget and golden tests:

- compact HUD contains only required persistent information;
- status height and pause safe-area anchors fit 390×844;
- joystick idle/active opacity and touch-origin behavior;
- pause and level-up overlays retain screen-space layout;
- debug panel is absent from release-mode policy.

Performance tests:

- fixed-seed before/after report;
- experience conservation during dense pickup;
- bounded active gems;
- bounded creates/removes per second;
- no combat-time image loads;
- no camera-motion p95 regression beyond the agreed budget.

## Verification Policy

During implementation:

- run the smallest relevant test after every red/green cycle;
- run targeted `flutter analyze` when interfaces change;
- use local Chrome development and hot reload for camera and HUD checks;
- do not open an external tunnel;
- do not run Android or iOS builds.

At final completion only:

1. `flutter analyze`
2. full `flutter test`
3. `flutter build web`

The known Windows `impellerc` crash must be reported honestly if it prevents a
clean final command. Reusing a previously compiled shader may support a local
preview, but it does not count as a successful clean `flutter build web`.

## Explicit Non-goals

- treasure chest components, rewards, UI, or opening logic;
- permanent training or meta-progression changes;
- new characters, weapons, augments, or balance changes;
- simultaneous actor-size and camera-zoom changes;
- pre-spawning a map-wide enemy population;
- global pooling without measured evidence;
- graphics-quality reduction without profiling;
- an externally accessible preview tunnel.

## Completion Criteria

The milestone is complete when:

- combat actors use real world coordinates under `CombatWorld`;
- the `2048 × 5120` world is traversable and visually bounded;
- zoom 0.90 tracking is smooth, dead-zoned, and clamped;
- static background uses deterministic chunk/batch rendering;
- spatial activity tiers and enemy sleeping/recycle behavior are observable;
- experience total is conserved through merge/compress/restore/consume;
- pickup animation grants experience exactly once;
- the compact screen-space HUD meets the required mobile information surface;
- debug overlays and required metrics work only in development;
- before/after fixed-seed performance and Chrome timing are reported;
- the required targeted and final verification commands have been run and
  their actual results recorded.
