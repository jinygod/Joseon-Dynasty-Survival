# Hwando Release Vertical Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a release-quality Hwando slash whose authored PNG, attack timeline, inset hitbox, contact point, hit feedback, and debug overlays all derive from one contract and are verified in a landscape mobile runtime.

**Architecture:** Add immutable timeline and geometry contracts beside the existing `AttackSpec`, then queue Hwando attacks until their active strike frame instead of resolving them at creation. Rendering and hit resolution consume the same frozen contract; contact points are carried through `DamageEvent` so impact art appears where the blade actually meets the hurtbox.

**Tech Stack:** Flutter 3.44.4, Dart 3.12.2, Flame 1.37.0, `flutter_test`, `flame_test`, built-in image generation with local chroma-key removal.

## Global Constraints

- Final character, monster, weapon, and combat-effect presentation must not use circles, rectangles, ovals, or solid-colour Canvas primitives.
- Hwando visual bounds and hit geometry must derive from the same frozen attack data.
- Hwando hit geometry is 10% smaller than its visual geometry.
- Damage is active only during the strike phase; windup and recovery never deal damage.
- Contact VFX appears at the computed world contact point.
- Existing Hwando damage, cooldown, level count, combo count, and mastery balance remain unchanged.
- HUD and game logic remain independent of camera movement.
- Release execution must not fall back to generated-review, temporary, missing, or Canvas attack art.
- The work is incomplete until landscape runtime screenshots, debug geometry screenshots, tests, analyze, and an Android build are reviewed.

## File Structure

### New production files

- `lib/game/combat/attack_timeline.dart`: immutable timing values and mutable phase cursor.
- `lib/game/combat/attack_presentation_contract.dart`: frozen visual and inset hit geometry derived from `AttackInstance`.
- `lib/game/combat/combat_contact.dart`: contact point and normal value object.
- `lib/game/combat/hwando_attack_queue.dart`: owns pending Hwando timelines and emits exactly one strike activation.
- `lib/game/components/hwando_contact_vfx_component.dart`: renders only the authored contact PNG at a world contact point.
- `lib/game/components/combat_geometry_debug_component.dart`: debug-only visual bounds, hitbox, hurtbox, and contact point overlay.

### Modified production files

- `lib/game/combat/attack_spec.dart`: expose recovery terminology without changing serialized balance data.
- `lib/game/combat/attack_geometry.dart`: accept frozen geometry and return `CombatContact`.
- `lib/game/models/damage_event.dart`: carry an optional defensive copy of contact point.
- `lib/game/systems/hwando_executor.dart`: assign non-zero windup, active, and recovery values.
- `lib/game/components/enemy_component.dart`: expose the reviewed gameplay hurt radius.
- `lib/game/components/hwando_vfx_component.dart`: render timeline-specific authored layers at contract scale.
- `lib/game/content/attack_visual_registry.dart`: register ready windup, strike, recovery, and contact sheets.
- `lib/game/content/asset_catalog.dart`: register final Hwando assets.
- `lib/game/pixel_survivor_game.dart`: queue Hwando, resolve at strike activation, spawn contact art, and manage debug snapshots.
- `lib/app/vfx_gallery_screen.dart`, `lib/game/vfx_gallery_game.dart`: show 8-direction timeline and geometry review controls.

### New assets

- `assets/images/vfx/hwando/hwando_windup_128.png`
- `assets/images/vfx/hwando/hwando_strike_128.png`
- `assets/images/vfx/hwando/hwando_recovery_128.png`
- `assets/images/vfx/hwando/hwando_contact_128.png`
- `art_source/generated/hwando/*.png`: selected chroma-key source images.
- `art_source/review/hwando/*.png`: contact sheets and runtime comparisons.

---

### Task 1: Freeze the attack timeline contract

**Files:**
- Create: `lib/game/combat/attack_timeline.dart`
- Create: `test/game/attack_timeline_test.dart`
- Modify: `lib/game/combat/attack_spec.dart`

**Interfaces:**
- Produces: `enum AttackPhase { windup, active, recovery, complete }`
- Produces: `AttackTiming(windupSeconds, activeSeconds, recoverySeconds)`
- Produces: `AttackTimelineCursor(AttackTiming timing)`
- Produces: `AttackTimelineAdvance advance(double dt)` with `enteredActive` and `completed`
- Consumes later: `HwandoAttackQueue` and `HwandoVfxComponent`

- [ ] **Step 1: Write phase-boundary tests**

```dart
test('timeline enters active once and never activates in recovery', () {
  final cursor = AttackTimelineCursor(
    const AttackTiming(
      windupSeconds: .06,
      activeSeconds: .08,
      recoverySeconds: .10,
    ),
  );

  expect(cursor.advance(.059).enteredActive, isFalse);
  expect(cursor.phase, AttackPhase.windup);
  expect(cursor.advance(.001).enteredActive, isTrue);
  expect(cursor.phase, AttackPhase.active);
  expect(cursor.advance(.08).enteredActive, isFalse);
  expect(cursor.phase, AttackPhase.recovery);
  expect(cursor.advance(.10).completed, isTrue);
  expect(cursor.phase, AttackPhase.complete);
});

test('large dt still reports one active transition', () {
  final cursor = AttackTimelineCursor(
    const AttackTiming(
      windupSeconds: .06,
      activeSeconds: .08,
      recoverySeconds: .10,
    ),
  );
  expect(cursor.advance(.20).enteredActive, isTrue);
  expect(cursor.advance(.20).enteredActive, isFalse);
});
```

- [ ] **Step 2: Run the test and confirm it fails**

Run:

```powershell
D:\FlutterSdk\bin\flutter.bat test test/game/attack_timeline_test.dart
```

Expected: FAIL because `attack_timeline.dart` does not exist.

- [ ] **Step 3: Implement the timeline cursor**

Use clamped finite deltas and preserve a private `_didEnterActive` flag. `AttackTiming.totalSeconds` is the sum of all three phases. `AttackSpec.lingerSeconds` remains source-compatible and gains:

```dart
double get recoverySeconds => lingerSeconds;

AttackTiming get timing => AttackTiming(
  windupSeconds: windupSeconds,
  activeSeconds: activeSeconds,
  recoverySeconds: recoverySeconds,
);
```

`AttackTimelineCursor.advance` compares the previous and next elapsed values with `windupSeconds`, so a large delta emits `enteredActive` exactly once even if it crosses the entire active window.

- [ ] **Step 4: Run focused timing and executor tests**

Run:

```powershell
D:\FlutterSdk\bin\flutter.bat test test/game/attack_timeline_test.dart test/game/hwando_executor_test.dart
```

Expected: PASS with existing executor behavior unchanged.

- [ ] **Step 5: Commit**

```powershell
git add lib/game/combat/attack_timeline.dart lib/game/combat/attack_spec.dart test/game/attack_timeline_test.dart
git commit -m "feat: add attack phase timeline"
```

---

### Task 2: Derive visual and hit sectors from one contract

**Files:**
- Create: `lib/game/combat/attack_presentation_contract.dart`
- Create: `lib/game/combat/combat_contact.dart`
- Modify: `lib/game/combat/attack_geometry.dart`
- Modify: `lib/game/components/enemy_component.dart`
- Test: `test/game/attack_presentation_contract_test.dart`
- Test: `test/game/attack_geometry_test.dart`

**Interfaces:**
- Produces: `SectorGeometry(origin, direction, radius, angleRadians)`
- Produces: `AttackPresentationContract.fromAttack(AttackInstance attack, {double hitInsetFraction = .10})`
- Produces: `visualSector`, `hitSector`, `timing`, and `effectId`
- Produces: `CombatContact(point, normal)`
- Produces: `AttackGeometry.sectorContact(SectorGeometry geometry, Vector2 targetCenter, double targetRadius)`
- Produces: `EnemyComponent.hurtRadius`

- [ ] **Step 1: Write contract and boundary tests**

```dart
test('Hwando hit sector is ten percent inside its visual sector', () {
  final attack = AttackInstance(
    spec: AttackSpec(
      id: 'hwando_slash',
      shape: AttackShape.sector,
      damage: 8,
      range: 58,
      angleRadians: math.pi / 2,
      radius: 0,
      width: 0,
      windupSeconds: .06,
      activeSeconds: .08,
      lingerSeconds: .10,
      knockback: 45,
      slowFraction: 0,
      traits: const {AttackTrait.melee},
      presentation: AttackPresentation.normal,
    ),
    origin: Vector2(20, 30),
    direction: Vector2(1, 0),
    sequenceIndex: 0,
  );

  final contract = AttackPresentationContract.fromAttack(attack);
  expect(contract.visualSector.radius, 58);
  expect(contract.hitSector.radius, closeTo(52.2, .0001));
  expect(
    contract.hitSector.angleRadians,
    closeTo(math.pi / 2 * .9, .0001),
  );
});

test('sector contact lies on the target hurt circle inside the blade', () {
  final contact = AttackGeometry.sectorContact(
    SectorGeometry(
      origin: Vector2.zero(),
      direction: Vector2(1, 0),
      radius: 90,
      angleRadians: math.pi / 2,
    ),
    Vector2(60, 8),
    7,
  );
  expect(contact, isNotNull);
  expect(contact!.point.distanceTo(Vector2(60, 8)), closeTo(7, .001));
});
```

- [ ] **Step 2: Run the focused geometry tests**

Run:

```powershell
D:\FlutterSdk\bin\flutter.bat test test/game/attack_presentation_contract_test.dart test/game/attack_geometry_test.dart
```

Expected: FAIL because contract and contact APIs are missing.

- [ ] **Step 3: Implement immutable geometry**

`SectorGeometry` defensively clones origin and normalizes direction. `inset(.10)` multiplies radius and angle by `.90`. Reject non-finite values and inset values outside `0..0.15`.

`AttackPresentationContract.fromAttack` accepts only sector attacks in this vertical slice and copies `attack.spec.timing`.

`AttackGeometry.sectorContact` first reuses the reviewed sector overlap logic, then computes:

```dart
final fromTargetToOrigin = geometry.origin - targetCenter;
final normal = fromTargetToOrigin.length2 == 0
    ? -geometry.direction
    : (fromTargetToOrigin..normalize());
final point = targetCenter + normal * targetRadius;
return CombatContact(point: point, normal: -normal);
```

Clamp the returned point to the sector radius if the target overlaps only at the outer edge.

Expose `EnemyComponent.hurtRadius` as `size.x * .45`; this keeps the gameplay body inside the established collision size and removes the current full half-width assumption.

- [ ] **Step 4: Run geometry, enemy, and attack tests**

Run:

```powershell
D:\FlutterSdk\bin\flutter.bat test test/game/attack_presentation_contract_test.dart test/game/attack_geometry_test.dart test/game/enemy_component_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add lib/game/combat/attack_presentation_contract.dart lib/game/combat/combat_contact.dart lib/game/combat/attack_geometry.dart lib/game/components/enemy_component.dart test/game/attack_presentation_contract_test.dart test/game/attack_geometry_test.dart test/game/enemy_component_test.dart
git commit -m "feat: unify Hwando visual and hit geometry"
```

---

### Task 3: Queue Hwando until the active strike frame

**Files:**
- Create: `lib/game/combat/hwando_attack_queue.dart`
- Create: `test/game/hwando_attack_queue_test.dart`
- Modify: `lib/game/systems/hwando_executor.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `test/game/pixel_survivor_game_loop_test.dart`

**Interfaces:**
- Consumes: `AttackPresentationContract`, `AttackTimelineCursor`
- Produces: `HwandoAttackQueue.enqueue(AttackInstance attack)`
- Produces: `List<AttackPresentationContract> advance(double dt)`
- Produces: `Iterable<AttackPresentationContract> get pending`
- Produces: `void clear()`

- [ ] **Step 1: Write queue activation tests**

```dart
test('queue emits a Hwando strike only after windup', () {
  final queue = HwandoAttackQueue();
  queue.enqueue(hwandoAttack());

  expect(queue.advance(.059), isEmpty);
  expect(queue.advance(.001), hasLength(1));
  expect(queue.advance(.08), isEmpty);
  expect(queue.pending, isNotEmpty);
  queue.advance(.10);
  expect(queue.pending, isEmpty);
});
```

Add a Flame game-loop test that places an enemy inside the sector, updates `.059`, asserts unchanged health, updates `.001`, and asserts one damage application.

- [ ] **Step 2: Run queue and game-loop tests**

Run:

```powershell
D:\FlutterSdk\bin\flutter.bat test test/game/hwando_attack_queue_test.dart test/game/pixel_survivor_game_loop_test.dart
```

Expected: FAIL because Hwando still resolves immediately.

- [ ] **Step 3: Set reviewed Hwando timing**

In `_ScheduledHwandoStage.instantiate`, set:

```dart
windupSeconds: .06,
activeSeconds: .08,
lingerSeconds: .10,
```

Preserve existing combo schedule offsets and all damage, range, angle, and cooldown values.

- [ ] **Step 4: Integrate the queue into the game loop**

Add `_hwandoAttackQueue`. Change `_resolveSharedAttack` so Hwando sector attacks:

1. spawn their visual immediately;
2. enqueue instead of resolving damage;
3. emit attack audio at windup start.

At the combat update point after `_updateWeapons(simulationDt)`, call `_resolveQueuedHwando(simulationDt)`. For each activation, run a new `_resolveSharedAttackHits(attack, contract)` that uses `contract.hitSector`, `enemy.hurtRadius`, and `AttackGeometry.sectorContact`.

Non-Hwando attacks retain the existing immediate path. Clear the queue on run end, player death, and reset. Because `simulationDt` is zero during pause, level-up, and hit stop, the queue cannot advance in those states.

- [ ] **Step 5: Run all Hwando and game-loop tests**

Run:

```powershell
D:\FlutterSdk\bin\flutter.bat test test/game/hwando_executor_test.dart test/game/hwando_attack_queue_test.dart test/game/pixel_survivor_game_loop_test.dart test/game/game_performance_budget_test.dart
```

Expected: PASS, including level 1–6 combo counts and existing damage values.

- [ ] **Step 6: Commit**

```powershell
git add lib/game/combat/hwando_attack_queue.dart lib/game/systems/hwando_executor.dart lib/game/pixel_survivor_game.dart test/game/hwando_attack_queue_test.dart test/game/pixel_survivor_game_loop_test.dart
git commit -m "feat: strike Hwando on its active frame"
```

---

### Task 4: Generate and validate the authored Hwando PNG set

**Files:**
- Create: `art_source/generated/hwando/hwando_windup_chroma.png`
- Create: `art_source/generated/hwando/hwando_strike_chroma.png`
- Create: `art_source/generated/hwando/hwando_recovery_chroma.png`
- Create: `art_source/generated/hwando/hwando_contact_chroma.png`
- Create: `assets/images/vfx/hwando/hwando_windup_128.png`
- Create: `assets/images/vfx/hwando/hwando_strike_128.png`
- Create: `assets/images/vfx/hwando/hwando_recovery_128.png`
- Create: `assets/images/vfx/hwando/hwando_contact_128.png`
- Create: `docs/assets/prompts/hwando-release-vfx.md`
- Modify: `docs/assets/asset-rights-ledger.csv`
- Test: `test/game/hwando_release_asset_contract_test.dart`

**Interfaces:**
- Produces four horizontal RGBA sheets with 128×128 cells.
- Frame counts: windup 4, strike 6, recovery 4, contact 6.
- All sheets face right with pivot `(64, 64)`.

- [ ] **Step 1: Write failing PNG contract tests**

```dart
const specs = {
  'assets/images/vfx/hwando/hwando_windup_128.png': Size(512, 128),
  'assets/images/vfx/hwando/hwando_strike_128.png': Size(768, 128),
  'assets/images/vfx/hwando/hwando_recovery_128.png': Size(512, 128),
  'assets/images/vfx/hwando/hwando_contact_128.png': Size(768, 128),
};

for (final entry in specs.entries) {
  test('${entry.key} is an RGBA sheet with transparent corners', () async {
    final bytes = await File(entry.key).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final image = (await codec.getNextFrame()).image;
    expect(Size(image.width.toDouble(), image.height.toDouble()), entry.value);
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    expect(data!.getUint8(3), 0);
  });
}
```

- [ ] **Step 2: Run the contract and confirm missing assets**

Run:

```powershell
D:\FlutterSdk\bin\flutter.bat test test/game/hwando_release_asset_contract_test.dart
```

Expected: FAIL with missing file errors.

- [ ] **Step 3: Generate four source sheets with the built-in image tool**

Use one generation call per sheet. Record these normalized prompts verbatim in `docs/assets/prompts/hwando-release-vfx.md`:

```text
Use case: stylized-concept
Asset type: 2D mobile game VFX sprite sheet, four/six equal horizontal frames
Primary request: Joseon folk-fantasy Hwando [windup/strike/recovery/contact] animation, facing right
Style/medium: clean cute premium mobile game illustration, large readable shapes, restrained detail
Composition/framing: centered in each 128px square cell, identical pivot, generous padding, no frame overlap
Lighting/mood: cool moonlight from upper left, ivory blade core, pale cyan energy, dark navy outline
Scene/backdrop: perfectly flat solid #00FF00 chroma-key background
Constraints: one continuous phase progression; no character; no text; no watermark; no cast shadow; do not use #00FF00 in the effect
Avoid: solid primitive shapes, photorealism, muddy smoke, excessive bloom, cropped edges
```

For contact, add restrained gold and vermilion sparks centered at the contact origin. Generate each distinct sheet separately.

- [ ] **Step 4: Remove chroma key and assemble exact sheets**

Run the installed helper for each selected source:

```powershell
python 'C:\Users\전성진\.codex\skills\.system\imagegen\scripts\remove_chroma_key.py' --input art_source/generated/hwando/hwando_strike_chroma.png --out assets/images/vfx/hwando/hwando_strike_128.png --auto-key border --soft-matte --transparent-threshold 12 --opaque-threshold 220 --despill
```

Repeat for windup, recovery, and contact. If the generator returns a grid with margins, crop and resample with a deterministic repository script or ImageMagick so each final sheet has the exact dimensions above. Do not stretch individual frames non-uniformly.

- [ ] **Step 5: Inspect every final sheet**

Open each final PNG at original resolution. Reject and regenerate if:

- any frame crosses a cell boundary;
- the strike silhouette is not a readable fan;
- green fringe remains;
- the pivot visibly jumps;
- the contact effect fills more than 40% of a 128px cell;
- windup or recovery looks stronger than the strike.

- [ ] **Step 6: Record provenance and run asset tests**

Record tool, prompt path, output path, source/final SHA-256, generation date, and project-owned generated status in `asset-rights-ledger.csv`.

Run:

```powershell
D:\FlutterSdk\bin\flutter.bat test test/game/hwando_release_asset_contract_test.dart test/game/hwando_visual_asset_contract_test.dart
```

Expected: PASS.

- [ ] **Step 7: Commit**

```powershell
git add art_source/generated/hwando assets/images/vfx/hwando docs/assets/prompts/hwando-release-vfx.md docs/assets/asset-rights-ledger.csv test/game/hwando_release_asset_contract_test.dart
git commit -m "art: add release Hwando animation set"
```

---

### Task 5: Render the authored phases from the frozen contract

**Files:**
- Modify: `lib/game/content/attack_visual_registry.dart`
- Modify: `lib/game/content/asset_catalog.dart`
- Modify: `lib/game/combat/attack_visual_event.dart`
- Modify: `lib/game/components/hwando_vfx_component.dart`
- Modify: `lib/game/content/combat_asset_preloader.dart`
- Test: `test/game/hwando_vfx_component_test.dart`
- Test: `test/game/combat_visual_factory_test.dart`
- Test: `test/game/hwando_visual_asset_contract_test.dart`

**Interfaces:**
- Consumes: `AttackPresentationContract`
- Produces registry layer IDs `windup`, `strike`, and `recovery`
- Produces `HwandoVfxComponent.contract`
- Produces `HwandoVfxComponent.phase`

- [ ] **Step 1: Write render phase and scale tests**

Create fake 512×128 and 768×128 images. Assert:

```dart
expect(component.phase, AttackPhase.windup);
component.update(.06);
expect(component.phase, AttackPhase.active);
component.update(.08);
expect(component.phase, AttackPhase.recovery);
expect(component.visualRadius, contract.visualSector.radius);
expect(component.facingAngle, closeTo(math.pi / 2, .0001));
```

Add a source contract test that `HwandoVfxComponent` contains no `drawCircle`, `drawRect`, `drawPath`, or legacy `weapon_effects_atlas` fallback.

- [ ] **Step 2: Run the VFX tests and confirm failure**

Run:

```powershell
D:\FlutterSdk\bin\flutter.bat test test/game/hwando_vfx_component_test.dart test/game/combat_visual_factory_test.dart test/game/hwando_visual_asset_contract_test.dart
```

Expected: FAIL because the component still uses fraction-only trail/impact layers.

- [ ] **Step 3: Register final ready layers**

Replace generated-review slash layers with:

```dart
AttackVisualLayerSpec(
  id: 'windup',
  assetKey: 'vfx/hwando/hwando_windup_128.png',
  frameSize: 128,
  frameCount: 4,
  anchor: Anchor.center,
  priorityOffset: 0,
  startFraction: 0,
  endFraction: .25,
),
AttackVisualLayerSpec(
  id: 'strike',
  assetKey: 'vfx/hwando/hwando_strike_128.png',
  frameSize: 128,
  frameCount: 6,
  anchor: Anchor.center,
  priorityOffset: 1,
  startFraction: .25,
  endFraction: .583333,
),
AttackVisualLayerSpec(
  id: 'recovery',
  assetKey: 'vfx/hwando/hwando_recovery_128.png',
  frameSize: 128,
  frameCount: 4,
  anchor: Anchor.center,
  priorityOffset: 0,
  startFraction: .583333,
  endFraction: 1,
),
```

Set relevant Hwando specs to `AttackVisualStatus.ready`.

- [ ] **Step 4: Scale authored art to visual geometry**

Construct `AttackVisualEvent` with the frozen contract and let `HwandoVfxComponent` size each frame to `visualSector.radius * 2`. The component’s local origin remains the attack origin, and `facingAngle` uses the same direction as the hit sector.

The component chooses a phase from elapsed seconds, not approximate layer fractions. Missing final images throw in debug/test and do not draw a Canvas fallback.

- [ ] **Step 5: Preload all four sheets before combat**

Include registry asset keys in the existing `_visualImages` preload set. Assert `startsImageLoadOnMount == false` and that rendering does not call `images.load`.

- [ ] **Step 6: Run VFX and preload tests**

Run:

```powershell
D:\FlutterSdk\bin\flutter.bat test test/game/hwando_vfx_component_test.dart test/game/combat_visual_factory_test.dart test/game/hwando_visual_asset_contract_test.dart test/game/combat_asset_preloader_test.dart
```

Expected: PASS.

- [ ] **Step 7: Commit**

```powershell
git add lib/game/content/attack_visual_registry.dart lib/game/content/asset_catalog.dart lib/game/combat/attack_visual_event.dart lib/game/components/hwando_vfx_component.dart lib/game/content/combat_asset_preloader.dart test/game/hwando_vfx_component_test.dart test/game/combat_visual_factory_test.dart test/game/hwando_visual_asset_contract_test.dart test/game/combat_asset_preloader_test.dart
git commit -m "feat: render authored Hwando attack phases"
```

---

### Task 6: Apply contact-point impact and bounded hit feedback

**Files:**
- Create: `lib/game/components/hwando_contact_vfx_component.dart`
- Modify: `lib/game/models/damage_event.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `lib/game/systems/combat_feedback_controller.dart`
- Test: `test/game/hwando_contact_vfx_component_test.dart`
- Test: `test/game/combat_feedback_controller_test.dart`
- Test: `test/game/pixel_survivor_game_loop_test.dart`

**Interfaces:**
- Consumes: `CombatContact`, final contact PNG
- Produces: `DamageEvent.contactPoint`
- Produces: `CombatFeedbackRequest.hwandoHit()`
- Produces: `HwandoContactVfxComponent(position, direction, image, onExpired)`

- [ ] **Step 1: Write contact propagation tests**

```dart
test('damage event defensively carries the actual contact point', () {
  final point = Vector2(30, 40);
  final event = DamageEvent(
    target: enemy,
    damage: 8,
    knockback: 45,
    direction: Vector2(1, 0),
    weaponId: hwandoSlash,
    sourceId: hwandoSlash,
    traits: const {AttackTrait.melee},
    isCritical: false,
    contactPoint: point,
  );
  point.setZero();
  expect(event.contactPoint, Vector2(30, 40));
});
```

Add a game-loop test asserting the mounted contact VFX position equals the computed contact point rather than `enemy.position`.

- [ ] **Step 2: Run contact and feedback tests**

Run:

```powershell
D:\FlutterSdk\bin\flutter.bat test test/game/hwando_contact_vfx_component_test.dart test/game/combat_feedback_controller_test.dart test/game/pixel_survivor_game_loop_test.dart
```

Expected: FAIL because damage events currently spawn generic hit art at enemy center.

- [ ] **Step 3: Carry contact through damage resolution**

Add an optional cloned `contactPoint` to `DamageEvent`. In `_resolveSharedAttackHits`, attach `contact.point`.

When a non-blocked event has `weaponId == hwandoSlash` and a contact point:

- spawn `HwandoContactVfxComponent` at that point;
- do not spawn the generic `CombatEffectKind.hit` ring;
- preserve critical damage numbers and critical sound;
- use `event.direction` for contact VFX rotation.

- [ ] **Step 4: Implement contact art**

The component renders six 128px frames over `.15` seconds at 36×36 world units. It loads no image on mount; the preloaded image is required in its constructor. It contains no Canvas fallback.

- [ ] **Step 5: Add per-contact hit stop**

Add:

```dart
const CombatFeedbackRequest.hwandoHit()
  : hitStopSeconds = .030,
    shakeMagnitude = 0,
    presentation = AttackPresentation.normal;
```

Request it only once per activated Hwando attack, after at least one effective damage event. Preserve the existing global `.035` cap so dense multi-target slashes do not stack unbounded hit stop.

- [ ] **Step 6: Run contact, feedback, and population tests**

Run:

```powershell
D:\FlutterSdk\bin\flutter.bat test test/game/hwando_contact_vfx_component_test.dart test/game/combat_feedback_controller_test.dart test/game/pixel_survivor_game_loop_test.dart test/game/game_performance_budget_test.dart
```

Expected: PASS with contact components counted against `maxCombatEffects`.

- [ ] **Step 7: Commit**

```powershell
git add lib/game/components/hwando_contact_vfx_component.dart lib/game/models/damage_event.dart lib/game/pixel_survivor_game.dart lib/game/systems/combat_feedback_controller.dart test/game/hwando_contact_vfx_component_test.dart test/game/combat_feedback_controller_test.dart test/game/pixel_survivor_game_loop_test.dart
git commit -m "feat: place Hwando impact at blade contact"
```

---

### Task 7: Add debug geometry and a deterministic landscape review gallery

**Files:**
- Create: `lib/game/components/combat_geometry_debug_component.dart`
- Create: `test/game/combat_geometry_debug_component_test.dart`
- Modify: `lib/game/vfx_gallery_game.dart`
- Modify: `lib/app/vfx_gallery_screen.dart`
- Modify: `test/app/vfx_gallery_screen_test.dart`
- Modify: `test/game/vfx_gallery_game_test.dart`

**Interfaces:**
- Consumes: pending `AttackPresentationContract`, target center/radius, latest `CombatContact`
- Produces toggles for `visual bounds`, `hitbox`, `hurtbox`, and `contact point`
- Produces direction index `0..7`
- Produces playback rates `.25`, `.5`, and `1.0`

- [ ] **Step 1: Write debug ownership and toggle tests**

Assert the component:

- is created only when `kDebugMode`;
- uses the contract visual sector and hit sector without recomputing constants;
- exposes the latest contact point;
- is absent from a release-mode source path;
- responds to all four gallery toggles.

- [ ] **Step 2: Run debug and gallery tests**

Run:

```powershell
D:\FlutterSdk\bin\flutter.bat test test/game/combat_geometry_debug_component_test.dart test/game/vfx_gallery_game_test.dart test/app/vfx_gallery_screen_test.dart
```

Expected: FAIL because the gallery has only the legacy hitbox toggle.

- [ ] **Step 3: Implement debug-only drawing**

Draw debug geometry only in `CombatGeometryDebugComponent`:

- visual bounds: cyan stroke;
- active hitbox: vermilion stroke;
- inactive hitbox: translucent gold stroke;
- hurtbox: ivory stroke;
- contact point: magenta cross;
- labels: current phase and remaining milliseconds.

These primitives are permitted because the component is development-only and never substitutes for authored art.

- [ ] **Step 4: Add deterministic gallery controls**

Use the real registry, component, and contracts. Provide 8 directions, three playback rates, loop/step, dark/light stage samples, and all geometry toggles. Do not build a separate fake renderer.

- [ ] **Step 5: Run gallery tests and inspect manually**

Run:

```powershell
D:\FlutterSdk\bin\flutter.bat test test/game/combat_geometry_debug_component_test.dart test/game/vfx_gallery_game_test.dart test/app/vfx_gallery_screen_test.dart
```

Expected: PASS.

Open the gallery and verify all eight directions keep the same pivot and the hit sector stays 10% inside the visual fan.

- [ ] **Step 6: Commit**

```powershell
git add lib/game/components/combat_geometry_debug_component.dart lib/game/vfx_gallery_game.dart lib/app/vfx_gallery_screen.dart test/game/combat_geometry_debug_component_test.dart test/game/vfx_gallery_game_test.dart test/app/vfx_gallery_screen_test.dart
git commit -m "feat: inspect Hwando visual and hit geometry"
```

---

### Task 8: Capture and review landscape runtime evidence

**Files:**
- Create: `art_source/review/hwando/hwando_gallery_dark.png`
- Create: `art_source/review/hwando/hwando_gallery_light.png`
- Create: `art_source/review/hwando/hwando_combat_16_9.png`
- Create: `art_source/review/hwando/hwando_combat_19_5_9.png`
- Create: `art_source/review/hwando/hwando_debug_contact.png`
- Modify: `test/app/balanced_casual_combat_golden_test.dart`
- Create: `test/app/goldens/hwando_release_landscape_16_9.png`
- Create: `docs/testing/hwando-release-vertical-slice-report.md`

**Interfaces:**
- Produces a 960×540 deterministic golden.
- Produces real Chrome screenshots at 16:9 and 19.5:9 landscape.
- Produces a debug overlay screenshot with contact point.

- [ ] **Step 1: Add a deterministic landscape golden**

Use a fixed seed, one exorcist, three stationary bandits positioned inside, on the boundary, and outside the hit sector. Advance to the active strike frame and capture `GameWidget` plus HUD at 960×540.

- [ ] **Step 2: Generate and inspect the golden**

Run:

```powershell
D:\FlutterSdk\bin\flutter.bat test --update-goldens test/app/balanced_casual_combat_golden_test.dart
```

Inspect the PNG directly. Reject it if:

- the slash reads as a rectangle or solid primitive;
- the player is hidden by the trail;
- the outside enemy shows a hit flash;
- the contact effect is centered on the enemy instead of the blade edge;
- the HUD overlaps the attack.

- [ ] **Step 3: Run Chrome in landscape and capture real frames**

Run:

```powershell
D:\FlutterSdk\bin\flutter.bat run -d chrome --web-port 7357
```

Use browser device emulation for 960×540 and 932×430. Capture normal combat and debug overlay frames into `art_source/review/hwando/`.

- [ ] **Step 4: Perform one-issue-at-a-time visual iteration**

If a failure is visible, classify it as exactly one of:

- silhouette;
- contrast;
- pivot;
- phase timing;
- visual/hit alignment;
- contact placement;
- effect occlusion.

Regenerate only the affected sheet or change only the relevant contract value, rerun focused tests, and recapture. Do not update the golden to accept a known defect.

- [ ] **Step 5: Write the evidence report**

Record:

- before/after image paths;
- final timing and 10% inset;
- tested inside/boundary/outside coordinates;
- contact point observation;
- Chrome viewport sizes;
- any regenerated asset and reason;
- focused test results.

- [ ] **Step 6: Commit**

```powershell
git add art_source/review/hwando test/app/balanced_casual_combat_golden_test.dart test/app/goldens/hwando_release_landscape_16_9.png docs/testing/hwando-release-vertical-slice-report.md
git commit -m "test: review Hwando landscape combat"
```

---

### Task 9: Run final quality gates and Android build

**Files:**
- Modify: `docs/testing/hwando-release-vertical-slice-report.md`
- Modify only if a gate exposes a defect: files already owned by Tasks 1–8

**Interfaces:**
- Produces final analyzer, full test, Android build, and runtime review evidence.

- [ ] **Step 1: Run the related Hwando suite**

Run:

```powershell
D:\FlutterSdk\bin\flutter.bat test test/game/attack_timeline_test.dart test/game/attack_presentation_contract_test.dart test/game/attack_geometry_test.dart test/game/hwando_attack_queue_test.dart test/game/hwando_executor_test.dart test/game/hwando_vfx_component_test.dart test/game/hwando_contact_vfx_component_test.dart test/game/hwando_release_asset_contract_test.dart test/game/hwando_visual_asset_contract_test.dart test/game/pixel_survivor_game_loop_test.dart test/app/balanced_casual_combat_golden_test.dart
```

Expected: PASS.

- [ ] **Step 2: Run analyzer**

Run:

```powershell
D:\FlutterSdk\bin\flutter.bat analyze
```

Expected: `No issues found!`

- [ ] **Step 3: Run the full test suite**

First ensure no stale `flutter_tester` process from this worktree is running. Then run:

```powershell
D:\FlutterSdk\bin\flutter.bat test
```

Expected: all tests PASS. If `ink_sparkle.frag` is missing again, record the exact SDK path and rerun the failed files serially; do not classify an environment runner failure as a code pass.

- [ ] **Step 4: Build Android**

Run:

```powershell
D:\FlutterSdk\bin\flutter.bat build apk --debug
```

Expected: PASS and `build/app/outputs/flutter-apk/app-debug.apk` exists.

- [ ] **Step 5: Review the Android artifact on a real or emulated landscape device**

Verify:

- windup, active, and recovery are visibly distinct;
- no invisible hit before the strike;
- the contact effect is on the blade/enemy intersection;
- rapid direction changes rotate art and hitbox together;
- pause and level-up do not duplicate damage;
- no image loads or visible fallback occur during combat;
- frame pacing does not visibly drop during dense multi-target hits.

- [ ] **Step 6: Update the final report and commit**

Add exact command results, APK path and hash, screenshot links, remaining mobile-device-only checks, and before/after comparison.

```powershell
git add docs/testing/hwando-release-vertical-slice-report.md
git commit -m "docs: verify release Hwando vertical slice"
```

## Plan Self-Review

- Spec coverage: the plan covers authored PNG generation, single-source geometry, 10% inset, windup/active/recovery, actual contact point, hit stop, debug bounds, runtime screenshots, tests, analyze, and Android build.
- Scope: only the Hwando vertical slice and its reusable foundation are implemented; the generic “brick” projectile, actor visibility, codex, and lobby remain separate approved follow-up passes.
- Type consistency: `AttackTiming`, `AttackPresentationContract`, `SectorGeometry`, `CombatContact`, and `HwandoAttackQueue` are defined before consumers.
- Placeholder scan: every code, asset, test, execution, and review step has explicit inputs, commands, and acceptance conditions.
- Balance preservation: damage, cooldown, range progression, combo count, and mastery behavior are not redesigned.

