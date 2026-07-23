# Stage and Missing Enemy Art Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Use the imagegen skill for authored PNG production. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace temporary stage imagery with deterministic batched tiles, decals, and props, and give eight runtime enemy types unique 4×4 animation sheets.

**Architecture:** A stage visual specification selects static tile and decoration assets by stage ID and seed; one component builds immutable batches at load time. Enemy sheets retain the existing 4×4 animation state contract while moving to 128px cells and unique paths in `EnemySpriteSheet.specs`.

**Tech Stack:** Flutter, Dart, Flame `SpriteBatch`, RGBA PNG sheets, `flutter_test`, OpenAI image generation.

## Global Constraints

- Complete the VFX foundation plan before this plan; stage and enemy art may be produced independently but runtime edits remain sequential.
- Do not add a tilemap or rendering package.
- Do not create, remove, or update individual tile components every frame.
- Stage decoration must not own collision or alter spawn/navigation rules.
- Enemy frames remain move 0–3, attack 4–7, hit 8–9, death 10–15.
- Enemy runtime sheets use 128×128 cells in a 4×4, 512×512 transparent RGBA PNG.
- Do not complete a missing enemy by copying an existing enemy image.
- Delegated image/runtime writing uses explicit Terra; read-only contract QA uses explicit Luna; no subagent uses Sol.

---

### Task 1: Define Static Stage Visual Contracts

**Files:**
- Create: `lib/game/content/stage_visual_spec.dart`
- Create: `lib/game/components/stage_tile_batch_component.dart`
- Test: `test/game/stage_visual_spec_test.dart`
- Test: `test/game/stage_tile_batch_component_test.dart`

**Interfaces:**
- Consumes: stage ID, integer seed, visible world rectangle, and a fixed `StageVisualSpec.seedSalt`.
- Produces: `StageVisualSpec`, `StageTilePlacement`, `StageDecorationPlacement`, and load-time-only `StageTileBatchComponent`.

- [ ] **Step 1: Write failing determinism tests**

```dart
test('same stage and seed produce identical placements', () {
  final a = StageLayout.build(spec, seed: 3107, bounds: bounds);
  final b = StageLayout.build(spec, seed: 3107, bounds: bounds);
  expect(a.tiles, b.tiles);
  expect(a.decorations, b.decorations);
});

test('stage batch does no per-frame allocation work', () {
  final component = StageTileBatchComponent(layout: layout, images: images);
  final before = component.placementBuildCount;
  component.update(1 / 60);
  expect(component.placementBuildCount, before);
  expect(component.ownsCollision, isFalse);
});
```

- [ ] **Step 2: Verify tests fail**

Run: `flutter test test/game/stage_visual_spec_test.dart test/game/stage_tile_batch_component_test.dart`

Expected: stage contract types are absent.

- [ ] **Step 3: Implement deterministic layout**

Use `Random(seed ^ spec.seedSalt)` only during construction; assign permanent integer salts in the two stage specs so results do not depend on runtime string hashing. Fill bounds with a base tile grid, select 2–4 variants, and place sparse decals. Restrict props to an edge band and store all placements in unmodifiable lists.

- [ ] **Step 4: Build batches once**

Construct one `SpriteBatch` per atlas/image during `onLoad`; `render` calls each batch and `update` performs no layout or sprite creation.

- [ ] **Step 5: Run and commit**

Run: `flutter test test/game/stage_visual_spec_test.dart test/game/stage_tile_batch_component_test.dart`

Expected: deterministic equality and static-build assertions pass.

```powershell
git add lib/game/content/stage_visual_spec.dart lib/game/components/stage_tile_batch_component.dart test/game/stage_visual_spec_test.dart test/game/stage_tile_batch_component_test.dart
git commit -m "feat: define deterministic stage visual batches"
```

### Task 2: Produce Stage Tiles, Decals, and Props

**Files:**
- Create: `assets/images/tiles/moonlit_office_tiles_128.png`
- Create: `assets/images/tiles/plague_market_tiles_128.png`
- Create: `assets/images/props/moonlit_office_props_128.png`
- Create: `assets/images/props/plague_market_props_128.png`
- Create: `art_source/generated/stages/`
- Modify: `lib/game/content/stage_visual_spec.dart`
- Modify: `lib/game/content/asset_catalog.dart`
- Modify: `docs/assets/asset-rights-ledger.csv`
- Modify: `pubspec.yaml`
- Test: `test/game/stage_visual_asset_contract_test.dart`

**Interfaces:**
- Consumes: two current stage IDs and approved Joseon style.
- Produces: stage-specific atlas contracts and rights records.

- [ ] **Step 1: Write the failing stage asset test**

```dart
for (final stageId in [moonlitAbandonedOffice, plagueMarket]) {
  final spec = stageVisualSpecFor(stageId);
  expect(File('assets/images/${spec.tileAssetKey}').existsSync(), isTrue);
  expect(File('assets/images/${spec.propAssetKey}').existsSync(), isTrue);
  expect(spec.tileVariants, inInclusiveRange(2, 4));
}
```

- [ ] **Step 2: Verify missing assets fail**

Run: `flutter test test/game/stage_visual_asset_contract_test.dart`

Expected: the first missing stage atlas is reported.

- [ ] **Step 3: Generate and review stage art**

Use imagegen for moonlit government-office courtyard stone/packed-earth tiles, cracks, leaves, paper fragments, Jangseung/roof/lantern/grass edge props; and plague-market dirt/stone tiles, stains, abandoned baskets, torn awnings, herb bundles, and edge debris. Reject readable shop signs, full scenes with perspective baked into tiles, opaque padding, and props that imply collision.

- [ ] **Step 4: Normalize and record**

Export RGBA atlases with exact 128px cells, update specs and catalog paths, add assets directories to `pubspec`, and append source/hash/status/runtime-use ledger rows.

- [ ] **Step 5: Validate and commit**

Run: `flutter test test/game/stage_visual_asset_contract_test.dart test/game/asset_rights_policy_test.dart`

Expected: both stages resolve unique valid assets with complete rights records.

```powershell
git add assets/images/tiles assets/images/props art_source/generated/stages lib/game/content/stage_visual_spec.dart lib/game/content/asset_catalog.dart docs/assets/asset-rights-ledger.csv pubspec.yaml test/game/stage_visual_asset_contract_test.dart
git commit -m "art: add Joseon stage tile and prop sets"
```

### Task 3: Connect Static Stage Batches

**Files:**
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `lib/game/content/combat_asset_preloader.dart`
- Test: `test/game/pixel_survivor_game_loop_test.dart`
- Test: `test/game/stage_tile_batch_component_test.dart`

**Interfaces:**
- Consumes: current `stageId`, stage specs, preloaded stage images.
- Produces: one background batch component per run below combat actors.

- [ ] **Step 1: Add the failing integration test**

```dart
await game.ready();
expect(game.children.whereType<StageTileBatchComponent>(), hasLength(1));
final stage = game.children.whereType<StageTileBatchComponent>().single;
expect(stage.priority, lessThan(0));
expect(stage.stageId, moonlitAbandonedOffice);
```

- [ ] **Step 2: Verify failure**

Run: `flutter test test/game/pixel_survivor_game_loop_test.dart`

Expected: no stage batch component exists.

- [ ] **Step 3: Preload and mount**

Add the selected stage tile/prop keys to the preloader request. Mount `StageTileBatchComponent` after preload and before actors. Use run seed plumbing already present in deterministic tests; do not use the weapon or wave RNG instance.

- [ ] **Step 4: Confirm no gameplay ownership**

Add assertions that enemy spawn positions, collision counts, and run seed simulation results match the pre-stage baseline.

- [ ] **Step 5: Run and commit**

Run: `flutter test test/game/stage_tile_batch_component_test.dart test/game/pixel_survivor_game_loop_test.dart test/game/five_minute_run_simulation_test.dart`

Expected: all pass and only presentation component counts change.

```powershell
git add lib/game/pixel_survivor_game.dart lib/game/content/combat_asset_preloader.dart test/game/pixel_survivor_game_loop_test.dart test/game/stage_tile_batch_component_test.dart
git commit -m "feat: render stages with static sprite batches"
```

### Task 4: Lock Eight Unique Enemy Briefs and Contracts

**Files:**
- Create: `docs/assets/prompts/missing-eight-enemy-sheets.md`
- Modify: `lib/game/content/sprite_atlas_contract.dart`
- Test: `test/game/missing_enemy_visual_contract_test.dart`

**Interfaces:**
- Consumes: eight enemy IDs.
- Produces: one silhouette/color/prop/attack brief and one 512×512 contract per ID.

- [ ] **Step 1: Write the failing coverage test**

```dart
const missingEight = {
  sakkatSpecter,
  plagueCrow,
  spearBandit,
  rottenHerbalist,
  graveEmber,
  blackHatAssassin,
  brokenJangseungSpirit,
  sorrowfulMaidenGhost,
};
expect(missingEightVisualContracts.keys.toSet(), missingEight);
for (final contract in missingEightVisualContracts.values) {
  expect(contract.pixelWidth, 512);
  expect(contract.pixelHeight, 512);
}
```

- [ ] **Step 2: Verify failure**

Run: `flutter test test/game/missing_enemy_visual_contract_test.dart`

Expected: the visual contract map is absent.

- [ ] **Step 3: Write exact briefs**

For each ID record unique silhouette, main/accent colors, weapon or prop, attack direction, death motion, and prohibited overlap with existing enemies. Include the shared frame order and transparent-background rule in the prompt document.

- [ ] **Step 4: Add contracts**

Register paths `assets/images/enemies/<enemy_id>_128.png`, 128px cells, 4 columns, 4 rows, transparency required, and temporary status.

- [ ] **Step 5: Run and commit**

Run: `flutter test test/game/missing_enemy_visual_contract_test.dart test/game/sprite_atlas_contract_test.dart`

Expected: exactly eight complete contracts.

```powershell
git add docs/assets/prompts/missing-eight-enemy-sheets.md lib/game/content/sprite_atlas_contract.dart test/game/missing_enemy_visual_contract_test.dart
git commit -m "docs: lock missing enemy sprite contracts"
```

### Task 5: Generate and Connect Eight Enemy Sheets

**Files:**
- Create: `assets/images/enemies/*_128.png` for the eight contracted IDs
- Create: `art_source/generated/enemies/`
- Modify: `lib/game/components/enemy_component.dart`
- Modify: `lib/game/content/asset_catalog.dart`
- Modify: `docs/assets/asset-rights-ledger.csv`
- Modify: `pubspec.yaml`
- Test: `test/game/enemy_component_test.dart`
- Test: `test/game/missing_enemy_visual_contract_test.dart`
- Test: `test/game/content_integrity_test.dart`

**Interfaces:**
- Consumes: shared frame order and Task 4 briefs.
- Produces: unique 4×4 sheets registered in both `AssetCatalog.enemies` and `EnemySpriteSheet.specs`.

- [ ] **Step 1: Change the old negative assertion**

Replace the existing assertion that `EnemySpriteSheet.specs` excludes `sakkatSpecter` with:

```dart
expect(EnemySpriteSheet.specs.keys, containsAll(missingEight));
for (final id in missingEight) {
  expect(EnemySpriteSheet.specs[id]!.frameSize, 128);
  expect(AssetCatalog.enemies[id], 'assets/images/enemies/${id}_128.png');
}
```

- [ ] **Step 2: Verify failure**

Run: `flutter test test/game/enemy_component_test.dart test/game/missing_enemy_visual_contract_test.dart`

Expected: all eight specs or files are missing.

- [ ] **Step 3: Generate and inspect sheets**

Use imagegen per enemy brief. Require the same character identity and ground anchor across 16 cells. Inspect each sheet at original resolution for duplicated poses, broken weapons, direction changes, clipped alpha, text, and non-transparent backgrounds.

- [ ] **Step 4: Normalize and connect**

Export exact 512×512 RGBA files, add unique catalog paths and `EnemySpriteSpec(assetKey: 'enemies/<id>_128.png', frameSize: 128)`, and record hashes and provenance.

- [ ] **Step 5: Validate state animation**

Run: `flutter test test/game/missing_enemy_visual_contract_test.dart test/game/enemy_component_test.dart test/game/enemy_behavior_controller_test.dart test/game/content_integrity_test.dart`

Expected: all sheets pass PNG and alpha checks; move/attack/hit/death frame sequences remain unchanged.

- [ ] **Step 6: Commit**

```powershell
git add assets/images/enemies art_source/generated/enemies lib/game/components/enemy_component.dart lib/game/content/asset_catalog.dart docs/assets/asset-rights-ledger.csv pubspec.yaml test/game/enemy_component_test.dart test/game/missing_enemy_visual_contract_test.dart test/game/content_integrity_test.dart
git commit -m "art: add eight unique enemy sprite sheets"
```

## Plan Exit Gate

- Both stages render unique static image batches without per-frame layout work.
- The eight listed enemies no longer reuse old catalog paths and all animate from unique 4×4 sheets.
- Stage visuals do not change collision, spawn, navigation, or deterministic simulation results.
- All source assets, runtime files, hashes, and rights states are recorded.
