# Combat VFX Gallery and Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Use the imagegen skill for authored PNG production. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Migrate the remaining player, status, projectile, and enemy combat visuals from primary Canvas geometry to registry-backed image components and expose those real components in a debug-only gallery.

**Architecture:** Extend the approved `AttackVisualRegistry` rather than creating per-screen maps. Shared specialized components render projectiles, areas, enemy telegraphs, and attached statuses from preloaded images. The gallery invokes those same production factories and adds only debug controls and overlays.

**Tech Stack:** Flutter, Dart, Flame, `flutter_test`, widget tests, RGBA PNG sprite sheets, OpenAI image generation.

## Global Constraints

- Complete `2026-07-23-combat-vfx-foundation-hwando.md` first.
- Keep damage, collision, hazard, cooldown, and AI timing in existing gameplay systems.
- Images must be original generated art, transparent RGBA, text-free, and recorded in `docs/assets/asset-rights-ledger.csv`.
- Geometric hitbox outlines may appear only behind an explicit debug toggle.
- Gallery and combat must use identical registry entries, factories, and component classes.
- Gallery access must be guarded by `kDebugMode`.
- Delegated writing uses explicit `gpt-5.6-terra`; read-only QA uses explicit `gpt-5.6-luna`; no subagent uses Sol.
- Run focused tests only; final full validation belongs to the final plan.

---

## File Map

- Create `lib/game/components/projectile_vfx_component.dart`, `area_vfx_component.dart`, `enemy_telegraph_vfx_component.dart`, `status_marker_vfx_component.dart`.
- Create `lib/game/content/combat_visual_factory.dart`: production component creation by registry category.
- Create `lib/app/vfx_gallery_screen.dart` and `lib/game/vfx_gallery_game.dart`: debug-only gallery shell and Flame preview.
- Modify current projectile, ward, frost, talisman, hazard, projectile, overlay components to delegate presentation without moving gameplay logic.
- Extend `assets/images/vfx/`, `assets/images/projectiles/`, and `assets/images/zones/`.

### Task 1: Add Category Factories and Component Contracts

**Files:**
- Create: `lib/game/content/combat_visual_factory.dart`
- Create: `lib/game/components/registry_vfx_component.dart`
- Create: `lib/game/components/projectile_vfx_component.dart`
- Create: `lib/game/components/area_vfx_component.dart`
- Create: `lib/game/components/enemy_telegraph_vfx_component.dart`
- Create: `lib/game/components/status_marker_vfx_component.dart`
- Test: `test/game/combat_visual_factory_test.dart`

**Interfaces:**
- Consumes: `AttackVisualEvent`, registry category, preloaded image map.
- Produces: `CombatVisualFactory.create`, testable `CombatVisualFactory.createFromSpec`, shared `RegistryVfxComponent`, `ProjectileVfxComponent`, `AreaVfxComponent`, `EnemyTelegraphVfxComponent`, `StatusMarkerVfxComponent`.

- [ ] **Step 1: Write the failing dispatch test**

```dart
test('factory dispatches each visual category', () {
  expect(factory.create(projectileEvent), isA<ProjectileVfxComponent>());
  expect(factory.create(areaEvent), isA<AreaVfxComponent>());
  expect(factory.create(telegraphEvent), isA<EnemyTelegraphVfxComponent>());
  expect(factory.create(statusEvent), isA<StatusMarkerVfxComponent>());
});
```

- [ ] **Step 2: Verify failure**

Run: `flutter test test/game/combat_visual_factory_test.dart`

Expected: compilation fails for missing factory and components.

- [ ] **Step 3: Implement explicit category dispatch**

```dart
PositionComponent create(AttackVisualEvent event) {
  final spec = AttackVisualRegistry.byId(event.effectId);
  return createFromSpec(event, spec);
}

PositionComponent createFromSpec(
  AttackVisualEvent event,
  AttackVisualSpec spec,
) {
  return switch (spec.category) {
    CombatVisualCategory.hwando => HwandoVfxComponent(
        event: event, images: images),
    CombatVisualCategory.projectile => ProjectileVfxComponent(
        event: event, spec: spec, images: images),
    CombatVisualCategory.area => AreaVfxComponent(
        event: event, spec: spec, images: images),
    CombatVisualCategory.telegraph => EnemyTelegraphVfxComponent(
        event: event, spec: spec, images: images),
    CombatVisualCategory.status => StatusMarkerVfxComponent(
        event: event, spec: spec, images: images),
  };
}
```

`createFromSpec` is the seam for focused category tests before later tasks register real non-Hwando IDs; production calls `create(event)`. `RegistryVfxComponent` owns shared cached layers, finite progress, rendering, expiry, and exactly-once callback behavior. The four category classes remain thin named specializations and may override only category-specific transform/layer behavior. They never query enemies or decide damage.

- [ ] **Step 4: Test lifetime cleanup**

Add one test per component type that advances beyond duration and verifies it removes itself and calls expiry once.

- [ ] **Step 5: Run and commit**

Run: `flutter test test/game/combat_visual_factory_test.dart`

Expected: all dispatch and lifecycle tests pass.

```powershell
git add lib/game/content/combat_visual_factory.dart lib/game/components/registry_vfx_component.dart lib/game/components/projectile_vfx_component.dart lib/game/components/area_vfx_component.dart lib/game/components/enemy_telegraph_vfx_component.dart lib/game/components/status_marker_vfx_component.dart test/game/combat_visual_factory_test.dart
git commit -m "feat: add specialized combat visual components"
```

### Task 2: Produce Player and Status VFX Assets

**Files:**
- Create: `assets/images/vfx/player/`
- Create: `assets/images/projectiles/player/`
- Create: `assets/images/zones/player/`
- Create: `art_source/generated/player_vfx/`
- Modify: `lib/game/content/attack_visual_registry.dart`
- Modify: `lib/game/content/sprite_atlas_contract.dart`
- Modify: `lib/game/content/asset_catalog.dart`
- Modify: `docs/assets/asset-rights-ledger.csv`
- Modify: `pubspec.yaml`
- Test: `test/game/player_visual_asset_contract_test.dart`

**Interfaces:**
- Consumes: IDs for sealing slash, wind-thunder fan, singijeon, Jangseung ward, five-color ward, frost field, talisman attach/transfer.
- Produces: normalized runtime sheets and ready registry contracts.

Use these exact single-layer contracts:

| Effect ID | Category | Runtime key | Frames | Rotation |
| --- | --- | --- | ---: | --- |
| `sealing_slash` | `hwando` | `vfx/player/sealing_slash_128.png` | 6 | yes |
| `wind_thunder_fan` | `area` | `vfx/player/wind_thunder_fan_128.png` | 6 | yes |
| `singijeon_volley` | `projectile` | `projectiles/player/singijeon_128.png` | 4 | yes |
| `jangseung_ward` | `area` | `zones/player/jangseung_ward_128.png` | 8 | no |
| `frost_flask` | `area` | `zones/player/frost_field_128.png` | 8 | no |
| `talisman_attachment` | `status` | `vfx/player/talisman_attachment_128.png` | 4 | no |
| `talisman_transfer` | `status` | `vfx/player/talisman_transfer_128.png` | 6 | yes |
| `talisman_explosion` | `area` | `vfx/player/talisman_explosion_128.png` | 6 | no |
| `talisman_small_ward` | `area` | `zones/player/talisman_ward_128.png` | 8 | no |
| `talisman_master_ward` | `area` | `zones/player/talisman_ward_128.png` | 8 | no |

`talisman_small_ward` and `talisman_master_ward` intentionally share the same authored sheet and differ later by gameplay radius and presentation scale. Every sheet uses 128×128 cells in one horizontal row.

- [ ] **Step 1: Write the failing required-ID test**

```dart
test('all player combat IDs have non-missing visual specs', () {
  for (final id in requiredPlayerVisualIds) {
    final spec = AttackVisualRegistry.byId(id);
    expect(spec.status, isNot(AttackVisualStatus.missing), reason: id);
    expect(spec.layers, isNotEmpty, reason: id);
  }
});
```

- [ ] **Step 2: Verify registry gaps fail**

Run: `flutter test test/game/player_visual_asset_contract_test.dart`

Expected: failure names the first unregistered player visual ID.

- [ ] **Step 3: Generate the asset batch**

Use built-in imagegen on a flat removable chroma-key background to create the nine distinct sheets named above: sealing paper-cut slash, wind-and-lightning fan trail, Singijeon rocket and fire tail, carved Jangseung ward ring, frost-field edge/crystals, talisman attachment, transfer streak, talisman explosion, and five-color talisman ward. Inspect at original resolution and reject text-like seals, clipped/crossing frames, opaque backgrounds, or effects that obscure actors.

- [ ] **Step 4: Normalize and register**

Export to the three runtime directories by category. Add the ten registry IDs, nine exact `SpriteAtlasContract` entries, `AssetCatalog.effects` paths, and `pubspec.yaml` directory entries for `assets/images/projectiles/` and `assets/images/zones/`. Use center anchors, full `0..1` layer spans, and the rotation values in the table. Record SHA-256 and provenance in the ledger.

- [ ] **Step 5: Validate and commit**

Run: `flutter test test/game/player_visual_asset_contract_test.dart test/game/attack_visual_registry_test.dart test/game/asset_rights_policy_test.dart`

Expected: every required player ID resolves to valid RGBA files with ledger records.

```powershell
git add assets/images/vfx/player assets/images/projectiles/player assets/images/zones/player art_source/generated/player_vfx lib/game/content/attack_visual_registry.dart lib/game/content/sprite_atlas_contract.dart lib/game/content/asset_catalog.dart docs/assets/asset-rights-ledger.csv pubspec.yaml test/game/player_visual_asset_contract_test.dart
git commit -m "art: add player combat visual assets"
```

### Task 3: Connect Player and Status Components

**Files:**
- Modify: `lib/game/components/projectile_component.dart`
- Modify: `lib/game/components/ward_aura_component.dart`
- Modify: `lib/game/components/five_color_ward_component.dart`
- Modify: `lib/game/components/frost_field_component.dart`
- Modify: `lib/game/components/talisman_presentation_component.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Test: `test/game/projectile_component_test.dart`
- Test: `test/game/five_color_ward_component_test.dart`
- Test: `test/game/frost_field_component_test.dart`
- Test: `test/game/talisman_presentation_component_test.dart`

**Interfaces:**
- Consumes: preloaded images and factory components from Task 1.
- Produces: image-backed player projectile, zone, and status visuals without gameplay changes.

- [ ] **Step 1: Add failing presentation assertions**

```dart
expect(component.usesRegistryVisual, isTrue);
expect(component.startsImageLoadOnMount, isFalse);
expect(component.ownsDamageResolution, isFalse);
```

Add these assertions to the relevant component tests, using test-visible getters rather than source-text matching.

- [ ] **Step 2: Verify old behavior fails**

Run: `flutter test test/game/projectile_component_test.dart test/game/five_color_ward_component_test.dart test/game/frost_field_component_test.dart test/game/talisman_presentation_component_test.dart`

Expected: assertions fail for geometric or on-mount image paths.

- [ ] **Step 3: Delegate rendering**

Keep existing position, hit, slow, transfer, and lifetime calculations. Replace each primary Canvas drawing block with a child or composed specialized VFX component supplied from cached images. Retain only debug boundary drawing behind `showCombatHitboxes`.

- [ ] **Step 4: Check gameplay parity**

Run: `flutter test test/game/projectile_component_test.dart test/game/five_color_ward_component_test.dart test/game/frost_field_component_test.dart test/game/talisman_executor_test.dart test/game/talisman_presentation_component_test.dart test/game/weapon_synergy_resolver_test.dart`

Expected: all pass with identical hit counts, slow fractions, transfers, and expiry.

- [ ] **Step 5: Commit**

```powershell
git add lib/game/components/projectile_component.dart lib/game/components/ward_aura_component.dart lib/game/components/five_color_ward_component.dart lib/game/components/frost_field_component.dart lib/game/components/talisman_presentation_component.dart lib/game/pixel_survivor_game.dart test/game/projectile_component_test.dart test/game/five_color_ward_component_test.dart test/game/frost_field_component_test.dart test/game/talisman_presentation_component_test.dart
git commit -m "feat: migrate player combat visuals to sprites"
```

### Task 4: Produce and Connect Enemy VFX

**Files:**
- Create: `assets/images/vfx/enemy/`
- Create: `assets/images/projectiles/enemy/`
- Create: `art_source/generated/enemy_vfx/`
- Modify: `lib/game/content/attack_visual_registry.dart`
- Modify: `lib/game/components/enemy_hazard_component.dart`
- Modify: `lib/game/components/enemy_projectile_component.dart`
- Modify: `lib/game/components/enemy_combat_overlay_component.dart`
- Modify: `lib/game/components/enemy_component.dart`
- Test: `test/game/enemy_visual_asset_contract_test.dart`
- Test: `test/game/enemy_hazard_component_test.dart`
- Test: `test/game/enemy_projectile_component_test.dart`
- Test: `test/game/enemy_combat_overlay_component_test.dart`

**Interfaces:**
- Consumes: poison, shockwave, scream, telegraph, shield, and enemy projectile gameplay data.
- Produces: image-backed enemy effects whose visible danger boundary never understates the gameplay area.

**Locked enemy visual contracts:**

| Effect ID | Category | Runtime asset key | Frames | Rotate |
| --- | --- | --- | ---: | --- |
| `enemy_poison_pool` | area | `vfx/enemy/poison_pool_128.png` | 8 | no |
| `enemy_shockwave` | area | `vfx/enemy/shockwave_128.png` | 6 | no |
| `enemy_spirit_scream` | area | `vfx/enemy/spirit_scream_128.png` | 6 | no |
| `enemy_line_telegraph` | telegraph | `vfx/enemy/line_telegraph_128.png` | 6 | yes |
| `enemy_ranged_telegraph` | telegraph | `vfx/enemy/ranged_telegraph_128.png` | 6 | yes |
| `enemy_radial_telegraph` | telegraph | `vfx/enemy/radial_telegraph_128.png` | 8 | no |
| `enemy_shield_block_flash` | status | `vfx/enemy/shield_block_flash_128.png` | 5 | yes |
| `sakkat_spirit_projectile` | projectile | `projectiles/enemy/sakkat_spirit_projectile_128.png` | 4 | yes |

All sheets use one horizontal row of 128x128 transparent RGBA cells,
`generatedReview`, center anchors, priority offset zero, and full `0..1`
layer spans. `EnemyHazardKind.warning` is unused and does not receive a
separate asset. Line telegraphs cover dash, double-dash, dive, and thrust;
ranged covers the Sakkat specter; radial is shared by shockwave and scream.

Danger presentation scales are derived from gameplay geometry rather than
added to the registry. With the current 24px player collision size, poison,
shockwave, and scream render to at least `(damageRadius + 12) * 2`, or
100px, 200px, and 264px respectively. Line telegraphs extend beyond their
profile range by the enemy-plus-player collision radii and keep visible side
and end caps. The Sakkat projectile visual is at least 34x34 while its 10px
gameplay hitbox remains unchanged. Preparation edges stay readable on both
the moonlit blue and plague olive stage palettes; normal rendering never
removes the high-contrast danger boundary.

- [ ] **Step 1: Write failing visual coverage and boundary tests**

```dart
for (final id in requiredEnemyVisualIds) {
  expect(AttackVisualRegistry.byId(id).status,
      isNot(AttackVisualStatus.missing), reason: id);
}
expect(telegraph.visualRadius, greaterThanOrEqualTo(telegraph.damageRadius));
```

- [ ] **Step 2: Verify failures**

Run: `flutter test test/game/enemy_visual_asset_contract_test.dart test/game/enemy_hazard_component_test.dart test/game/enemy_combat_overlay_component_test.dart`

Expected: missing registry IDs and old presentation assertions fail.

- [ ] **Step 3: Generate and normalize enemy effects**

Use imagegen for poison vapor/pool, ground shockwave, spirit scream, low-alpha preparation edges, high-contrast impact, shield direction/block flash, and enemy projectile families. Keep telegraphs readable on both stage palettes and free of readable text.

- [ ] **Step 4: Connect components without moving rules**

Enemy behavior continues to select warning/active timing and hazard geometry. Presentation components receive snapshots and cached images. Preserve existing damage and collision tests; remove full-body geometric overlays from the normal render path.

- [ ] **Step 5: Validate and commit**

Run: `flutter test test/game/enemy_visual_asset_contract_test.dart test/game/enemy_hazard_component_test.dart test/game/enemy_projectile_component_test.dart test/game/enemy_combat_overlay_component_test.dart test/game/enemy_behavior_controller_test.dart`

Expected: all pass; warning duration, damage radius, shield angle, and projectile collisions are unchanged.

```powershell
git add assets/images/vfx/enemy assets/images/projectiles/enemy art_source/generated/enemy_vfx lib/game/content/attack_visual_registry.dart lib/game/components/enemy_hazard_component.dart lib/game/components/enemy_projectile_component.dart lib/game/components/enemy_combat_overlay_component.dart lib/game/components/enemy_component.dart docs/assets/asset-rights-ledger.csv pubspec.yaml test/game/enemy_visual_asset_contract_test.dart test/game/enemy_hazard_component_test.dart test/game/enemy_projectile_component_test.dart test/game/enemy_combat_overlay_component_test.dart
git commit -m "feat: migrate enemy combat visuals to sprites"
```

### Task 5: Build the Debug-Only VFX Gallery

**Files:**
- Create: `lib/app/vfx_gallery_screen.dart`
- Create: `lib/game/vfx_gallery_game.dart`
- Modify: `lib/app/pixel_survivor_app.dart`
- Test: `test/app/vfx_gallery_screen_test.dart`
- Test: `test/game/vfx_gallery_game_test.dart`

**Interfaces:**
- Consumes: `AttackVisualRegistry`, `CombatVisualFactory`.
- Produces: debug-only navigation and controls for speed, loop, direction, background, actor, hitbox, anchor, frame, and component count.

- [ ] **Step 1: Write failing widget and factory-identity tests**

```dart
expect(find.byKey(const Key('vfx-speed-025')), findsOneWidget);
expect(find.byKey(const Key('vfx-direction-7')), findsOneWidget);
expect(find.byKey(const Key('vfx-hitbox-toggle')), findsOneWidget);
expect(gallery.factory.runtimeType, CombatVisualFactory);
```

- [ ] **Step 2: Verify failure**

Run: `flutter test test/app/vfx_gallery_screen_test.dart test/game/vfx_gallery_game_test.dart`

Expected: gallery types and controls are absent.

- [ ] **Step 3: Implement gallery controls**

Create one selected registry ID, replay mode, `timeScale` values `.25`, `.5`, `1`, eight normalized directions, light/dark backgrounds, and debug overlay flags. Display current frame and active component count as Flutter text, never as baked image text.

- [ ] **Step 4: Guard release access**

Register the route and development entry point only inside `if (kDebugMode)`. Add a test under release-style constant evaluation that the production navigation list excludes the gallery entry.

- [ ] **Step 5: Run and commit**

Run: `flutter test test/app/vfx_gallery_screen_test.dart test/game/vfx_gallery_game_test.dart test/app/release_flow_integration_test.dart`

Expected: gallery works in tests and release navigation has no entry.

```powershell
git add lib/app/vfx_gallery_screen.dart lib/game/vfx_gallery_game.dart lib/app/pixel_survivor_app.dart test/app/vfx_gallery_screen_test.dart test/game/vfx_gallery_game_test.dart
git commit -m "feat: add debug combat VFX gallery"
```

## Plan Exit Gate

- All listed player, status, enemy, projectile, and telegraph effects have non-missing registry entries and valid PNG contracts.
- Normal rendering does not use geometric shapes as the primary combat effect.
- Gallery and combat create components through the same factory.
- Focused gameplay tests prove damage, timing, collision, slow, and transfer behavior are unchanged.
