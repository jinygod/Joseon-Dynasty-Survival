# Eight-Weapon Roster Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Expand the playable weapon roster from four runtime weapons to eight distinct five-level weapons and ship the result through tests, web, and Android builds.

**Architecture:** Keep targeting and cooldown decisions in `WeaponSystem`, keep repeated frost-field behavior in a focused Flame component, and keep enemy movement modifiers authoritative in `EnemyComponent`. `PixelSurvivorGame` remains the integration boundary that adds visual components, applies repeated field damage, resets environmental slow every frame, records telemetry, and maps new weapons to reusable temporary audio cues.

**Tech Stack:** Flutter 3.44.4, Dart 3.12.2, Flame, flutter_test, shared_preferences, PowerShell release tooling.

## Global Constraints

- The roster must contain exactly eight unique weapons and every weapon must have exactly five levels.
- Existing four weapon behavior and save schema version 1 remain compatible.
- New art remains temporary and replaceable through central weapon IDs and atlas mapping; code-rendered fallback visuals are required.
- Frost slow never stacks: the strongest active field wins and movement returns to normal when no field contains the enemy.
- At most three frost fields and one ward visual may be active for one player.
- Singijeon creates at most nine projectiles in one fire event.
- All new damage must flow through existing `DamageEvent` handling so kills, telemetry, and audio remain consistent.
- Worktree, temporary files, and Pub cache live on D: while the final merged source and build artifacts remain in the C: project.

---

### Task 1: Lock the eight-weapon content contract

**Files:**
- Modify: `lib/game/content/weapon_definitions.dart`
- Modify: `lib/game/content/weapon_level_definitions.dart`
- Modify: `lib/game/content/unlock_definitions.dart`
- Modify: `test/game/content_definitions_test.dart`
- Modify: `test/game/progression_system_test.dart`

**Interfaces:**
- Produces: `const frostFlask = 'frost_flask'` and `const windThunderFan = 'wind_thunder_fan'`.
- Produces: `WeaponLevelDefinition.durationSeconds` and `WeaponLevelDefinition.slowFraction`, both defaulting to zero for existing callers.
- Produces: eight `weaponDefinitions` entries and forty `weaponLevels` rows.

- [ ] **Step 1: Write failing content tests**

```dart
test('release roster has eight unique five-level weapons', () {
  expect(weaponDefinitions, hasLength(8));
  expect(weaponDefinitions.map((item) => item.id).toSet(), hasLength(8));
  for (final weapon in weaponDefinitions) {
    expect(weapon.maxLevel, 5, reason: weapon.id);
    expect(weaponLevels[weapon.id], hasLength(5), reason: weapon.id);
  }
});

test('new weapon names and elements are fixed', () {
  expect(_weapon(frostFlask).name, '서리 호리병');
  expect(_weapon(frostFlask).element, ElementType.ice);
  expect(_weapon(windThunderFan).name, '풍뢰 부채');
  expect(_weapon(windThunderFan).element, ElementType.lightning);
});
```

- [ ] **Step 2: Run the tests and verify RED**

Run: `flutter test test/game/content_definitions_test.dart test/game/progression_system_test.dart`

Expected: FAIL because the two IDs, extra level fields, and eight-item roster do not exist.

- [ ] **Step 3: Add the content definitions and exact five-level data**

Add optional fields to `WeaponLevelDefinition`:

```dart
this.durationSeconds = 0,
this.slowFraction = 0,
```

Use these level tuples `(damage, cooldown, range, projectileCount, pierce, chainCount, knockback, duration, slow)`:

```text
장승 결계: (4,.80,72,1,0,0,18,0,0), (5,.70,80,1,0,0,22,0,0),
             (6,.60,88,1,0,0,28,0,0), (7,.52,98,1,0,0,34,0,0),
             (9,.45,108,1,0,0,42,0,0)
신기전:     (5,2.20,460,4,0,0,8,0,0), (6,2.00,470,5,0,0,8,0,0),
             (7,1.80,480,6,0,0,10,0,0), (8,1.60,500,7,1,0,10,0,0),
             (9,1.40,520,9,1,0,12,0,0)
서리 호리병:(4,2.80,60,1,0,0,12,2.5,.20), (5,2.60,70,1,0,0,14,3.0,.25),
             (6,2.40,80,1,0,0,16,3.5,.30), (7,2.20,90,1,0,0,18,4.0,.38),
             (8,2.00,100,1,0,0,20,4.5,.45)
풍뢰 부채:  (9,1.60,90,1,0,0,50,0,0), (11,1.40,102,1,0,0,62,0,0),
             (13,1.20,114,1,0,0,74,0,0), (15,1.05,126,1,0,0,86,0,0),
             (18,.90,140,2,0,0,100,0,0)
```

Add unlock goals `defeat_two_bosses` for `frostFlask` and `unlock_six_weapons` for `windThunderFan`. Both new weapons remain `startsUnlocked: false`.

- [ ] **Step 4: Run focused tests and verify GREEN**

Run: `flutter test test/game/content_definitions_test.dart test/game/progression_system_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add lib/game/content test/game/content_definitions_test.dart test/game/progression_system_test.dart
git commit -m "feat: define eight-weapon roster"
```

### Task 2: Add authoritative frost slow and repeated frost fields

**Files:**
- Create: `lib/game/components/frost_field_component.dart`
- Modify: `lib/game/components/enemy_component.dart`
- Create: `test/game/frost_field_component_test.dart`
- Modify: `test/game/enemy_component_test.dart`

**Interfaces:**
- Produces: `EnemyComponent.setEnvironmentalSlow(double fraction)`.
- Produces: `EnemyComponent.environmentalSlowFraction` and `effectiveMoveSpeed` getters.
- Produces: `FrostFieldComponent.collectDamageEvents(Iterable<EnemyComponent>)`, `containsEnemy`, `slowFraction`, `isExpired`.

- [ ] **Step 1: Write failing slow and field tests**

```dart
test('environmental slow changes movement without mutating base speed', () {
  final enemy = testEnemy(moveSpeed: 100);
  enemy.setEnvironmentalSlow(.45);
  enemy.moveToward(Vector2(100, 0), 1);
  expect(enemy.position.x, closeTo(55, .001));
  expect(enemy.moveSpeed, 100);
  enemy.setEnvironmentalSlow(0);
  expect(enemy.effectiveMoveSpeed, 100);
});

test('frost field ticks repeatedly and expires', () {
  final field = FrostFieldComponent(
    weaponId: frostFlask,
    damage: 6,
    radius: 80,
    durationSeconds: 1.1,
    tickSeconds: .5,
    slowFraction: .3,
    position: Vector2.zero(),
  );
  final enemy = testEnemy(position: Vector2(20, 0));
  field.update(.5);
  expect(field.collectDamageEvents([enemy]), hasLength(1));
  field.update(.5);
  expect(field.collectDamageEvents([enemy]), hasLength(1));
  field.update(.2);
  expect(field.isExpired, isTrue);
});
```

- [ ] **Step 2: Run and verify RED**

Run: `flutter test test/game/enemy_component_test.dart test/game/frost_field_component_test.dart`

Expected: FAIL because slow APIs and `FrostFieldComponent` are missing.

- [ ] **Step 3: Implement minimal authoritative slow**

```dart
double _environmentalSlowFraction = 0;
double get environmentalSlowFraction => _environmentalSlowFraction;
double get effectiveMoveSpeed => moveSpeed * (1 - _environmentalSlowFraction);

void setEnvironmentalSlow(double fraction) {
  if (!fraction.isFinite || fraction < 0 || fraction >= .8) {
    throw ArgumentError.value(fraction, 'fraction');
  }
  _environmentalSlowFraction = fraction;
}
```

Change movement to use `effectiveMoveSpeed * speedMultiplier * dt`.

- [ ] **Step 4: Implement `FrostFieldComponent`**

The component owns elapsed time and a pending tick count. `update` adds due ticks, `collectDamageEvents` consumes one pending tick and returns frost `DamageEvent`s for living enemies in range. Render a translucent cyan circle so no image asset is required.

- [ ] **Step 5: Run focused tests and commit**

Run: `flutter test test/game/enemy_component_test.dart test/game/frost_field_component_test.dart`

Expected: PASS.

```powershell
git add lib/game/components test/game/enemy_component_test.dart test/game/frost_field_component_test.dart
git commit -m "feat: add frost field movement control"
```

### Task 3: Make WeaponSystem fire all four new weapons

**Files:**
- Modify: `lib/game/systems/weapon_system.dart`
- Modify: `test/game/weapon_system_test.dart`

**Interfaces:**
- Extends: `WeaponTickResult.frostFields` as `List<FrostFieldComponent>`.
- Keeps: `damageEvents`, `projectiles`, `meleeArcs`, `areaAttacks`, and `firedWeaponIds` backward compatible.
- Consumes: eight weapon IDs and level definitions from Task 1.

- [ ] **Step 1: Write one failing test per new weapon**

```dart
EnemyComponent target(double x, double y) => EnemyComponent(
  enemyId: 'target', maxHealth: 100, moveSpeed: 0, damage: 0,
  position: Vector2(x, y),
);

test('ward damages every enemy inside its radius', () {
  final result = WeaponSystem(initialLevels: const {jangseungWard: 1})
      .tick(dt: 1, origin: Vector2.zero(), enemies: [target(30, 0), target(100, 0)]);
  expect(result.damageEvents, hasLength(1));
  expect(result.damageEvents.single.weaponId, jangseungWard);
});

test('singijeon aims a fan at the densest direction', () {
  final result = WeaponSystem(initialLevels: const {singijeonVolley: 1})
      .tick(dt: 3, origin: Vector2.zero(), enemies: [target(50, 0), target(60, 5), target(-40, 0)]);
  expect(result.projectiles, hasLength(4));
  expect(result.projectiles.every((shot) => shot.velocity.x > 0), isTrue);
});

test('frost flask creates a field at a dense target', () {
  final result = WeaponSystem(initialLevels: const {frostFlask: 1})
      .tick(dt: 3, origin: Vector2.zero(), enemies: [target(80, 0), target(82, 4)]);
  expect(result.frostFields, hasLength(1));
  expect(result.frostFields.single.weaponId, frostFlask);
  expect(result.frostFields.single.slowFraction, .2);
});

test('level five wind thunder fan sweeps both directions', () {
  final result = WeaponSystem(initialLevels: const {windThunderFan: 5})
      .tick(dt: 2, origin: Vector2.zero(), enemies: [target(20, 0)]);
  expect(result.meleeArcs, hasLength(2));
  expect(result.meleeArcs[0].direction.dot(result.meleeArcs[1].direction), closeTo(-1, .001));
});
```

Assert exact weapon IDs, counts, ranges, damage, pierce, knockback, cooldown behavior, element multiplier, attack-speed multiplier, critical rolls, and size multiplier. Use seeded `Random(1)` for critical assertions.

- [ ] **Step 2: Run and verify RED**

Run: `flutter test test/game/weapon_system_test.dart`

Expected: FAIL because new weapons never fire and `frostFields` is missing.

- [ ] **Step 3: Implement the four firing methods**

Add `_fireWard`, `_fireSingijeon`, `_fireFrostFlask`, and `_fireWindThunderFan`. Use `_consumeCooldown`, `_elementDamageMultiplier`, `_rolledDamage`, and existing `_damageEvent` helpers. Add a deterministic `_densestDirection` helper that bins enemy angles into eight sectors and breaks ties by nearest distance.

Ward emits immediate `DamageEvent`s. Singijeon emits `ProjectileComponent`s spread evenly across `0.9` radians. Frost emits one `FrostFieldComponent` at the densest living enemy position. Wind-thunder emits one `MeleeArcComponent` and, at level 5, one opposite arc.

- [ ] **Step 4: Run focused tests, refactor repeated fire accounting, and verify GREEN**

Run: `flutter test test/game/weapon_system_test.dart`

Expected: PASS with all eight weapons represented in `firedWeaponIds`.

- [ ] **Step 5: Commit**

```powershell
git add lib/game/systems/weapon_system.dart test/game/weapon_system_test.dart
git commit -m "feat: fire four new weapon archetypes"
```

### Task 4: Integrate persistent visuals, frost damage, slow, and audio

**Files:**
- Create: `lib/game/components/ward_attack_component.dart`
- Modify: `lib/game/components/melee_arc_component.dart`
- Modify: `lib/game/content/weapon_effect_atlas.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `test/game/pixel_survivor_game_loop_test.dart`
- Modify: `test/game/weapon_effect_atlas_test.dart`

**Interfaces:**
- Produces: one `WardAttackComponent` that follows `Vector2 Function()` and renders the current ward radius.
- Consumes: `WeaponTickResult.frostFields`.
- Reuses: bow audio for singijeon, talisman audio for ward/frost, bomb audio for wind-thunder until final sound assets arrive.

- [ ] **Step 1: Write failing game-loop integration tests**

```dart
gameTester.testGameWidget(
  'game keeps one ward visual and records ward damage',
  setUp: (game, _) async {
    game.unlockedWeaponIds.add(jangseungWard);
    game.weaponSystem.upgrade(jangseungWard, game.unlockedWeaponIds);
    await game.ensureAdd(EnemyComponent(
      enemyId: 'ward_target', maxHealth: 100, moveSpeed: 0, damage: 0,
      position: game.activePlayers.single.position + Vector2(20, 0),
    ));
  },
  verify: (game, _) {
    game.update(1);
    expect(game.children.whereType<WardAttackComponent>(), hasLength(1));
    expect(game.currentRunResult().weaponDamageTotals[jangseungWard], greaterThan(0));
  },
);

test('strongest frost field wins and no field restores speed', () {
  final enemy = EnemyComponent(
    enemyId: 'slow_target', maxHealth: 100, moveSpeed: 100, damage: 0,
    position: Vector2.zero(),
  );
  enemy.setEnvironmentalSlow(.45);
  expect(enemy.effectiveMoveSpeed, 55);
  enemy.setEnvironmentalSlow(0);
  expect(enemy.effectiveMoveSpeed, 100);
});

gameTester.testGameWidget(
  'new weapon components retain their weapon ids',
  setUp: (game, _) async {
    game.unlockedWeaponIds.addAll({singijeonVolley, frostFlask, windThunderFan});
    for (final id in [singijeonVolley, frostFlask, windThunderFan]) {
      game.weaponSystem.upgrade(id, game.unlockedWeaponIds);
    }
    await game.ensureAdd(EnemyComponent(
      enemyId: 'component_target', maxHealth: 1000, moveSpeed: 0, damage: 0,
      position: game.activePlayers.single.position + Vector2(30, 0),
    ));
  },
  verify: (game, _) {
    game.update(3);
    expect(game.children.whereType<ProjectileComponent>()
        .where((item) => item.weaponId == singijeonVolley), isNotEmpty);
    expect(game.children.whereType<FrostFieldComponent>()
        .where((item) => item.weaponId == frostFlask), hasLength(1));
    expect(game.children.whereType<MeleeArcComponent>()
        .where((item) => item.weaponId == windThunderFan), isNotEmpty);
  },
);
```

- [ ] **Step 2: Run and verify RED**

Run: `flutter test test/game/pixel_survivor_game_loop_test.dart test/game/weapon_effect_atlas_test.dart`

Expected: FAIL because game integration and new fallback contracts are absent.

- [ ] **Step 3: Implement integration**

In the weapon tick boundary, add returned frost fields while removing the oldest field before adding a fourth. Ensure or remove one `WardAttackComponent` based on ward level. Each frame, calculate every living enemy's strongest containing frost field and call `setEnvironmentalSlow`; collect frost damage through `_applyDamageEvents`.

Change melee rendering to call `WeaponEffectAtlas.rowForWeapon(weaponId)` and use code fallback when it returns null, preventing new fan arcs from incorrectly drawing the hwando row.

- [ ] **Step 4: Run focused tests and verify GREEN**

Run: `flutter test test/game/pixel_survivor_game_loop_test.dart test/game/weapon_effect_atlas_test.dart`

Expected: PASS, including telemetry weapon IDs and speed restoration.

- [ ] **Step 5: Commit**

```powershell
git add lib/game/components lib/game/content/weapon_effect_atlas.dart lib/game/pixel_survivor_game.dart test/game
git commit -m "feat: integrate new weapons into live combat"
```

### Task 5: Complete balance coverage and regression gates

**Files:**
- Modify: `lib/game/balance/weapon_balance_baseline.dart`
- Modify: `test/game/weapon_balance_baseline_test.dart`
- Modify: `test/game/multi_seed_run_regression_test.dart`
- Modify: `test/game/level_up_system_test.dart`

**Interfaces:**
- Produces: `WeaponBaselineSimulator.simulate()` with 40 rows and no unsupported IDs.
- Preserves: fixed-seed five-minute horde constraints and level-up limits.

- [ ] **Step 1: Write failing baseline and selection tests**

```dart
test('baseline supports all eight weapons and forty levels', () {
  final report = const WeaponBaselineSimulator().simulate();
  expect(report.supportedWeaponIds, weaponDefinitions.map((w) => w.id).toSet());
  expect(report.rows, hasLength(40));
  expect(report.unsupportedWeaponIds, isEmpty);
});

test('each unlocked new weapon can appear as a level-up choice', () {
  final choices = LevelUpSystem(random: Random(1)).choices(
    unlockedWeaponIds: {jangseungWard, singijeonVolley, frostFlask, windThunderFan},
    unlockedAugmentIds: const {},
    currentWeaponLevels: const {},
    currentAugmentLevels: const {},
    maxChoices: 8,
  );
  expect(choices.map((choice) => choice.id).toSet(), {
    jangseungWard, singijeonVolley, frostFlask, windThunderFan,
  });
});
```

- [ ] **Step 2: Run and verify RED**

Run: `flutter test test/game/weapon_balance_baseline_test.dart test/game/level_up_system_test.dart`

Expected: FAIL because the simulator supports only four runtime IDs.

- [ ] **Step 3: Add hit models for the new archetypes**

Ward uses `crowdTargetsPerArea`; singijeon uses `projectileCount * (pierce + 1)`; frost uses `crowdTargetsPerArea * floor(durationSeconds / .5)`; wind-thunder uses `projectileCount * 2` representative cone targets. Keep these assumptions documented in test reasons.

- [ ] **Step 4: Run focused and fixed-seed regression tests**

Run: `flutter test test/game/weapon_balance_baseline_test.dart test/game/level_up_system_test.dart test/game/multi_seed_run_regression_test.dart test/game/five_minute_run_simulation_test.dart`

Expected: PASS with no invalid pools, frame spawn cap violations, or unsupported weapons.

- [ ] **Step 5: Commit**

```powershell
git add lib/game/balance test/game/weapon_balance_baseline_test.dart test/game/level_up_system_test.dart test/game/multi_seed_run_regression_test.dart
git commit -m "test: cover complete weapon roster balance"
```

### Task 6: Record milestone, verify, playtest, and merge

**Files:**
- Modify: `docs/master-development-todo.md`

**Interfaces:**
- Produces: CNT-003 and CNT-004 completion evidence and points the next queue to CNT-005.

- [ ] **Step 1: Update the milestone document**

Record exact weapon roles, 40 level rows, frost slow/cap behavior, final test count, analysis result, web build, Android APK build, and browser smoke result.

- [ ] **Step 2: Run formatting, focused status checks, and full release verification**

Run: `./tool/release_check.ps1 -IncludeAndroid`

Expected: exit code 0, no analysis issues, all tests pass, web build succeeds, and `build/app/outputs/flutter-apk/app-debug.apk` exists.

- [ ] **Step 3: Browser smoke test the exact release web build**

Serve `build/web`, open character → stage → battle, verify at least one new weapon can be selected in a controlled unlocked-save test flow, verify its visual effect and weapon label, and verify no relevant console errors on menu/selection screens.

- [ ] **Step 4: Commit documentation and merge using the user's standing policy**

```powershell
git add docs/master-development-todo.md
git commit -m "docs: record eight-weapon milestone"
git switch master
git merge --ff-only eight-weapon-roster
```

- [ ] **Step 5: Verify the merged hash and clean temporary D: resources**

Run the full release check on the fast-forwarded `master` if build artifacts were created only in the worktree, retain the master web server for user play, remove only the verified D: feature worktree/cache paths created for this task, and confirm `git status --short` is empty.
