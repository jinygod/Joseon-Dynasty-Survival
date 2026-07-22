# Combat VFX and Progress HUD Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove placeholder rectangles and primitive-only attacks, add a high-resolution bandit, make all current weapon and hazard families visually authored, enlarge experience gems, and expose a prominent level/XP header.

**Architecture:** Keep hit detection and balance in the existing attack, projectile, field, and progression models. Add deterministic bounded VFX drawing helpers consumed by presentation components, make runtime enemy sprite mapping total for stage content, and let HUD consume the already-existing level/XP getters. Raster generation is limited to the bandit atlas; other spectacle is code-native and geometry-driven.

**Tech Stack:** Flutter 3 / Dart 3, Flame components, `dart:ui` Canvas, Flutter widget/golden tests, existing 4×4 sprite-atlas contracts.

## Global Constraints

- Preserve existing weapon IDs, enemy IDs, save data, damage values, health values, pickup radius, and attack geometry.
- Do not copy any commercial character, UI, or effect.
- Keep particle and decoration counts deterministic and bounded for mobile web and Android.
- Do not use full-screen white flashes, continuous shake, or presentation that hides enemy warnings.
- Every production behavior change follows a red-green-refactor test cycle.

---

### Task 1: Total enemy art routing and 128px bandit atlas

**Files:**
- Create: `assets/images/monsters/bandit_128.png`
- Create: `docs/assets/prompts/bandit-balanced-casual-atlas.md`
- Modify: `lib/game/components/enemy_component.dart`
- Modify: `lib/game/content/actor_visual_spec.dart`
- Modify: `lib/game/content/asset_catalog.dart`
- Modify: `lib/game/content/sprite_atlas_contract.dart`
- Modify: `docs/assets/asset-rights-ledger.csv`
- Test: `test/game/enemy_component_test.dart`
- Test: `test/game/content_integrity_test.dart`

**Interfaces:**
- Produces: `EnemySpriteSheet.specs` containing every ID referenced by `stageDefinitions`/wave definitions.
- Produces: `EnemySpriteSpec(assetKey: 'monsters/bandit_128.png', frameSize: 128)` for bandit-family enemies.

- [ ] **Step 1: Write the failing total-mapping and bandit-contract tests**

```dart
final stageEnemyIds = waveDefinitions
    .expand((wave) => wave.enemyWeights.keys)
    .toSet();
expect(EnemySpriteSheet.specs.keys, containsAll(stageEnemyIds));
expect(EnemySpriteSheet.specs[bandit]!.frameSize, 128);
expect(EnemySpriteSheet.specs[bandit]!.assetKey, 'monsters/bandit_128.png');
```

- [ ] **Step 2: Run the focused tests and confirm they fail on the seven missing IDs and 32px bandit**

Run: `flutter test test/game/enemy_component_test.dart test/game/content_integrity_test.dart`

- [ ] **Step 3: Generate and validate the original 4×4 bandit atlas**

Use built-in image generation with the representative player/enemy atlases as style references. Generate on a flat chroma key, remove the key with the installed helper, and validate 512×512 RGBA, transparent corners, 16 occupied frames, and readable Joseon bandit silhouette.

- [ ] **Step 4: Make sprite routing total and replace the rectangle fallback**

Map bandit-family IDs to `bandit_128.png`, spirit-family IDs to reviewed 128px spirit atlases, anomaly IDs to reviewed dokkaebi/family atlases, and plague IDs to the reviewed plague atlas. Replace the rectangle fallback with an outlined circular head/body folk-spirit silhouette made from paths so asynchronous load failures never show a square.

- [ ] **Step 5: Update catalogs, rights records, and focused tests**

Run: `flutter test test/game/enemy_component_test.dart test/game/content_integrity_test.dart test/game/actor_visual_spec_test.dart`

- [ ] **Step 6: Commit**

```text
feat: replace placeholder enemies with authored sprite routing
```

### Task 2: Deterministic shared VFX primitives

**Files:**
- Create: `lib/game/combat/combat_vfx_primitives.dart`
- Test: `test/game/combat_vfx_primitives_test.dart`

**Interfaces:**
- Produces: `CombatVfxTier { normal, strong, master }`.
- Produces: `CombatVfxPrimitives.drawTaperedTrail`, `drawRadialBurst`, `drawRuneRing`, `drawCrystal`, `drawChevronLane`, and `drawSmokePuff`.
- All helpers consume a `Canvas`, exact geometry, palette, normalized progress, and a capped count; none own gameplay state.

- [ ] **Step 1: Write failing tests for tier scale and capped deterministic sample generation**

```dart
expect(CombatVfxTier.master.scale, greaterThan(CombatVfxTier.normal.scale));
expect(radialSamples(count: 99).length, CombatVfxPrimitives.maxBurstSamples);
expect(radialSamples(count: 8), radialSamples(count: 8));
```

- [ ] **Step 2: Run the focused test and confirm missing API failures**

Run: `flutter test test/game/combat_vfx_primitives_test.dart`

- [ ] **Step 3: Implement pure sample generation and bounded Canvas helpers**

Use filled `Path` ribbons instead of single strokes for attack bodies, keep glow to a small number of layers, and derive every point from fixed indices plus progress rather than randomness.

- [ ] **Step 4: Run focused tests and static analysis for the new file**

Run: `flutter test test/game/combat_vfx_primitives_test.dart`

- [ ] **Step 5: Commit**

```text
feat: add bounded combat vfx drawing primitives
```

### Task 3: Frost-field spectacle and mastery distinction

**Files:**
- Modify: `lib/game/components/frost_field_component.dart`
- Modify: `lib/game/systems/weapon_system.dart`
- Test: `test/game/frost_field_component_test.dart`
- Test: `test/game/weapon_system_test.dart`

**Interfaces:**
- `FrostFieldComponent` gains `CombatVfxTier tier` with default `normal`.
- `WeaponSystem` supplies `master` at weapon level 6 and `strong` at levels 4–5 without altering radius or damage.

- [ ] **Step 1: Write failing tests for visual tier propagation and unchanged hit radius**

```dart
expect(masterField.tier, CombatVfxTier.master);
expect(masterField.radius, normalField.radius);
expect(masterField.containsEnemy(edgeEnemy), normalField.containsEnemy(edgeEnemy));
```

- [ ] **Step 2: Run tests and confirm tier API failures**

Run: `flutter test test/game/frost_field_component_test.dart test/game/weapon_system_test.dart`

- [ ] **Step 3: Implement layered ice rendering**

Render a translucent ice footprint, six-axis snowflake rune, deterministic cracks, eight perimeter crystals, drifting specks, and a tick pulse. Use the component `radius` for every outer coordinate and expose testable `visualTier`/pulse getters without adding test-only production branches.

- [ ] **Step 4: Run focused tests**

Run: `flutter test test/game/frost_field_component_test.dart test/game/weapon_system_test.dart`

- [ ] **Step 5: Commit**

```text
feat: turn frost fields into animated ice sigils
```

### Task 4: Replace primitive player weapon presentations

**Files:**
- Modify: `lib/game/components/attack_effect_component.dart`
- Modify: `lib/game/components/melee_arc_component.dart`
- Modify: `lib/game/components/projectile_component.dart`
- Modify: `lib/game/components/area_attack_component.dart`
- Modify: `lib/game/components/talisman_presentation_component.dart`
- Modify: `lib/game/components/ward_aura_component.dart`
- Modify: `lib/game/components/five_color_ward_component.dart`
- Modify: `lib/game/content/weapon_visual_theme.dart`
- Test: `test/game/attack_effect_component_test.dart`
- Test: `test/game/weapon_system_test.dart`
- Test: `test/game/pixel_survivor_game_loop_test.dart`

**Interfaces:**
- Every weapon ID resolves through `WeaponVfxFamily` and `CombatVfxTier`.
- Presentation derives tier from level/master flags already present in attack/projectile results.
- Exact attack direction/range/radius remains the input for the corresponding visual footprint.

- [ ] **Step 1: Write failing coverage that all twelve weapons have a VFX family and master style**

```dart
for (final weapon in weaponDefinitions) {
  final theme = weaponVisualThemeFor(weapon.id);
  expect(theme.family, isNot(WeaponVfxFamily.neutral), reason: weapon.id);
  expect(theme.masterScale, greaterThan(1), reason: weapon.id);
}
```

- [ ] **Step 2: Confirm focused failures**

Run: `flutter test test/game/weapon_visual_theme_test.dart test/game/attack_effect_component_test.dart test/game/weapon_system_test.dart`

- [ ] **Step 3: Implement authored family rendering**

Replace line-only beams with tapered filled trails and cores; plain arc-only melee with blade ribbons and sparks; plain projectile ovals with family silhouettes and segmented trails; plain area circles with footprint, rune/charge, burst, smoke/shards, and shock rings. Preserve existing optional atlas branches only when they add detail without suppressing the new layers.

- [ ] **Step 4: Add master emphasis without extra damage**

Master variants increase visual scale, afterimage count, head/core contrast, and burst decorations while reusing gameplay geometry. Cap each decoration list and keep enemy-warning alpha visible.

- [ ] **Step 5: Run focused combat tests**

Run: `flutter test test/game/weapon_visual_theme_test.dart test/game/attack_effect_component_test.dart test/game/weapon_system_test.dart test/game/pixel_survivor_game_loop_test.dart`

- [ ] **Step 6: Commit**

```text
feat: give every weapon an authored combat presentation
```

### Task 5: Enemy warnings, hazards, and projectiles

**Files:**
- Modify: `lib/game/components/enemy_combat_overlay_component.dart`
- Modify: `lib/game/components/enemy_hazard_component.dart`
- Modify: `lib/game/components/enemy_projectile_component.dart`
- Modify: `lib/game/components/stage_backdrop_component.dart`
- Test: `test/game/enemy_combat_overlay_component_test.dart`
- Test: `test/game/enemy_hazard_component_test.dart`
- Test: `test/game/enemy_projectile_component_test.dart`

**Interfaces:**
- Warning snapshots continue to supply exact direction, endpoint, range, and progress.
- Hazard rendering continues to use the exact gameplay radius.

- [ ] **Step 1: Write failing tests for authored warning/hazard styles and background contrast**

Assert dash lanes expose chevrons, ranged targets expose reticle rings, poison/shockwave/scream styles are distinct, and decorative backdrop strokes do not reuse warning colors.

- [ ] **Step 2: Run focused tests and confirm failures**

Run: `flutter test test/game/enemy_combat_overlay_component_test.dart test/game/enemy_hazard_component_test.dart test/game/enemy_projectile_component_test.dart`

- [ ] **Step 3: Implement warning lanes and hazard families**

Use low-alpha filled lanes with bright borders/chevrons, multi-ring reticles, directional guard plates, poison puddle lobes/bubbles, shockwave rings/cracks, scream wave bands, and a bright enemy projectile core with tail and outline.

- [ ] **Step 4: Reduce decorative stage-line ambiguity and run focused tests**

Run: `flutter test test/game/enemy_combat_overlay_component_test.dart test/game/enemy_hazard_component_test.dart test/game/enemy_projectile_component_test.dart test/game/stage_backdrop_component_test.dart`

- [ ] **Step 5: Commit**

```text
feat: author readable enemy warnings and hazards
```

### Task 6: Larger value-aware experience gems

**Files:**
- Modify: `lib/game/components/experience_gem_component.dart`
- Test: `test/game/weapon_system_test.dart`
- Test: `test/game/pixel_survivor_game_loop_test.dart`

**Interfaces:**
- Default visual size becomes 20×20.
- `pickupRadius` remains 28.
- `visualScaleForValue(int)` is clamped so merged gems grow and brighten without becoming screen clutter.

- [ ] **Step 1: Write failing size, pickup independence, and value-scale tests**

```dart
final gem = ExperienceGemComponent(experienceValue: 1);
expect(gem.size, Vector2.all(20));
expect(gem.pickupRadius, 28);
gem.absorbExperience(20);
expect(gem.visualScale, greaterThan(1));
```

- [ ] **Step 2: Confirm test failures**

Run: `flutter test test/game/weapon_system_test.dart test/game/pixel_survivor_game_loop_test.dart`

- [ ] **Step 3: Implement a diamond core, white rim, pulse halo, orbiting sparks, and clamped value scaling**

Keep the atlas sprite as the center accent when available and always add the high-resolution halo/outline layers so the gem remains readable on web and mobile.

- [ ] **Step 4: Run focused tests and commit**

```text
feat: make experience drops visible and value aware
```

### Task 7: Prominent level/XP header and queued multi-level choices

**Files:**
- Modify: `lib/app/game_hud.dart`
- Modify: `lib/game/systems/run_progression_system.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Test: `test/app/game_hud_test.dart`
- Test: `test/app/accessibility_surfaces_test.dart`
- Test: `test/app/responsive_layout_test.dart`
- Test: `test/game/run_progression_system_test.dart`
- Test: `test/game/pixel_survivor_game_loop_test.dart`

**Interfaces:**
- Preserve `GameHudSource.playerLevel/currentExperience/experienceToNextLevel`.
- Add stable keys `hud-player-level`, `hud-xp-fill`, and keep `hud-xp-bar`.
- `RunProgressionSystem.addExperience` returns the number of levels gained or exposes it through a result value.
- `PixelSurvivorGame` maintains a bounded pending level-choice count and queues the next choice after the current selection closes.

- [ ] **Step 1: Write failing HUD tests at 390×844**

Require a visible `레벨 1` badge, a 14–18px XP track spanning most available width, numeric XP, SafeArea containment, and a fill fraction matching current/required XP.

- [ ] **Step 2: Write failing progression tests for two thresholds crossed in one collection**

```dart
expect(result.levelsGained, 2);
expect(game.playerLevel, 3);
expect(game.pendingLevelChoiceCount, 2);
```

- [ ] **Step 3: Confirm both failures**

Run: `flutter test test/app/game_hud_test.dart test/game/run_progression_system_test.dart test/game/pixel_survivor_game_loop_test.dart`

- [ ] **Step 4: Build the full-width level/XP header and compact secondary row**

Leave 64px for pause, use a gold level badge, blue/cyan meter with bright leading cap, readable numeric label, and keep time/kills/health/weapon slots below within the mobile HUD-area budget.

- [ ] **Step 5: Queue one choice per gained level**

Do not alter the XP curve. Consume one pending choice when a selection is applied, then immediately queue the next set until the count reaches zero.

- [ ] **Step 6: Run focused responsive and progression tests**

Run: `flutter test test/app/game_hud_test.dart test/app/accessibility_surfaces_test.dart test/app/responsive_layout_test.dart test/game/run_progression_system_test.dart test/game/pixel_survivor_game_loop_test.dart`

- [ ] **Step 7: Commit**

```text
feat: surface level progress and preserve every level choice
```

### Task 8: Mobile visual regression, full gates, push, and external play build

**Files:**
- Modify: `test/app/balanced_casual_combat_golden_test.dart`
- Modify: `test/app/goldens/balanced_casual_early_390x844.png`
- Modify: `test/app/goldens/balanced_casual_late_390x844.png`
- Modify: `docs/testing/balanced-casual-mobile-checklist.md`

**Interfaces:**
- Goldens include bandit, missing-spec elite families, frost, projectile, hazard, XP gem, and the level header.

- [ ] **Step 1: Extend the combat fixture and confirm the old golden fails**

Run: `flutter test test/app/balanced_casual_combat_golden_test.dart`

- [ ] **Step 2: Generate and visually inspect updated 390×844 goldens**

Run: `flutter test --update-goldens test/app/balanced_casual_combat_golden_test.dart`

Inspect that no rectangle fallback remains, frost is visibly crystalline, attack lanes have bodies/cores/accents, gems are readable, the bandit matches the player style, and enemy warnings remain legible.

- [ ] **Step 3: Update the physical-device checklist and run quality gates**

Run: `flutter analyze`

Run: `flutter test --reporter compact`

Run: `flutter build web --release`

Run: `flutter build apk --debug`

- [ ] **Step 4: Commit, push, restart the external web server, and compare local/external build hashes**

```text
test: verify combat spectacle and progress hud
```

- [ ] **Step 5: Report the temporary external play URL, branch SHA, build evidence, and remaining physical-play checks**
