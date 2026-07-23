# Combat VFX Foundation and Hwando Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Use the imagegen skill for authored PNG production. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build one gameplay-authoritative VFX pipeline and replace every primary geometric Hwando rendering path with reviewed image animation.

**Architecture:** `AttackInstance` remains the immutable gameplay source and is converted to an `AttackVisualEvent` without changing balance values. A registry supplies asset, frame, anchor, layer, and timing metadata to both the real combat component and a future gallery; a preloader resolves the same registry before combat. Hwando is the first complete vertical slice.

**Tech Stack:** Flutter 3.44, Dart 3.12, Flame 1.18, `flutter_test`, Flame component tests, RGBA PNG sprite sheets, OpenAI image generation.

## Global Constraints

- Preserve every existing `AttackSpec` damage, range, angle, radius, width, cooldown, knockback, slow, and timing value.
- Use 128px working cells, transparent RGBA PNG, bold outline, 2–3 tone cel shading, and Joseon folk-fantasy visual vocabulary.
- Do not bake text, logos, signatures, or watermarks into assets.
- Do not use Canvas sectors, circles, or lines as the primary Hwando visual.
- Thin hitbox outlines are allowed only as an explicit debug overlay.
- Load combat images before the first attack; no component may start `images.load` during its first combat mount.
- Main orchestration, integration, and final decisions remain with `gpt-5.6-sol`.
- Any delegated implementation must explicitly use `gpt-5.6-terra`; read-only exploration or QA must explicitly use `gpt-5.6-luna`.
- A writing worker owns only its assigned files; no two workers edit the same file concurrently.
- Run focused checks per task. Do not run the full suite or web build in this plan.

---

## File Map

- Create `lib/game/combat/attack_visual_event.dart`: immutable presentation snapshot derived from `AttackInstance`.
- Create `lib/game/content/attack_visual_registry.dart`: effect IDs and image/frame/anchor/timing contracts.
- Create `lib/game/content/combat_asset_preloader.dart`: registry-driven image preload.
- Create `lib/game/components/hwando_vfx_component.dart`: layered Hwando animation and lifetime.
- Modify `lib/game/pixel_survivor_game.dart`: preload assets and route Hwando to one VFX component.
- Modify `lib/game/components/attack_effect_component.dart`: keep only non-migrated safe behavior.
- Modify `lib/game/components/melee_arc_component.dart`: stop combat-time loading and remove Hwando ownership.
- Modify `lib/game/content/asset_catalog.dart`, `lib/game/content/sprite_atlas_contract.dart`, `pubspec.yaml`: register reviewed runtime files.
- Create `assets/images/vfx/hwando/`: normalized runtime PNGs.
- Create `art_source/generated/hwando/`: generated originals and review exports; exclude from `pubspec`.
- Modify `docs/assets/asset-rights-ledger.csv`: provenance, SHA-256, status, and runtime use.

### Task 1: Freeze the Visual Event Contract

**Files:**
- Create: `lib/game/combat/attack_visual_event.dart`
- Test: `test/game/attack_visual_event_test.dart`

**Interfaces:**
- Consumes: `AttackInstance`.
- Produces: `AttackVisualEvent.fromAttack(AttackInstance)`, cloned `origin`/`direction`, `effectId`, geometry, `impactAt`, `duration`, presentation, and sequence.

- [ ] **Step 1: Write the failing immutability test**

```dart
final hwandoSpec = AttackSpec(
  id: 'hwando_slash',
  shape: AttackShape.sector,
  damage: 10,
  range: 80,
  angleRadians: math.pi * .7,
  radius: 0,
  width: 0,
  windupSeconds: .05,
  activeSeconds: .12,
  lingerSeconds: .08,
  knockback: 10,
  slowFraction: 0,
  traits: {AttackTrait.melee},
  presentation: AttackPresentation.normal,
);

test('visual event freezes attack direction and timing', () {
  final direction = Vector2(2, 0);
  final attack = AttackInstance(
    spec: hwandoSpec,
    origin: Vector2(10, 20),
    direction: direction,
    sequenceIndex: 3,
  );
  final event = AttackVisualEvent.fromAttack(attack);
  direction.setValues(0, 1);

  expect(event.effectId, hwandoSpec.id);
  expect(event.origin, Vector2(10, 20));
  expect(event.direction, Vector2(1, 0));
  expect(event.impactAt, hwandoSpec.windupSeconds);
  expect(
    event.duration,
    hwandoSpec.windupSeconds +
        hwandoSpec.activeSeconds +
        hwandoSpec.lingerSeconds,
  );
});
```

- [ ] **Step 2: Verify the test fails**

Run: `flutter test test/game/attack_visual_event_test.dart`

Expected: compilation fails because `AttackVisualEvent` does not exist.

- [ ] **Step 3: Implement the immutable snapshot**

```dart
@immutable
class AttackVisualEvent {
  AttackVisualEvent.fromAttack(AttackInstance attack)
      : effectId = attack.spec.id,
        shape = attack.spec.shape,
        _origin = attack.origin,
        _direction = attack.direction,
        range = attack.spec.range,
        angleRadians = attack.spec.angleRadians,
        radius = attack.spec.radius,
        width = attack.spec.width,
        impactAt = attack.spec.windupSeconds,
        duration = attack.spec.windupSeconds +
            attack.spec.activeSeconds +
            attack.spec.lingerSeconds,
        presentation = attack.spec.presentation,
        sequenceIndex = attack.sequenceIndex;

  final String effectId;
  final AttackShape shape;
  final Vector2 _origin;
  final Vector2 _direction;
  final double range;
  final double angleRadians;
  final double radius;
  final double width;
  final double impactAt;
  final double duration;
  final AttackPresentation presentation;
  final int sequenceIndex;

  Vector2 get origin => _origin.clone();
  Vector2 get direction => _direction.clone();
}
```

- [ ] **Step 4: Run focused tests**

Run: `flutter test test/game/attack_visual_event_test.dart test/game/attack_geometry_test.dart test/game/hwando_executor_test.dart`

Expected: all tests pass and no balance baseline changes.

- [ ] **Step 5: Commit**

```powershell
git add lib/game/combat/attack_visual_event.dart test/game/attack_visual_event_test.dart
git commit -m "feat: define immutable attack visual events"
```

### Task 2: Define the Visual Registry and Missing-Asset Policy

**Files:**
- Create: `lib/game/content/attack_visual_registry.dart`
- Modify: `lib/game/content/sprite_atlas_contract.dart`
- Test: `test/game/attack_visual_registry_test.dart`

**Interfaces:**
- Consumes: stable attack IDs and `AttackPresentation`.
- Produces: `AttackVisualSpec`, `AttackVisualLayerSpec`, `AttackVisualStatus`, `AttackVisualRegistry.byId(String)`, and `AttackVisualRegistry.requiredAssetKeys`.

- [ ] **Step 1: Write the failing registry test**

```dart
test('Hwando visual contracts declare layers and timing', () {
  final spec = AttackVisualRegistry.byId('hwando_slash');
  expect(spec.status, AttackVisualStatus.generatedReview);
  expect(spec.layers.map((layer) => layer.id), containsAll([
    'trail',
    'impact',
  ]));
  expect(spec.layers.every((layer) => layer.frameSize == 128), isTrue);
  expect(spec.layers.every((layer) => layer.assetKey.startsWith('vfx/')), isTrue);
});

test('unknown IDs are explicit in development', () {
  expect(
    () => AttackVisualRegistry.byId('not_registered'),
    throwsA(isA<MissingAttackVisualException>()),
  );
});
```

- [ ] **Step 2: Verify the tests fail**

Run: `flutter test test/game/attack_visual_registry_test.dart`

Expected: compilation fails for undefined registry types.

- [ ] **Step 3: Implement focused registry types**

```dart
enum AttackVisualStatus { ready, generatedReview, temporary, missing }

class AttackVisualLayerSpec {
  const AttackVisualLayerSpec({
    required this.id,
    required this.assetKey,
    required this.frameSize,
    required this.frameCount,
    required this.anchor,
    required this.priorityOffset,
    required this.startFraction,
    required this.endFraction,
  });

  final String id;
  final String assetKey;
  final double frameSize;
  final int frameCount;
  final Anchor anchor;
  final int priorityOffset;
  final double startFraction;
  final double endFraction;
}

class AttackVisualSpec {
  const AttackVisualSpec({
    required this.effectId,
    required this.category,
    required this.status,
    required this.layers,
    required this.rotateWithDirection,
  });

  final String effectId;
  final CombatVisualCategory category;
  final AttackVisualStatus status;
  final List<AttackVisualLayerSpec> layers;
  final bool rotateWithDirection;
}
```

Define `CombatVisualCategory { hwando, projectile, area, telegraph, status }` in this registry file. Register separate Hwando entries for normal/left/right, blade wave, master circle, and finisher using the exact IDs emitted by `hwando_executor.dart`. Set their category to `hwando`. Do not add entries for other weapons in this task.

- [ ] **Step 4: Add runtime contracts**

Add one `SpriteAtlasContract` per normalized Hwando sheet with `frameWidth: 128`, `frameHeight: 128`, exact columns/rows from the reviewed export, `requiresTransparency: true`, and `status: ArtAssetStatus.temporary` until visual review is complete.

- [ ] **Step 5: Run focused tests**

Run: `flutter test test/game/attack_visual_registry_test.dart test/game/sprite_atlas_contract_test.dart`

Expected: all registry IDs resolve and every declared PNG contract is structurally valid once Task 4 supplies the files.

- [ ] **Step 6: Commit**

```powershell
git add lib/game/content/attack_visual_registry.dart lib/game/content/sprite_atlas_contract.dart test/game/attack_visual_registry_test.dart
git commit -m "feat: define combat visual registry"
```

### Task 3: Preload Registry Assets Before Combat

**Files:**
- Create: `lib/game/content/combat_asset_preloader.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `lib/app/game_screen.dart`
- Test: `test/game/combat_asset_preloader_test.dart`
- Test: `test/app/game_screen_settings_test.dart`

**Interfaces:**
- Consumes: `AttackVisualRegistry.requiredAssetKeys`, Flame `Images`.
- Produces: `CombatAssetPreloader.load(Images, Iterable<String>)`, a deduplicated `Map<String, Image>`, and `PixelSurvivorGame.visualImages`.

- [ ] **Step 1: Write the failing preload test**

```dart
test('preloader deduplicates registry keys', () async {
  final loaded = <String>[];
  final recorder = ui.PictureRecorder();
  final fakeImage = await recorder.endRecording().toImage(1, 1);
  final result = await CombatAssetPreloader.loadWith(
    const ['vfx/a.png', 'vfx/a.png', 'vfx/b.png'],
    (key) async {
      loaded.add(key);
      return fakeImage;
    },
  );
  expect(loaded, ['vfx/a.png', 'vfx/b.png']);
  expect(result.keys, {'vfx/a.png', 'vfx/b.png'});
});
```

- [ ] **Step 2: Verify the test fails**

Run: `flutter test test/game/combat_asset_preloader_test.dart`

Expected: compilation fails because the preloader is absent.

- [ ] **Step 3: Implement deterministic preload**

```dart
abstract final class CombatAssetPreloader {
  static Future<Map<String, Image>> loadWith(
    Iterable<String> keys,
    Future<Image> Function(String key) loader,
  ) async {
    final images = <String, Image>{};
    for (final key in keys.toSet().toList()..sort()) {
      images[key] = await loader(key);
    }
    return Map.unmodifiable(images);
  }
}
```

In `PixelSurvivorGame.onLoad`, await this loader after `super.onLoad()` and before spawning active combat actors. Preserve `loadVisualAssets: false` tests by returning an empty immutable map.

- [ ] **Step 4: Prevent first-mount loads**

Pass cached images into migrated VFX components. Add a test that mounts a Hwando component with a fake cached map and verifies the injected loader is never invoked during `onLoad`.

- [ ] **Step 5: Run focused tests**

Run: `flutter test test/game/combat_asset_preloader_test.dart test/game/pixel_survivor_game_loop_test.dart test/app/game_screen_settings_test.dart`

Expected: tests pass; game construction remains asynchronous only where already supported by `GameScreen`.

- [ ] **Step 6: Commit**

```powershell
git add lib/game/content/combat_asset_preloader.dart lib/game/pixel_survivor_game.dart lib/app/game_screen.dart test/game/combat_asset_preloader_test.dart test/app/game_screen_settings_test.dart
git commit -m "perf: preload combat visual assets"
```

### Task 4: Produce and Validate the Hwando PNG Set

**Files:**
- Create: `art_source/generated/hwando/`
- Create: `assets/images/vfx/hwando/hwando_basic_128.png`
- Create: `assets/images/vfx/hwando/hwando_master_circle_128.png`
- Create: `assets/images/vfx/hwando/hwando_blade_wave_128.png`
- Create: `assets/images/vfx/hwando/hwando_finisher_128.png`
- Create: `assets/images/vfx/hwando/hwando_impact_128.png`
- Modify: `docs/assets/asset-rights-ledger.csv`
- Modify: `pubspec.yaml`
- Test: `test/game/hwando_visual_asset_contract_test.dart`

**Interfaces:**
- Consumes: registry frame contracts from Task 2 and the approved art guide.
- Produces: original generated sources, normalized RGBA runtime sheets, hashes, and rights records.

- [ ] **Step 1: Write the failing asset contract**

```dart
test('all Hwando runtime sheets satisfy their PNG contracts', () {
  for (final id in hwandoVisualAtlasIds) {
    final contract = ReplaceableArtCatalog.byId(id);
    final bytes = File(contract.runtimePath).readAsBytesSync();
    expect(contract.validatePngHeader(bytes), isEmpty, reason: id);
  }
});
```

- [ ] **Step 2: Verify missing files fail**

Run: `flutter test test/game/hwando_visual_asset_contract_test.dart`

Expected: failure naming the first absent Hwando PNG.

- [ ] **Step 3: Generate original transparent artwork**

Use the imagegen skill with the approved style: directional ink-and-gold sword trails, bold dark edge, 2–3 cel-shaded values, transparent background, no sword-wielding character, no letters or seals resembling readable text. Generate separate source images for basic slash, circular master slash, blade wave, finisher, and impact burst.

- [ ] **Step 4: Inspect and normalize**

Inspect every source at original detail. Reject residual backgrounds, clipped alpha, text-like marks, inconsistent light direction, or commercial character resemblance. Normalize each accepted source to the exact registry grid with consistent center/pivot and save RGBA PNG files at the paths above.

- [ ] **Step 5: Record provenance**

Append ledger rows containing runtime path, source path, `generated-original`, generation date `2026-07-23`, tool, prompt document reference, SHA-256, review status `temporary`, and runtime owner `AttackVisualRegistry`.

- [ ] **Step 6: Run asset validation**

Run: `flutter test test/game/hwando_visual_asset_contract_test.dart test/game/attack_visual_registry_test.dart test/game/asset_rights_policy_test.dart`

Expected: all files exist, have expected dimensions and RGBA color type, and have ledger entries.

- [ ] **Step 7: Commit**

```powershell
git add art_source/generated/hwando assets/images/vfx/hwando docs/assets/asset-rights-ledger.csv pubspec.yaml test/game/hwando_visual_asset_contract_test.dart
git commit -m "art: add generated Hwando visual set"
```

### Task 5: Route Hwando Through One Image Component

**Files:**
- Create: `lib/game/components/hwando_vfx_component.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `lib/game/components/attack_effect_component.dart`
- Modify: `lib/game/components/melee_arc_component.dart`
- Test: `test/game/hwando_vfx_component_test.dart`
- Test: `test/game/pixel_survivor_game_loop_test.dart`

**Interfaces:**
- Consumes: `AttackVisualEvent`, `AttackVisualRegistry`, `PixelSurvivorGame.visualImages`.
- Produces: `HwandoVfxComponent`, one component per Hwando `AttackInstance`, frame/layer state, and clean expiry callback.

- [ ] **Step 1: Write the failing lifecycle and direction tests**

```dart
test('Hwando VFX freezes direction and expires once', () {
  var expired = 0;
  final images = <String, ui.Image>{
    for (final layer in AttackVisualRegistry.byId('hwando_slash').layers)
      layer.assetKey: onePixelImage,
  };
  final component = HwandoVfxComponent(
    event: AttackVisualEvent.fromAttack(hwandoAttack),
    images: images,
    onExpired: () => expired += 1,
  );
  expect(component.facingAngle, closeTo(0, 1e-9));
  component.update(component.event.duration + 0.001);
  component.update(1);
  expect(component.isRemoving, isTrue);
  expect(expired, 1);
});
```

In the test file, create `onePixelImage` once in `setUpAll` with `ui.PictureRecorder().endRecording().toImage(1, 1)`. Construct `hwandoAttack` from the concrete `AttackSpec` fixture used in Task 1 so the test does not rely on production balance lookups.

Add a game-loop assertion that a fired Hwando attack creates one `HwandoVfxComponent`, zero Hwando `MeleeArcComponent`, and zero Hwando `AttackEffectComponent`.

- [ ] **Step 2: Verify the tests fail**

Run: `flutter test test/game/hwando_vfx_component_test.dart test/game/pixel_survivor_game_loop_test.dart`

Expected: compilation fails for the new component or the old-path count assertion fails.

- [ ] **Step 3: Implement layered sprite rendering**

Use `_age / event.duration` to select active registry layers and frame indices. Rotate directional layers by `atan2(event.direction.y, event.direction.x)`. Render the impact layer only when `_age >= event.impactAt`; render circular master layers without directional rotation. Cache `Sprite` objects in the constructor or `onLoad` from the injected image map.

- [ ] **Step 4: Replace the runtime branch**

At the existing `AttackEffectComponent` creation site near `pixel_survivor_game.dart:886`, branch on Hwando effect IDs and add `HwandoVfxComponent`. Remove the `if (arc.weaponId == hwandoSlash) continue` workaround only after confirming the arc list cannot create a second Hwando visual. Keep damage processing at `pixel_survivor_game.dart:684` unchanged.

- [ ] **Step 5: Remove Hwando fallback ownership**

`MeleeArcComponent` must accept an already loaded image for remaining weapons and must not call `WeaponEffectAtlas.load` in `onLoad`. `AttackEffectComponent` may retain temporary rendering for non-migrated IDs but must reject Hwando IDs in an assertion during development.

- [ ] **Step 6: Run focused validation**

Run: `flutter test test/game/hwando_vfx_component_test.dart test/game/hwando_executor_test.dart test/game/weapon_system_test.dart test/game/pixel_survivor_game_loop_test.dart test/game/game_performance_budget_test.dart`

Expected: all pass; weapon balance snapshots and damage totals are unchanged.

- [ ] **Step 7: Commit**

```powershell
git add lib/game/components/hwando_vfx_component.dart lib/game/pixel_survivor_game.dart lib/game/components/attack_effect_component.dart lib/game/components/melee_arc_component.dart test/game/hwando_vfx_component_test.dart test/game/pixel_survivor_game_loop_test.dart
git commit -m "feat: render Hwando attacks with authored VFX"
```

## Plan Exit Gate

- Hwando uses reviewed PNG layers for every emitted stage.
- No Hwando attack produces the legacy geometric component or a duplicate arc.
- Focused attack, game-loop, registry, PNG, and balance tests pass.
- A manual combat capture verifies 8 directions, normal/master/blade-wave/finisher, and impact timing.
- Do not start the remaining VFX plan until this gate is reviewed.
