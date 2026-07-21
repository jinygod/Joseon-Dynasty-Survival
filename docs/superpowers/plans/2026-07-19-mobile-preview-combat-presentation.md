# Mobile Preview and Combat Presentation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a debug-web portrait preview, double actor artwork, give the static player subtle procedural motion, and make hwando slashes use one deterministic target direction without changing balance or collision geometry.

**Architecture:** A root Flutter preview widget owns browser-only framing, `ActorRenderSizes` continues to own all visual sizes, `PlayerComponent` owns render-only pose state, and a focused `HwandoAimResolver` produces the immutable direction consumed by both `WeaponSystem` and `MeleeArcComponent`. Runtime platform gating and pure direction selection are independently testable.

**Tech Stack:** Flutter 3.44.4, Dart 3.12.2, Flame 1.37.0, flutter_test, flame_test

## Global Constraints

- Use a 390 by 844 debug-web preview with `BoxFit.contain` and a centered neutral outer background.
- Default `flutter run -d chrome` to preview enabled; allow `--dart-define=MOBILE_PREVIEW=false` to disable it.
- Never apply preview framing or synthetic safe-area padding on Android or release builds.
- Change visual sizes from player 54 to 108, normal 27 to 54, elite 40.5 to 81, and boss 63 to 126.
- Preserve collision sizes at player 24, normal 18, elite 40, and boss 42.
- Preserve actor anchors, foot positions, aspect ratio, nearest-neighbor filtering, camera zoom, movement speed, health, attack, spawn, progression, and animation timing values.
- Keep hwando damage, cooldown, range, knockback, projectile count, and level behavior unchanged.
- Do not modify or create image assets.
- Preserve every pre-existing uncommitted working-tree change and do not commit implementation changes unless explicitly requested.

---

### Task 1: Debug-web mobile preview policy and frame

**Files:**
- Create: `lib/app/mobile_preview.dart`
- Modify: `lib/app/pixel_survivor_app.dart`
- Create: `test/app/mobile_preview_test.dart`

**Interfaces:**
- Produces: `MobilePreviewPolicy.shouldEnable({required bool isWeb, required bool isDebug, required bool requested}) -> bool`.
- Produces: `MobilePreviewFrame({required Widget child, required bool enabled})` with `referenceSize == Size(390, 844)`.
- Consumes: `MobilePreviewFrame` from `PixelSurvivorApp` through `MaterialApp.builder`.

- [ ] **Step 1: Write failing preview policy and geometry tests**

Add widget tests that assert the policy is true only for requested debug web,
that an enabled preview exposes a 390 by 844 inner `SizedBox`, that a 780 by
1000 parent produces a contained 390 by 844 logical frame without distortion,
and that `enabled: false` returns the child without preview background or
synthetic `MediaQuery` padding.

- [ ] **Step 2: Run the focused test and verify RED**

Run:

```powershell
flutter test --no-pub test/app/mobile_preview_test.dart
```

Expected: compilation fails because `mobile_preview.dart` and its interfaces do not exist.

- [ ] **Step 3: Implement the minimal preview widget and root integration**

Implement a const policy with the `MOBILE_PREVIEW` compile-time flag defaulting
to true. Gate it with `kIsWeb && kDebugMode`. For enabled mode use
`ColoredBox -> Center -> FittedBox(fit: BoxFit.contain) -> SizedBox(390, 844)`
and a scoped `MediaQuery` with the reference size and representative portrait
safe-area padding. Add it through `MaterialApp.builder`; when disabled return
the app child unchanged.

- [ ] **Step 4: Format and verify GREEN**

Run:

```powershell
dart format lib/app/mobile_preview.dart lib/app/pixel_survivor_app.dart test/app/mobile_preview_test.dart
flutter test --no-pub test/app/mobile_preview_test.dart
```

Expected: all preview tests pass.

---

### Task 2: Double visual actor sizes while preserving collision contracts

**Files:**
- Modify: `test/game/actor_render_sizes_test.dart`
- Modify: `test/game/player_component_test.dart`
- Modify: `test/game/enemy_component_test.dart`
- Modify: `test/game/boss_component_visual_test.dart`
- Modify: `lib/game/content/actor_render_sizes.dart`

**Interfaces:**
- Consumes: existing `ActorRenderSizes` getters.
- Produces: player visual 108, normal visual 54, elite visual 81, boss visual 126 with unchanged collision constants and hierarchy ratios.

- [ ] **Step 1: Change visual-size assertions to the approved values**

Update the focused tests to expect 108, 54, 81, and 126 while retaining every
collision, `Anchor.center`, and `FilterQuality.none` assertion. Add snapshot
assertions for character and enemy balance fields before and after component
creation so render sizing cannot mutate health, damage, speed, or experience.

- [ ] **Step 2: Run the focused tests and verify RED**

Run:

```powershell
flutter test --no-pub test/game/actor_render_sizes_test.dart test/game/player_component_test.dart test/game/enemy_component_test.dart test/game/boss_component_visual_test.dart
```

Expected: visual-size expectations fail with the current 54, 27, 40.5, and 63 values while collision and balance assertions pass.

- [ ] **Step 3: Update only centralized visual constants**

Change `playerVisual`, `normalEnemyVisual`, `eliteEnemyVisual`, and `bossVisual`
in `actor_render_sizes.dart`. Do not change component sizes, render pivots,
collision math, or any content definition.

- [ ] **Step 4: Format and verify GREEN**

Run the focused test command from Step 2 after formatting the five files.

Expected: all sizing, anchor, filtering, hierarchy, collision, and balance tests pass.

---

### Task 3: Render-only procedural player movement and attack pose

**Files:**
- Modify: `test/game/player_component_test.dart`
- Modify: `lib/game/components/player_component.dart`

**Interfaces:**
- Produces: `PlayerComponent.lastMovementDirection`, `lastAttackDirection`, `preferredAttackDirection`, `isMoving`, and `playAttack(Vector2 direction)`.
- Consumes: movement input in `applyInput`; attack direction later supplied by `PixelSurvivorGame`.
- Invariant: `playAttack` and `update` never mutate component world position.

- [ ] **Step 1: Write failing behavior tests**

Add tests that prove horizontal movement updates facing, vertical-only movement
keeps the last horizontal facing, stopping retains a decaying motion blend,
`playAttack` stores a normalized direction, and applying movement before and
after `playAttack` advances the player by the same distance as movement without
an attack. Assert `update` during the pose leaves world position and component
size unchanged.

- [ ] **Step 2: Run the player test and verify RED**

Run:

```powershell
flutter test --no-pub test/game/player_component_test.dart
```

Expected: compilation fails because the direction getters and `playAttack` do not exist.

- [ ] **Step 3: Implement minimal pose state**

Track normalized last movement and attack directions, movement phase/blend,
desired and displayed facing, and a 0.15 second attack timer. Update these
values with clamped interpolation. Keep `applyInput` movement math unchanged.
When attacking, attack facing has priority while movement continues to update
the stored movement direction.

- [ ] **Step 4: Apply transforms only inside `render`**

Around the existing bottom-center sprite pivot, save the canvas and combine a
small blend-scaled sine bob, alternating tilt, complementary squash/stretch,
interpolated horizontal facing, and the short attack thrust/rotation/recoil.
Restore the canvas after drawing. Do not change `position`, `size`, or collision
geometry.

- [ ] **Step 5: Format and verify GREEN**

Run the focused player test. Expected: all old movement and damage-state tests plus the new procedural-motion tests pass.

---

### Task 4: Deterministic hwando aim resolver

**Files:**
- Create: `lib/game/systems/hwando_aim_resolver.dart`
- Create: `test/game/hwando_aim_resolver_test.dart`

**Interfaces:**
- Produces: immutable `HwandoAimDecision { EnemyComponent? target; Vector2 direction; }`.
- Produces: `HwandoAimResolver.resolve({required Vector2 origin, required Iterable<EnemyComponent> enemies, required double maxRange, required Vector2 fallbackDirection})`.
- Filters: `!enemy.isDead && !enemy.isRemoving`, center distance within `maxRange`, deterministic distance then `enemyId` then input-index ordering.

- [ ] **Step 1: Write failing resolver tests**

Cover nearest world-distance selection across normal, elite, and boss
components; dead exclusion; removing exclusion; range exclusion; deterministic
equal-distance selection; normalized target direction; and normalized fallback
including a zero-vector fallback resolving to `(1, 0)`.

- [ ] **Step 2: Run the resolver test and verify RED**

Run:

```powershell
flutter test --no-pub test/game/hwando_aim_resolver_test.dart
```

Expected: compilation fails because the resolver does not exist.

- [ ] **Step 3: Implement the pure resolver**

Iterate once, retain source index, compare squared distances, then identifier,
then index. Clone all returned vectors and normalize exactly once. Do not mutate
enemy positions or the caller's fallback vector.

- [ ] **Step 4: Format and verify GREEN**

Run the focused resolver test. Expected: every target, exclusion, range, tie, and fallback test passes.

---

### Task 5: Route one hwando direction through effect, hit cone, damage, and player pose

**Files:**
- Modify: `test/game/weapon_system_test.dart`
- Modify: `test/game/player_component_test.dart`
- Modify: `lib/game/systems/weapon_system.dart`
- Modify: `lib/game/components/melee_arc_component.dart`
- Modify: `lib/game/pixel_survivor_game.dart`

**Interfaces:**
- Extends: `WeaponSystem.tick(..., Vector2? hwandoFallbackDirection)`.
- Extends: `WeaponTickResult.hwandoDirection` as a cloned immutable-by-convention `Vector2?`.
- Produces: `MeleeArcComponent.facingAngle` derived from its normalized `direction`.
- Consumes: `PlayerComponent.preferredAttackDirection`; calls `player.playAttack(result.hwandoDirection!)` only when hwando fires.

- [ ] **Step 1: Write failing integration tests**

Add weapon tests proving the nearest in-range enemy controls
`hwandoDirection`, dead and out-of-range enemies do not, no enemy still emits a
slash along the supplied fallback when cooldown permits, the first arc direction
matches the result direction at level one, `facingAngle == atan2(y, x)`, and
damage events target exactly enemies for which that same arc's `containsEnemy`
is true. Add a game/player-level assertion that the player still moves during a
frame where hwando fires.

- [ ] **Step 2: Run focused tests and verify RED**

Run:

```powershell
flutter test --no-pub test/game/weapon_system_test.dart test/game/player_component_test.dart test/game/pixel_survivor_game_loop_test.dart
```

Expected: compilation fails because fallback input, result direction, angle getter, and attack-pose routing are absent.

- [ ] **Step 3: Integrate the resolver into only `_fireHwando`**

Initialize result lists before the no-enemy branch. Resolve and fire hwando with
its existing effective range and cooldown even when no valid target exists,
using the supplied fallback. Skip the other enemy-dependent weapon methods when
the alive candidate list is empty. Preserve their prior behavior when enemies
exist. Store the frozen base direction in `WeaponTickResult`.

- [ ] **Step 4: Make effect angle and game pose consume the frozen direction**

Expose the arc angle getter and use it in render. Pass
`player.preferredAttackDirection` into the weapon tick. When a result contains a
hwando direction, call `player.playAttack` after the tick without modifying
movement input, player position, cooldown, or damage timing.

- [ ] **Step 5: Format and verify GREEN**

Run the focused tests from Step 2. Expected: target, fallback, cone/effect consistency, and uninterrupted movement tests pass along with existing weapon-level behavior.

---

### Task 6: Document preview commands and size report

**Files:**
- Modify: `README.md`
- Modify: `docs/testing/local-playtest.md`

**Interfaces:**
- Documents: default preview and full-browser commands, 390 by 844 behavior, debug-web-only scope, actor before/after collision table, and portrait visual checks.

- [ ] **Step 1: Add executable local commands and QA checklist**

Document both commands exactly, note that Android never receives the frame,
and add checks for contain scaling, safe areas, foot alignment, sprite
sharpness, actor hierarchy, dense-wave overlap, hwando direction, and
movement-during-attack.

- [ ] **Step 2: Check documentation and formatting**

Run `git diff --check -- README.md docs/testing/local-playtest.md` and verify both `MOBILE_PREVIEW` commands appear with `rg`.

Expected: no whitespace errors and both execution modes are documented.

---

### Task 7: Full verification and portrait visual QA

**Files:**
- Verify all changed source, test, and documentation files.

**Interfaces:**
- Produces: fresh analyzer, complete test, web build, Android debug build, and manual portrait-preview evidence.

- [ ] **Step 1: Prove scope and unchanged asset bytes**

Run `git diff --check`, inspect `git diff --stat`, confirm no image file is in the
new diff, and inspect all balance/content definition diffs. Expected: only the
four requested areas, tests, and documentation changed; no balance or PNG
change was introduced by this implementation.

- [ ] **Step 2: Run analysis and full tests**

Using the repository's ASCII-drive workaround if required, run:

```powershell
flutter analyze --no-pub
flutter test --no-pub --concurrency=1
```

Expected: analyzer exits 0 and the full suite reports zero failures.

- [ ] **Step 3: Build Chrome web and Android debug artifacts**

Run:

```powershell
flutter build web --no-pub
flutter build apk --debug --no-pub
```

Expected: both builds exit 0.

- [ ] **Step 4: Run debug Chrome portrait QA**

Launch default Chrome debug mode and confirm the app is centered in a 390 by
844 contained frame at multiple browser sizes. Enter combat and inspect player,
normal, elite, and boss hierarchy; feet; crispness; overlap; procedural motion;
movement during attack; and hwando effect direction. Then launch with
`MOBILE_PREVIEW=false` and confirm full-browser behavior.

- [ ] **Step 5: Report evidence and remaining visual tuning**

Report exact before/after visual and collision sizes, targeting data flow,
verification command exit results, whether doubled art feels crowded without a
camera workaround, and any remaining manual device-only observations.
