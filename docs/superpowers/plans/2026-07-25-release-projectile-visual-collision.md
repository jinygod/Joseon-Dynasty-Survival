# Release Projectile Visual and Collision Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the brick-like and geometric player projectiles with readable weapon-specific PNGs and make every moving projectile hit only along its authored body using deterministic swept collision.

**Architecture:** Add an immutable `ProjectilePresentationSpec` per moving weapon and derive rendering plus a 10%-inset hit body from it. A pure swept-capsule geometry module returns first-contact data; `ProjectileComponent` retains previous position and the game loop sorts contacts by travel order before applying the existing damage and pierce rules.

**Tech Stack:** Flutter 3.44.4, Dart 3.12.2, Flame 1.37.0, `flutter_test`, `flame_test`, built-in image generation, local chroma-key removal.

## Global Constraints

- Final weapon and combat-effect presentation must not use circles, rectangles, ovals, or solid-colour Canvas primitives.
- Rendering and hit geometry must derive from the same immutable projectile specification.
- Hit length and width are exactly 10% smaller than the authored visible body.
- Fast projectiles use the previous and current world positions for continuous collision.
- Enemy collision uses `EnemyComponent.hurtRadius`.
- Existing damage, cooldown, speed, projectile count, pierce, knockback, mastery, and level values remain unchanged.
- The work adds no new weapon, character, augment, treasure chest, or permanent training system.
- Images are preloaded before combat; firing never starts an image load.
- Release execution must not draw a geometric projectile when an asset is missing.
- Completion requires landscape runtime review, collision-debug evidence, focused tests, `flutter analyze`, full `flutter test`, and an Android debug APK.

## File Structure

### New production files

- `lib/game/content/projectile_presentation_spec.dart`: weapon-specific sprite and body geometry contracts.
- `lib/game/combat/projectile_sweep_geometry.dart`: allocation-light swept capsule versus hurt-circle contact calculation.
- `lib/game/combat/projectile_contact.dart`: target-independent sweep time, world contact point, and normal.
- `lib/game/components/projectile_contact_vfx_component.dart`: authored projectile impact sheet renderer.
- `lib/game/components/projectile_geometry_debug_component.dart`: development-only visual body, swept hit capsule, hurtbox, contact, and weapon ID renderer.

### Modified production files

- `lib/game/components/projectile_component.dart`: sprite rendering, previous position, shared spec, and contact queries.
- `lib/game/systems/weapon_system.dart`: pass only approved size multipliers instead of independent collision sizes.
- `lib/game/pixel_survivor_game.dart`: preload projectile sheets, sort contacts, apply damage at the contact point, and mount debug/impact components.
- `lib/game/content/asset_catalog.dart`: register the three projectile sheets and contact sheet.
- `lib/game/content/sprite_atlas_contract.dart`: require exact 128px horizontal sheets and transparency.
- `lib/game/content/attack_visual_registry.dart`: point the existing Singijeon registry entry at the accepted sheet without duplicating rendering ownership.
- `lib/game/vfx_gallery_game.dart`, `lib/app/vfx_gallery_screen.dart`: add projectile identity, direction, speed, and collision review controls.

### New tests

- `test/game/projectile_presentation_spec_test.dart`
- `test/game/projectile_sweep_geometry_test.dart`
- `test/game/projectile_component_test.dart`
- `test/game/projectile_visual_asset_contract_test.dart`
- `test/game/projectile_contact_vfx_component_test.dart`
- `test/game/projectile_geometry_debug_component_test.dart`
- `test/app/projectile_release_landscape_golden_test.dart`

### New and replaced assets

- Replace: `assets/images/projectiles/player/singijeon_128.png`
- Create: `assets/images/projectiles/player/matchlock_shot_128.png`
- Create: `assets/images/projectiles/player/hawk_flight_128.png`
- Create: `assets/images/vfx/player/projectile_contact_128.png`
- Create: `art_source/generated/projectiles/*_source.png`
- Create: `art_source/review/projectiles/*.png`
- Create: `docs/assets/prompts/release-projectiles.md`
- Modify: `docs/assets/asset-rights-ledger.csv`

---

### Task 1: Freeze the projectile presentation contract

**Files:**
- Create: `lib/game/content/projectile_presentation_spec.dart`
- Create: `test/game/projectile_presentation_spec_test.dart`

**Interfaces:**
- Produces: `ProjectilePresentationSpec`
- Produces: `ProjectilePresentationSpec presentationFor(WeaponId weaponId)`
- Produces: `Set<String> ProjectilePresentationSpecs.requiredAssetKeys`
- Consumes later: `ProjectileComponent`, `PixelSurvivorGame`, asset contract tests

- [ ] **Step 1: Write the failing specification tests**

```dart
test('moving weapons own complete presentation specs', () {
  expect(ProjectilePresentationSpecs.byWeapon.keys, {
    gakgungShot,
    singijeonVolley,
    matchlockCannon,
    hawkSummon,
  });
});

test('hit bodies are ten percent inside visible bodies', () {
  for (final spec in ProjectilePresentationSpecs.byWeapon.values) {
    expect(spec.hitInsetFraction, .10);
    expect(spec.hitBodySize.x, closeTo(spec.bodySize.x * .90, 0.0001));
    expect(spec.hitBodySize.y, closeTo(spec.bodySize.y * .90, 0.0001));
    expect(spec.bodySize.x, lessThanOrEqualTo(spec.renderSize.x));
    expect(spec.bodySize.y, lessThanOrEqualTo(spec.renderSize.y));
  }
});

test('projectile assets are all preloaded keys', () {
  expect(ProjectilePresentationSpecs.requiredAssetKeys, {
    WeaponEffectAtlas.assetKey,
    'projectiles/player/singijeon_128.png',
    'projectiles/player/matchlock_shot_128.png',
    'projectiles/player/hawk_flight_128.png',
  });
});
```

- [ ] **Step 2: Run the test and confirm it fails**

```powershell
D:\FlutterSdk\bin\flutter.bat test test/game/projectile_presentation_spec_test.dart
```

Expected: FAIL because `projectile_presentation_spec.dart` does not exist.

- [ ] **Step 3: Implement immutable weapon specifications**

Use these reviewed logical values:

```dart
const byWeapon = <WeaponId, ProjectilePresentationSpec>{
  gakgungShot: ProjectilePresentationSpec(
    weaponId: gakgungShot,
    assetKey: WeaponEffectAtlas.assetKey,
    frameSize: 64,
    frameCount: 4,
    atlasRow: WeaponEffectAtlas.bowRow,
    frameSeconds: .08,
    renderWidth: 28,
    renderHeight: 28,
    bodyLength: 24,
    bodyWidth: 6,
    hitInsetFraction: .10,
    rotateWithVelocity: true,
  ),
  singijeonVolley: ProjectilePresentationSpec(
    weaponId: singijeonVolley,
    assetKey: 'projectiles/player/singijeon_128.png',
    frameSize: 128,
    frameCount: 4,
    atlasRow: 0,
    frameSeconds: .07,
    renderWidth: 30,
    renderHeight: 24,
    bodyLength: 25,
    bodyWidth: 9,
    hitInsetFraction: .10,
    rotateWithVelocity: true,
  ),
  matchlockCannon: ProjectilePresentationSpec(
    weaponId: matchlockCannon,
    assetKey: 'projectiles/player/matchlock_shot_128.png',
    frameSize: 128,
    frameCount: 4,
    atlasRow: 0,
    frameSeconds: .055,
    renderWidth: 22,
    renderHeight: 18,
    bodyLength: 15,
    bodyWidth: 10,
    hitInsetFraction: .10,
    rotateWithVelocity: true,
  ),
  hawkSummon: ProjectilePresentationSpec(
    weaponId: hawkSummon,
    assetKey: 'projectiles/player/hawk_flight_128.png',
    frameSize: 128,
    frameCount: 4,
    atlasRow: 0,
    frameSeconds: .085,
    renderWidth: 34,
    renderHeight: 24,
    bodyLength: 28,
    bodyWidth: 16,
    hitInsetFraction: .10,
    rotateWithVelocity: true,
  ),
};
```

Keep scalar dimensions in the const specification. `renderSize`, `bodySize`,
and `hitBodySize` getters return fresh `Vector2` values so callers cannot
mutate the contract.

- [ ] **Step 4: Run tests and commit**

```powershell
D:\FlutterSdk\bin\flutter.bat test test/game/projectile_presentation_spec_test.dart
git add lib/game/content/projectile_presentation_spec.dart test/game/projectile_presentation_spec_test.dart
git commit -m "feat: define projectile presentation contracts"
```

Expected: PASS and one focused commit.

---

### Task 2: Implement pure swept-capsule contact geometry

**Files:**
- Create: `lib/game/combat/projectile_contact.dart`
- Create: `lib/game/combat/projectile_sweep_geometry.dart`
- Create: `test/game/projectile_sweep_geometry_test.dart`

**Interfaces:**
- Consumes: previous/current centers, normalized direction, hit body size, hurt center, hurt radius
- Produces: `ProjectileContact? ProjectileSweepGeometry.firstContact(...)`
- Produces: immutable defensive copies of `travelFraction`, `point`, and `normal`
- Consumes later: `ProjectileComponent.contactsFor`

- [ ] **Step 1: Write failing tunnelling and miss tests**

```dart
test('finds a target crossed within one fast frame', () {
  final contact = ProjectileSweepGeometry.firstContact(
    previousCenter: Vector2.zero(),
    currentCenter: Vector2(100, 0),
    direction: Vector2(1, 0),
    hitBodySize: Vector2(18, 6),
    hurtCenter: Vector2(50, 0),
    hurtRadius: 8,
  );
  expect(contact, isNotNull);
  expect(contact!.travelFraction, inInclusiveRange(0, 1));
  expect(contact.point.x, closeTo(42, .01));
});

test('does not hit a near target outside the swept thickness', () {
  final contact = ProjectileSweepGeometry.firstContact(
    previousCenter: Vector2.zero(),
    currentCenter: Vector2(100, 0),
    direction: Vector2(1, 0),
    hitBodySize: Vector2(18, 6),
    hurtCenter: Vector2(50, 12),
    hurtRadius: 8,
  );
  expect(contact, isNull);
});

test('stationary projectile checks its oriented body', () {
  final contact = ProjectileSweepGeometry.firstContact(
    previousCenter: Vector2.zero(),
    currentCenter: Vector2.zero(),
    direction: Vector2(1, 0),
    hitBodySize: Vector2(18, 6),
    hurtCenter: Vector2(14, 0),
    hurtRadius: 8,
  );
  expect(contact, isNotNull);
});
```

- [ ] **Step 2: Run the test and confirm it fails**

```powershell
D:\FlutterSdk\bin\flutter.bat test test/game/projectile_sweep_geometry_test.dart
```

Expected: FAIL because the sweep geometry types do not exist.

- [ ] **Step 3: Implement allocation-light segment contact**

Extend the previous-to-current center segment by `hitBodySize.x / 2` at both
ends and expand the enemy hurt circle by `hitBodySize.y / 2`. Solve the
segment-circle quadratic for the earliest valid root. When the extended start
is already inside, use travel fraction zero. Derive the contact normal from
the closest sweep point toward the enemy and place the reported point on
`hurtCenter - normal * hurtRadius`. Do not allocate `Path`, polygon, or Flame
hitbox components.

Guard zero direction with `(currentCenter - previousCenter).normalized()`, and
fall back to `(1, 0)` only when both are zero. Reject non-finite inputs with
`ArgumentError`.

- [ ] **Step 4: Add ordering and defensive-copy tests**

```dart
test('earlier contact has a smaller travel fraction', () {
  final near = contactAt(Vector2(30, 0));
  final far = contactAt(Vector2(70, 0));
  expect(near.travelFraction, lessThan(far.travelFraction));
});

test('contact values do not alias caller vectors', () {
  final point = Vector2(50, 0);
  final contact = contactAt(point);
  point.setValues(999, 999);
  expect(contact.point.x, isNot(999));
});
```

- [ ] **Step 5: Run tests and commit**

```powershell
D:\FlutterSdk\bin\flutter.bat test test/game/projectile_sweep_geometry_test.dart
git add lib/game/combat/projectile_contact.dart lib/game/combat/projectile_sweep_geometry.dart test/game/projectile_sweep_geometry_test.dart
git commit -m "feat: add swept projectile contact geometry"
```

Expected: PASS and no geometry allocations beyond returned contact values.

---

### Task 3: Produce and contract the release projectile sheets

**Files:**
- Create: `test/game/projectile_visual_asset_contract_test.dart`
- Create: `docs/assets/prompts/release-projectiles.md`
- Replace/Create: the four runtime PNGs listed in File Structure
- Create: `art_source/generated/projectiles/*_source.png`
- Modify: `lib/game/content/asset_catalog.dart`
- Modify: `lib/game/content/sprite_atlas_contract.dart`
- Modify: `docs/assets/asset-rights-ledger.csv`

**Interfaces:**
- Consumes: exact asset keys from `ProjectilePresentationSpecs`
- Produces: three 512×128 projectile sheets with four 128×128 cells
- Produces: one 768×128 contact sheet with six 128×128 cells
- Produces: accepted SHA-256 and provenance entries

- [ ] **Step 1: Write failing asset contract tests**

The tests must decode each PNG and assert:

```dart
expect(image.width, 512);
expect(image.height, 128);
expect(contract.status, ArtAssetStatus.approved);
expect(cornerAlphaForEveryCell(image), everyElement(0));
expect(opaquePixelBoundsForEveryCell(image), everyElement(isNotEmpty));
```

Also assert that the old Singijeon yellow border is absent by sampling a
two-pixel band around each cell edge and requiring alpha zero.

- [ ] **Step 2: Run the contract test and confirm it fails**

```powershell
D:\FlutterSdk\bin\flutter.bat test test/game/projectile_visual_asset_contract_test.dart
```

Expected: FAIL because the new sheets are missing and the current Singijeon
cell edges contain opaque pixels.

- [ ] **Step 3: Record and use exact image-generation prompts**

Create `docs/assets/prompts/release-projectiles.md` with three separate prompts
and one impact prompt. Each prompt specifies:

```text
2D mobile game sprite sheet, four equal horizontal animation frames, right-facing,
Joseon folk fantasy, cute but combat-readable, bold dark-ink outline,
ivory highlights and restrained gold accents, flat solid #00FF00 chroma background,
no frame border, no card, no square aura, no readable text, no cropped silhouette.
```

Append these subject clauses:

- Singijeon: wooden rocket arrow, red gunpowder canister, short gold ignition flame.
- Matchlock shot: irregular dark iron shot, vermilion fire core, short grey smoke tail.
- Hawk: compact flying hawk, spread wings, hooked beak, navy feathers, gold-brown tips.
- Contact: tiny ivory-gold spark burst with a restrained vermilion core; no projectile body.

Generate each source with the built-in image tool and save the selected outputs
under `art_source/generated/projectiles/`.

- [ ] **Step 4: Remove chroma and assemble exact sheets**

Use the provided helper for each accepted source:

```powershell
python 'C:\Users\전성진\.codex\skills\.system\imagegen\scripts\remove_chroma_key.py' --input art_source/generated/projectiles/singijeon_source.png --out assets/images/projectiles/player/singijeon_128.png --auto-key border --soft-matte --transparent-threshold 12 --opaque-threshold 220 --despill
```

Repeat for matchlock, hawk, and contact. Crop equal source cells and resample
without non-uniform stretching so final dimensions are exactly 512×128.
Visually reject any result with a rectangular cell edge, opaque corner, muddy
silhouette, or unreadable 24px preview.

- [ ] **Step 5: Register provenance and make contracts pass**

Add exact paths to `AssetCatalog.effects`, exact `SpriteAtlasContract` entries
with `ArtAssetStatus.approved`, source/runtime SHA-256 values, generation date,
tool, and review state to `docs/assets/asset-rights-ledger.csv`.

```powershell
D:\FlutterSdk\bin\flutter.bat test test/game/projectile_visual_asset_contract_test.dart
git add assets/images/projectiles/player assets/images/vfx/player art_source/generated/projectiles docs/assets/prompts/release-projectiles.md docs/assets/asset-rights-ledger.csv lib/game/content/asset_catalog.dart lib/game/content/sprite_atlas_contract.dart test/game/projectile_visual_asset_contract_test.dart
git commit -m "art: add release player projectile sheets"
```

Expected: PASS with no opaque cell border.

---

### Task 4: Integrate sprite rendering and swept hit resolution

**Files:**
- Modify: `lib/game/components/projectile_component.dart`
- Modify: `lib/game/systems/weapon_system.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `lib/game/models/damage_event.dart`
- Create: `test/game/projectile_component_test.dart`
- Modify: `test/game/weapon_system_test.dart`
- Modify: `test/game/pixel_survivor_game_loop_test.dart`

**Interfaces:**
- Consumes: `ProjectilePresentationSpecs`, preloaded images, `ProjectileSweepGeometry`
- Produces: `List<ProjectileTargetContact> contactsFor(Iterable<EnemyComponent>)`
- Preserves: existing `registerHit`, lifetime, pierce, damage, speed, and population accounting

- [ ] **Step 1: Write failing component tests**

```dart
test('keeps previous position before a fast update', () {
  final projectile = projectileAt(Vector2.zero(), velocity: Vector2(100, 0));
  projectile.update(.5);
  expect(projectile.previousPosition, Vector2.zero());
  expect(projectile.position, Vector2(50, 0));
});

test('returns swept contacts in travel order', () {
  final projectile = projectileAt(Vector2.zero(), velocity: Vector2(100, 0));
  projectile.update(1);
  final contacts = projectile.contactsFor([
    enemyAt(Vector2(75, 0)),
    enemyAt(Vector2(25, 0)),
  ]);
  expect(contacts.map((item) => item.enemy.position.x), [25, 75]);
});

test('render source contains no geometric release fallback', () {
  final source = File('lib/game/components/projectile_component.dart')
      .readAsStringSync();
  expect(source, isNot(contains('drawOval')));
  expect(source, isNot(contains('drawCircle')));
  expect(source, isNot(contains('drawRect')));
});

test('resume does not sweep the paused interval twice', () {
  final projectile = projectileAt(Vector2.zero(), velocity: Vector2(100, 0));
  projectile.update(.1);
  final beforePause = projectile.position.clone();
  projectile.synchronizePreviousPosition();
  expect(projectile.previousPosition, beforePause);
  expect(projectile.contactsFor([enemyAt(Vector2(5, 0))]), isEmpty);
});
```

- [ ] **Step 2: Run tests and confirm the old path fails**

```powershell
D:\FlutterSdk\bin\flutter.bat test test/game/projectile_component_test.dart test/game/weapon_system_test.dart
```

Expected: FAIL because previous position, sorted contacts, and sprite-only
rendering do not exist.

- [ ] **Step 3: Replace component geometry and rendering**

`ProjectileComponent` stores `presentation`, `_previousPosition`,
`sizeMultiplier`, and a preloaded image. At the start of `update`, copy current
position into `_previousPosition`, then move. Render one atlas frame centered
inside `presentation.renderSize * sizeMultiplier`, rotated by velocity plus
`assetForwardAngle`.

Replace `overlapsEnemy` with:

```dart
List<ProjectileTargetContact> contactsFor(
  Iterable<EnemyComponent> enemies,
) {
  final contacts = <ProjectileTargetContact>[];
  for (final enemy in enemies.where((item) => !item.isDead)) {
    final contact = ProjectileSweepGeometry.firstContact(
      previousCenter: previousPosition,
      currentCenter: position,
      direction: velocity,
      hitBodySize: presentation.hitBodySize * sizeMultiplier,
      hurtCenter: enemy.position,
      hurtRadius: enemy.hurtRadius,
    );
    if (contact != null) {
      contacts.add(ProjectileTargetContact(enemy: enemy, contact: contact));
    }
  }
  contacts.sort(
    (a, b) => a.contact.travelFraction.compareTo(b.contact.travelFraction),
  );
  return contacts;
}
```

- [ ] **Step 4: Integrate preloading and ordered damage**

Add `ProjectilePresentationSpecs.requiredAssetKeys` and the contact sheet to
the one-time preloader. Attach the exact image in `_admitProjectile`.
`_applyProjectileHits` loops over `projectile.contactsFor(enemies)`, calls
`registerHit`, and creates `DamageEvent(contactPoint: contact.point)` with
knockback from the projectile direction. Stop at exhausted pierce.

Change the four weapon constructors to pass their existing scalar
`sizeMultiplier` and remove independent `Vector2.all(...)` collision sizes.
Assert existing projectile velocities, counts, damage, and pierce remain equal
in `weapon_system_test.dart`.

- [ ] **Step 5: Run focused integration tests and commit**

```powershell
D:\FlutterSdk\bin\flutter.bat test test/game/projectile_presentation_spec_test.dart test/game/projectile_sweep_geometry_test.dart test/game/projectile_component_test.dart test/game/weapon_system_test.dart test/game/pixel_survivor_game_loop_test.dart
git add lib/game/components/projectile_component.dart lib/game/systems/weapon_system.dart lib/game/pixel_survivor_game.dart lib/game/models/damage_event.dart test/game/projectile_component_test.dart test/game/weapon_system_test.dart test/game/pixel_survivor_game_loop_test.dart
git commit -m "feat: align projectile visuals and swept hits"
```

Expected: PASS, including a game-loop test where a projectile crosses an enemy
between two frames and damages it exactly once.

---

### Task 5: Add contact feedback, debug geometry, and gallery review

**Files:**
- Create: `lib/game/components/projectile_contact_vfx_component.dart`
- Create: `lib/game/components/projectile_geometry_debug_component.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `lib/game/vfx_gallery_game.dart`
- Modify: `lib/app/vfx_gallery_screen.dart`
- Create: `test/game/projectile_contact_vfx_component_test.dart`
- Create: `test/game/projectile_geometry_debug_component_test.dart`
- Modify: `test/game/vfx_gallery_game_test.dart`

**Interfaces:**
- Consumes: `ProjectileTargetContact`, accepted contact sheet, world debug toggle
- Produces: image-only 0.14-second impact at the exact world contact point
- Produces: development-only visual body, hit capsule, sweep, hurtbox, normal, weapon ID

- [ ] **Step 1: Write failing VFX and debug tests**

```dart
test('projectile contact effect renders six frames and expires', () {
  final effect = ProjectileContactVfxComponent.withoutImageForTesting(
    position: Vector2(30, 40),
  );
  expect(effect.position, Vector2(30, 40));
  effect.update(.14);
  expect(effect.isExpired, isTrue);
});

test('debug snapshot keeps exact projectile contact geometry', () {
  final debug = ProjectileGeometryDebugComponent(
    weaponId: singijeonVolley,
    previousCenter: Vector2.zero(),
    currentCenter: Vector2(100, 0),
    visualBodySize: Vector2(25, 9),
    hitBodySize: Vector2(22.5, 8.1),
    hurtCenter: Vector2(50, 0),
    hurtRadius: 8.1,
    contact: ProjectileContact(
      travelFraction: .4,
      point: Vector2(41.9, 0),
      normal: Vector2(1, 0),
    ),
  );
  expect(debug.hitBodySize.x, closeTo(debug.visualBodySize.x * .9, .0001));
});
```

- [ ] **Step 2: Run tests and confirm they fail**

```powershell
D:\FlutterSdk\bin\flutter.bat test test/game/projectile_contact_vfx_component_test.dart test/game/projectile_geometry_debug_component_test.dart test/game/vfx_gallery_game_test.dart
```

Expected: FAIL because the components and gallery controls do not exist.

- [ ] **Step 3: Implement feedback and debug ownership**

Render the six-frame contact sprite without a Canvas impact substitute.
Spawn it once after effective damage is accepted. The debug component may use
Canvas strokes and text only under `kDebugMode`; attach it only while the
existing world debug toggle is enabled and remove stale snapshots on the next
frame.

Add gallery entries for the four projectile IDs, eight direction presets,
0.25×/1× playback, bright/dark stage backgrounds, and toggles for visual body,
hit body, swept path, hurtbox, contact, and weapon ID.

- [ ] **Step 4: Run tests and commit**

```powershell
D:\FlutterSdk\bin\flutter.bat test test/game/projectile_contact_vfx_component_test.dart test/game/projectile_geometry_debug_component_test.dart test/game/vfx_gallery_game_test.dart test/game/pixel_survivor_game_loop_test.dart
git add lib/game/components/projectile_contact_vfx_component.dart lib/game/components/projectile_geometry_debug_component.dart lib/game/pixel_survivor_game.dart lib/game/vfx_gallery_game.dart lib/app/vfx_gallery_screen.dart test/game/projectile_contact_vfx_component_test.dart test/game/projectile_geometry_debug_component_test.dart test/game/vfx_gallery_game_test.dart test/game/pixel_survivor_game_loop_test.dart
git commit -m "feat: review projectile contact geometry"
```

Expected: PASS and no debug component in a release-mode source path.

---

### Task 6: Run landscape review and final verification

**Files:**
- Create: `test/app/projectile_release_landscape_golden_test.dart`
- Create: `test/app/goldens/projectile_release_landscape_16_9.png`
- Create: `art_source/review/projectiles/projectile_gallery_light.png`
- Create: `art_source/review/projectiles/projectile_gallery_dark.png`
- Create: `art_source/review/projectiles/projectile_debug_contact.png`
- Create: `art_source/review/projectiles/projectile_combat_16_9.png`
- Create: `art_source/review/projectiles/projectile_combat_19_5_9.png`
- Create: `docs/testing/projectile-release-vertical-slice-report.md`

**Interfaces:**
- Consumes: the complete projectile slice
- Produces: visual evidence, final verification logs, APK path and checksum

- [ ] **Step 1: Add the landscape golden**

The fixture must display all four projectile families against the moonlit
stage at 960×540, include enemies at contact and miss distances, and assert
that no yellow cell border or geometric projectile appears.

```powershell
D:\FlutterSdk\bin\flutter.bat test --update-goldens test/app/projectile_release_landscape_golden_test.dart
D:\FlutterSdk\bin\flutter.bat test test/app/projectile_release_landscape_golden_test.dart
```

Expected: PASS after visual inspection of the accepted golden.

- [ ] **Step 2: Run Chrome and capture runtime evidence**

Launch the existing development route locally, open the projectile gallery and
combat fixture at 16:9 and 19.5:9, and capture the five named review files.
Inspect:

- silhouette at actual mobile scale;
- no opaque cell edges or solid primitive fallback;
- visual body and hit capsule alignment in eight directions;
- earliest contact point on a single target;
- travel-order hits through a line of targets;
- no damage for a near miss just outside the swept capsule;
- no image loading or frame hitch during firing.

If one check fails, change only the responsible body bound, frame crop, or
asset and rerun its focused test before recapturing.

- [ ] **Step 3: Run the final verification once**

```powershell
D:\FlutterSdk\bin\flutter.bat analyze
D:\FlutterSdk\bin\flutter.bat test
$env:PUB_CACHE='D:\CodexCaches\Pub'; D:\FlutterSdk\bin\flutter.bat build apk --debug
Get-FileHash build\app\outputs\flutter-apk\app-debug.apk -Algorithm SHA256
```

Expected: analyze PASS, full test PASS, Android APK build PASS, checksum
recorded. Do not run iOS.

- [ ] **Step 4: Write the before/after report and commit**

Record:

- old Singijeon opaque border and generic oval paths;
- old current-position circular collision formula;
- new per-weapon render/body/hit sizes;
- new swept contact ordering and hurt radius;
- generated asset paths and provenance;
- focused/full test totals;
- analyze result;
- APK path and SHA-256;
- screenshots reviewed and remaining device-only checks.

```powershell
git add test/app/projectile_release_landscape_golden_test.dart test/app/goldens/projectile_release_landscape_16_9.png art_source/review/projectiles docs/testing/projectile-release-vertical-slice-report.md
git commit -m "docs: verify release projectile vertical slice"
git status --short --branch
```

Expected: only the user-owned untracked `.codex/` directory remains.

## Plan Self-Review

- Spec coverage: all four moving projectile weapons, exact art ownership,
  10% inset, enemy hurtbox, swept collision, ordering, contact feedback,
  pause-safe state, debug geometry, gallery, runtime review, tests, analyze,
  and Android build map to explicit tasks.
- Scope: no new content or balance redesign; gallery and debug work only
  support visual/collision review.
- Type consistency: the plan uses `ProjectilePresentationSpec`,
  `ProjectileContact`, `ProjectileSweepGeometry.firstContact`,
  `ProjectileTargetContact`, and `contactsFor` consistently.
- Asset consistency: all new runtime sheets are 512×128 with four 128px
  cells except the six-frame contact sheet, which is 768×128.
- Execution order: contracts and pure geometry precede assets and runtime
  integration; final full validation runs once.
