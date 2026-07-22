# Complete Base Roster Quality Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Open and finish the complete base roster—3 characters, 12 level-1-to-6 weapons, 13 production enemies, and 2 stages—with consistent high-resolution Joseon folk-fantasy presentation and a six-weapon run cap.

**Architecture:** `BaseContentPolicy` is the single source for permanent base access and is unioned into both new and migrated saves. Art is governed by exact 512×512 RGBA atlas contracts and stage-specific backdrop definitions; runtime rendering consumes those contracts without production rectangle/static fallbacks. Weapon definitions own six-level data, while `WeaponSystem` owns deterministic attack execution and `LevelUpSystem` enforces the six-slot acquisition rule.

**Tech Stack:** Dart 3.12, Flutter, Flame 1.18, flutter_test, flame_test, PNG RGBA assets, existing telemetry/performance harnesses.

## Global Constraints

- Preserve every existing content ID, wallet value, training/shop progress, record, completed goal, and claimed reward.
- Base characters are exactly 3, base weapons exactly 12, and base stages exactly 2; all are available in new and existing saves.
- Every weapon has levels 1 through 6; level 6 is a behavior-changing master, including Gakgung master `관월추성`.
- A run may own at most 6 weapons, including the character starting weapon.
- Every playable character and production enemy uses a 4×4 atlas of 128×128 RGBA frames (512×512 total).
- New art remains `ArtAssetStatus.temporary` until an external-phone playtest approves it.
- No production enemy may render as a rectangle and no playable character may use the old static swordswoman sprite.
- Maintain late-run average enemy count 30–55, global enemy cap 96, and damage-number cap 24.
- Do not add payments, gacha, new meta systems, more than 12 base weapons, more than 3 characters, or more than 2 stages.

---

### Task 1: Permanent Base Content Policy and Save Migration

**Files:**
- Create: `lib/game/content/base_content_policy.dart`
- Modify: `lib/game/systems/save_system.dart`
- Modify: `lib/game/content/playtest_content_policy.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Test: `test/game/base_content_policy_test.dart`
- Test: `test/game/save_migration_regression_test.dart`
- Test: `test/game/pixel_survivor_game_loop_test.dart`

**Interfaces:**
- Produces: `BaseContentPolicy.characterIds`, `weaponIds`, `stageIds`, and `union*` methods returning known-ID sets.
- Consumes: existing definition lists and unchanged string IDs.

- [ ] **Step 1: Write failing base-access tests**

```dart
test('base policy exposes the complete base roster', () {
  expect(BaseContentPolicy.characterIds, hasLength(3));
  expect(BaseContentPolicy.weaponIds, hasLength(12));
  expect(BaseContentPolicy.stageIds, hasLength(2));
});

test('old save gains base access without losing progress', () {
  final migrated = SaveState.fromJson(oldSaveJson);
  expect(migrated.unlockedCharacterIds, containsAll(BaseContentPolicy.characterIds));
  expect(migrated.unlockedWeaponIds, containsAll(BaseContentPolicy.weaponIds));
  expect(migrated.unlockedStageIds, containsAll(BaseContentPolicy.stageIds));
  expect(migrated.wallet.coin, oldCoin);
  expect(migrated.wallet.spiritJade, oldSpiritJade);
  expect(migrated.completedGoalIds, contains(oldCompletedGoal));
});
```

- [ ] **Step 2: Run tests and verify they fail**

Run: `F:\bin\flutter.bat test test/game/base_content_policy_test.dart test/game/save_migration_regression_test.dart`

Expected: FAIL because `BaseContentPolicy` does not exist and defaults expose only the original starter subset.

- [ ] **Step 3: Add the single source of truth**

```dart
abstract final class BaseContentPolicy {
  static Set<CharacterId> get characterIds =>
      characterDefinitions.map((item) => item.id).toSet();
  static Set<WeaponId> get weaponIds =>
      weaponDefinitions.map((item) => item.id).toSet();
  static Set<String> get stageIds =>
      stageDefinitions.map((item) => item.id).toSet();

  static Set<T> union<T>(Iterable<T> saved, Iterable<T> base) =>
      Set<T>.unmodifiable({...saved, ...base});
}
```

Use these sets in `SaveState.defaults()` and union them after `_knownStringSet` in `_fromSupportedJson`. Set `unlockedWeaponCount` to at least `BaseContentPolicy.weaponIds.length`; do not alter other counters.

- [ ] **Step 4: Remove release-only weapon access behavior**

Make `PixelSurvivorGame._addStartingRunUnlocks()` always add `BaseContentPolicy.weaponIds`. Retain `PlaytestContentPolicy` only as a backward-compatible no-op adapter so existing callers/tests compile.

- [ ] **Step 5: Run focused tests**

Run: `F:\bin\flutter.bat test test/game/base_content_policy_test.dart test/game/save_migration_regression_test.dart test/game/pixel_survivor_game_loop_test.dart`

Expected: PASS; both fresh and migrated saves expose all base IDs.

- [ ] **Step 6: Commit**

```powershell
git add lib/game/content/base_content_policy.dart lib/game/systems/save_system.dart lib/game/content/playtest_content_policy.dart lib/game/pixel_survivor_game.dart test/game/base_content_policy_test.dart test/game/save_migration_regression_test.dart test/game/pixel_survivor_game_loop_test.dart
git commit -m "feat: open complete base roster"
```

### Task 2: Twelve-Weapon Definition Contract and Gakgung Level 6

**Files:**
- Modify: `lib/game/content/weapon_definitions.dart`
- Modify: `lib/game/content/weapon_level_definitions.dart`
- Modify: `lib/game/balance/weapon_balance_baseline.dart`
- Modify: `tool/weapon_balance_report.dart`
- Test: `test/game/content_definitions_test.dart`
- Test: `test/game/weapon_balance_baseline_test.dart`
- Test: `test/game/content_integrity_test.dart`

**Interfaces:**
- Produces: weapon IDs `matchlockCannon`, `shamanBells`, `dokkaebiChain`, `hawkSummon`; six `WeaponLevelDefinition` entries for every weapon.
- Produces: `WeaponLevelDefinition.masterName` for explicit mastery UI and telemetry.

- [ ] **Step 1: Write failing roster/master tests**

```dart
test('all twelve weapons own six levels and a named master', () {
  expect(weaponDefinitions, hasLength(12));
  for (final weapon in weaponDefinitions) {
    expect(weapon.maxLevel, 6, reason: weapon.id);
    expect(weaponLevels[weapon.id], hasLength(6), reason: weapon.id);
    expect(weaponLevels[weapon.id]!.last.isMaster, isTrue);
    expect(weaponLevels[weapon.id]!.last.masterName, isNotEmpty);
  }
  expect(weaponLevels[gakgungShot]!.last.masterName, '관월추성');
});
```

- [ ] **Step 2: Run tests and verify the 5-level definitions fail**

Run: `F:\bin\flutter.bat test test/game/content_definitions_test.dart test/game/weapon_balance_baseline_test.dart`

Expected: FAIL for roster length, max levels, and missing `masterName`.

- [ ] **Step 3: Add four stable weapon IDs and six-level metadata**

```dart
const matchlockCannon = 'matchlock_cannon';
const shamanBells = 'shaman_bells';
const dokkaebiChain = 'dokkaebi_chain';
const hawkSummon = 'hawk_summon';
```

Set every `WeaponDefinition(maxLevel: 6, startsUnlocked: true)`. Add `masterName` with default `''` to `WeaponLevelDefinition`. Append behavior-changing level 6 entries to the seven existing 5-level weapons and define complete 1–6 arrays for the four new weapons.

- [ ] **Step 4: Define Gakgung mastery exactly**

```dart
WeaponLevelDefinition(
  damage: 26,
  cooldownSeconds: 0.95,
  range: 560,
  projectileCount: 3,
  pierce: 4,
  chainCount: 2,
  knockback: 24,
  displayEffect: '관월추성 · 관통 대시위 1발 + 추격 화살 2발',
  behaviorDescription: '가장 강한 적을 관통한 뒤 두 발의 추격 화살이 이어집니다.',
  isMaster: true,
  masterName: '관월추성',
),
```

Do not add explosion radius or area damage to Gakgung.

- [ ] **Step 5: Update balance/report contracts and run tests**

Run: `F:\bin\flutter.bat test test/game/content_definitions_test.dart test/game/weapon_balance_baseline_test.dart test/game/content_integrity_test.dart`

Expected: PASS with 12 weapons and 72 total level records.

- [ ] **Step 6: Commit**

```powershell
git add lib/game/content/weapon_definitions.dart lib/game/content/weapon_level_definitions.dart lib/game/balance/weapon_balance_baseline.dart tool/weapon_balance_report.dart test/game/content_definitions_test.dart test/game/weapon_balance_baseline_test.dart test/game/content_integrity_test.dart
git commit -m "feat: define twelve six-level weapons"
```

### Task 3: Six-Weapon Run Slot and Offer Weighting

**Files:**
- Modify: `lib/game/systems/level_up_system.dart`
- Modify: `lib/game/systems/weapon_system.dart`
- Test: `test/game/level_up_system_test.dart`
- Test: `test/game/weapon_system_test.dart`
- Test: `test/game/content_build_viability_test.dart`

**Interfaces:**
- Produces: `LevelUpSystem.maxOwnedWeapons = 6` and `WeaponSystem.ownedWeaponCount`.
- Consumes: `currentWeaponLevels`, where level `> 0` means owned.

- [ ] **Step 1: Write failing slot tests**

```dart
test('six owned weapons suppress new weapon offers', () {
  final levels = {for (final id in BaseContentPolicy.weaponIds.take(6)) id: 1};
  final choices = system.choices(
    unlockedWeaponIds: BaseContentPolicy.weaponIds,
    unlockedAugmentIds: unlockedAugments,
    currentWeaponLevels: levels,
    currentAugmentLevels: const {},
  );
  expect(
    choices.where((c) => c.type == LevelUpChoiceType.weapon),
    everyElement(predicate<LevelUpChoice>((c) => levels.containsKey(c.id))),
  );
});

test('an owned upgrade is present when one can level', () {
  expect(choices.any((c) => c.type == LevelUpChoiceType.weapon && levels.containsKey(c.id)), isTrue);
});
```

- [ ] **Step 2: Run tests and verify new weapons are still offered after six slots**

Run: `F:\bin\flutter.bat test test/game/level_up_system_test.dart test/game/content_build_viability_test.dart`

Expected: FAIL on slot filtering and owned-upgrade guarantee.

- [ ] **Step 3: Implement acquisition filtering before shuffle**

```dart
static const maxOwnedWeapons = 6;
final ownedIds = currentWeaponLevels.entries
    .where((entry) => entry.value > 0)
    .map((entry) => entry.key)
    .toSet();
final slotsFull = ownedIds.length >= maxOwnedWeapons;
// Skip definition when slotsFull && !ownedIds.contains(definition.id).
```

Reserve one weapon choice from upgradeable `ownedIds` before filling the remaining randomized choices. Preserve the existing weapon/augment mix when no owned upgrade exists.

- [ ] **Step 4: Guard direct upgrades**

Change `WeaponSystem.canUpgrade` so an unowned weapon returns false when `ownedWeaponCount >= 6`, while owned weapons may still reach level 6.

- [ ] **Step 5: Run focused tests and commit**

Run: `F:\bin\flutter.bat test test/game/level_up_system_test.dart test/game/weapon_system_test.dart test/game/content_build_viability_test.dart`

Expected: PASS with no seventh weapon path.

```powershell
git add lib/game/systems/level_up_system.dart lib/game/systems/weapon_system.dart test/game/level_up_system_test.dart test/game/weapon_system_test.dart test/game/content_build_viability_test.dart
git commit -m "feat: cap runs at six weapons"
```

### Task 4: Gakgung `관월추성` Runtime and Master Feedback

**Files:**
- Create: `lib/game/systems/gakgung_executor.dart`
- Modify: `lib/game/systems/weapon_system.dart`
- Modify: `lib/game/components/projectile_component.dart`
- Modify: `lib/game/content/combat_effect_atlas.dart`
- Modify: `lib/game/audio/audio_cue.dart`
- Modify: `lib/game/audio/audio_asset_catalog.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Test: `test/game/gakgung_executor_test.dart`
- Test: `test/game/weapon_system_test.dart`
- Test: `test/game/game_audio_service_test.dart`
- Test: `test/game/combat_feedback_controller_test.dart`

**Interfaces:**
- Produces: `GakgungExecutor.plan(GakgungInput) -> GakgungVolley`, where `GakgungVolley.shots` contains `GakgungShot(direction, targetEnemyId, followUpIndex, damageMultiplier, visualScale)`.
- Produces: `ProjectileComponent.followUpIndex`, `isMasterLead`, and `AudioCue.gakgungMaster`.
- Consumes: `WeaponLevelDefinition.chainCount == 2` at Gakgung level 6.

- [ ] **Step 1: Write failing mastery behavior tests**

```dart
test('관월추성 targets strongest enemy and emits two follow-ups', () {
  final volley = executor.plan(GakgungInput(
    level: 6,
    origin: Vector2.zero(),
    enemies: [weak, strongest, medium],
    stats: weaponLevelFor(gakgungShot, 6),
  ));
  expect(volley.shots, hasLength(3));
  expect(volley.shots.first.targetEnemyId, strongest.enemyId);
  expect(volley.shots.first.followUpIndex, 0);
  expect(volley.shots.skip(1).map((a) => a.followUpIndex), [1, 2]);
});

test('weapon system emits no gakgung area attack at mastery', () {
  final result = tickAtLevel(gakgungShot, 6, enemies: [strongest]);
  expect(result.projectiles.where((p) => p.weaponId == gakgungShot), hasLength(3));
  expect(result.areaAttacks.where((a) => a.weaponId == gakgungShot), isEmpty);
});
```

- [ ] **Step 2: Run and verify the level-6 path fails**

Run: `F:\bin\flutter.bat test test/game/gakgung_executor_test.dart test/game/weapon_system_test.dart --plain-name "관월추성"`

Expected: FAIL because Gakgung currently fires only the level-5 multi-arrow pattern.

- [ ] **Step 3: Implement strongest-target and follow-up sequencing**

At level 6, sort live in-range targets by `currentHealth` descending, return one enlarged lead-arrow plan and two visually offset follow-up plans. `WeaponSystem` converts each plan into a `ProjectileComponent`; keep all three as projectiles and create no `AreaAttackComponent`.

- [ ] **Step 4: Add distinct feedback**

Map Gakgung level 6 to a moon-gold/indigo trail, one restrained camera kick on the lead arrow, a stronger master sound, and the existing master name banner rate limit. Derive trail direction and hit timing from each projectile attack record.

- [ ] **Step 5: Test and commit**

Run: `F:\bin\flutter.bat test test/game/gakgung_executor_test.dart test/game/weapon_system_test.dart test/game/game_audio_service_test.dart test/game/combat_feedback_controller_test.dart`

Expected: PASS; tests prove three projectile hits, zero explosions, and one master cue.

```powershell
git add lib/game/systems/gakgung_executor.dart lib/game/systems/weapon_system.dart lib/game/components/projectile_component.dart lib/game/content/combat_effect_atlas.dart lib/game/audio/audio_cue.dart lib/game/audio/audio_asset_catalog.dart lib/game/pixel_survivor_game.dart test/game/gakgung_executor_test.dart test/game/weapon_system_test.dart test/game/game_audio_service_test.dart test/game/combat_feedback_controller_test.dart
git commit -m "feat: add gakgung moon-chasing mastery"
```

### Task 5: Existing Weapon Masters 4–8

**Files:**
- Modify: `lib/game/systems/weapon_system.dart`
- Modify: `lib/game/components/ward_aura_component.dart`
- Modify: `lib/game/components/projectile_component.dart`
- Modify: `lib/game/components/frost_field_component.dart`
- Modify: `lib/game/components/attack_effect_component.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Test: `test/game/weapon_system_test.dart`
- Test: `test/game/game_performance_budget_test.dart`

**Interfaces:**
- Consumes: level-6 records from Task 2.
- Produces: deterministic master component collections on `WeaponTickResult`: `areaAttacks`, `wardAuras`, `projectiles`, `frostFields`, and `meleeArcs` for bomb, ward, Singijeon, frost flask, and fan.
- Produces: optional `ProjectileComponent.laneIndex` (default `0`) and `WeaponTickResult.wardAuras` (default empty) so existing callers remain source-compatible.

- [ ] **Step 1: Add one failing shape test per master**

```dart
expect(masterBomb.areaAttacks.length, greaterThan(level5Bomb.areaAttacks.length));
expect(masterWard.wardAuras, hasLength(4));
expect(masterSingijeon.projectiles.map((p) => p.laneIndex).toSet(), hasLength(3));
expect(masterFrost.frostFields, hasLength(3));
expect(masterFan.meleeArcs.map((a) => a.direction.angleToSigned(Vector2(1, 0))).toSet(), hasLength(6));
```

- [ ] **Step 2: Run tests and verify each old executor lacks level-6 behavior**

Run: `F:\bin\flutter.bat test test/game/weapon_system_test.dart`

Expected: FAIL for all five new master expectations.

- [ ] **Step 3: Implement distinct master rules**

Implement: bomb center plus four chained satellite blasts; four moving Jangseung guards; three full-screen Singijeon lanes; one main frost lake plus two propagating child fields; six rotating alternating fan arcs. Use existing population budgets and aggregate overlapping damage numbers.

- [ ] **Step 4: Verify bounded presentation and commit**

Run: `F:\bin\flutter.bat test test/game/weapon_system_test.dart test/game/game_performance_budget_test.dart`

Expected: PASS with projectile/enemy/effect caps unchanged.

```powershell
git add lib/game/systems/weapon_system.dart lib/game/components/ward_aura_component.dart lib/game/components/projectile_component.dart lib/game/components/frost_field_component.dart lib/game/components/attack_effect_component.dart lib/game/pixel_survivor_game.dart test/game/weapon_system_test.dart test/game/game_performance_budget_test.dart
git commit -m "feat: evolve existing weapons at level six"
```

### Task 6: Four New Weapon Executors

**Files:**
- Create: `lib/game/systems/special_weapon_executor.dart`
- Create: `lib/game/components/hawk_dive_component.dart`
- Create: `lib/game/components/chain_sweep_component.dart`
- Modify: `lib/game/systems/weapon_system.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `lib/game/audio/audio_cue.dart`
- Modify: `lib/game/audio/audio_asset_catalog.dart`
- Test: `test/game/special_weapon_executor_test.dart`
- Test: `test/game/weapon_system_test.dart`
- Test: `test/game/game_performance_budget_test.dart`

**Interfaces:**
- Produces: `SpecialWeaponExecutor.execute(SpecialWeaponContext) -> SpecialWeaponResult`.
- `SpecialWeaponResult` contains `List<ProjectileComponent> projectiles`, `List<AreaAttackComponent> areaAttacks`, `List<MeleeArcComponent> meleeArcs`, `List<DamageEvent> damageEvents`, `List<double> pulseRadii`, `List<WeaponDiveLine> diveLines`, and `double pullStrength`.
- `WeaponDiveLine` is an immutable value with `Vector2 start`, `Vector2 end`, and `bool intersectsPoint(Vector2 point, {double tolerance = 32})`.
- Produces component collections consumed by the existing `WeaponTickResult` application path.

- [ ] **Step 1: Write failing identity tests**

```dart
expect(matchlock.projectiles.single.pierce, greaterThan(0));
expect(matchlock.areaAttacks, isNotEmpty);
expect(bells.pulseRadii, orderedEquals([48, 82, 118]));
expect(chain.pullStrength, greaterThan(0));
expect(hawk.diveLines.first.intersectsPoint(densestCluster), isTrue);
```

- [ ] **Step 2: Run and verify missing executor failures**

Run: `F:\bin\flutter.bat test test/game/special_weapon_executor_test.dart`

Expected: FAIL because `SpecialWeaponExecutor` is absent.

- [ ] **Step 3: Implement level-scaled executors**

Matchlock fires one piercing line and explodes only after the last hit; bells emit orbiting pulses; chain sweeps rotate and pull non-boss enemies; hawk chooses the densest 120px cluster and crosses it. At level 6 use the exact master patterns from the design spec. Bosses receive damage but ignore chain displacement.

- [ ] **Step 4: Wire audio/effects and game application**

Add unique cue mappings and distinct palettes: matchlock orange/charcoal, bells magenta/gold, chain cyan/violet, hawk ivory/teal. All visual positions/radii derive from the result attack records.

- [ ] **Step 5: Test and commit**

Run: `F:\bin\flutter.bat test test/game/special_weapon_executor_test.dart test/game/weapon_system_test.dart test/game/game_performance_budget_test.dart`

Expected: PASS for all levels and population limits.

```powershell
git add lib/game/systems/special_weapon_executor.dart lib/game/components/hawk_dive_component.dart lib/game/components/chain_sweep_component.dart lib/game/systems/weapon_system.dart lib/game/pixel_survivor_game.dart lib/game/audio/audio_cue.dart lib/game/audio/audio_asset_catalog.dart test/game/special_weapon_executor_test.dart test/game/weapon_system_test.dart test/game/game_performance_budget_test.dart
git commit -m "feat: add four distinct folk weapons"
```

### Task 7: Complete Character Atlas Set and Mobile Filtering

**Files:**
- Create: `assets/images/player/rookie_constable_128.png`
- Keep/verify: `assets/images/player/exorcist_dosa_128.png`
- Create: `assets/images/player/mountain_hunter_128.png`
- Modify: `lib/game/content/sprite_atlas_contract.dart`
- Modify: `lib/game/content/asset_catalog.dart`
- Modify: `lib/game/content/actor_visual_spec.dart`
- Modify: `lib/game/components/player_component.dart`
- Test: `test/game/sprite_atlas_contract_test.dart`
- Test: `test/game/actor_visual_spec_test.dart`
- Test: `test/game/player_component_test.dart`

**Interfaces:**
- Produces: one `SpriteAtlasContract` per character, keyed by character ID.
- Consumes: row contract move 0–3, attack 4–7, hit 8–9, death 10–15.

- [ ] **Step 1: Write failing exact-asset tests**

```dart
for (final id in BaseContentPolicy.characterIds) {
  final contract = ReplaceableArtCatalog.playerByCharacterId(id);
  expect(contract.pixelWidth, 512);
  expect(contract.pixelHeight, 512);
  expect(contract.validatePngHeader(File(contract.runtimePath).readAsBytesSync()), isEmpty);
}
expect(playerVisualSpecFor(rookieConstable).visualSize, 64);
expect(playerVisualSpecFor(mountainHunter).visualSize, 64);
```

- [ ] **Step 2: Generate/edit the two missing atlases with the `imagegen` skill**

Use the approved art guide: cute three-head proportion, large readable face/hands/weapon, thick clean outline, 2–3 cel-shading values, Joseon clothing, transparent background, no copied commercial character. Keep all 16 cells centered and separated.

- [ ] **Step 3: Register atlases and remove static-player runtime mapping**

Map all three character IDs to the 128px contracts. Keep old files in the repository for save/asset history, but no production selection/runtime path may return them.

- [ ] **Step 4: Change player downscale filter and verify frames**

Set `paint.filterQuality = FilterQuality.medium`; use one stable frame when velocity is zero and the defined animation rows for movement/attack/hit/death.

- [ ] **Step 5: Run tests and commit**

Run: `F:\bin\flutter.bat test test/game/sprite_atlas_contract_test.dart test/game/actor_visual_spec_test.dart test/game/player_component_test.dart`

Expected: PASS and every player contract validates as 512×512 RGBA.

```powershell
git add assets/images/player lib/game/content/sprite_atlas_contract.dart lib/game/content/asset_catalog.dart lib/game/content/actor_visual_spec.dart lib/game/components/player_component.dart test/game/sprite_atlas_contract_test.dart test/game/actor_visual_spec_test.dart test/game/player_component_test.dart
git commit -m "feat: unify playable character art"
```

### Task 8: Complete Thirteen-Enemy Atlas Set and Eliminate Rectangle Fallbacks

**Files:**
- Create/replace: `assets/images/monsters/*_128.png` for all 13 production enemy IDs
- Modify: `lib/game/content/sprite_atlas_contract.dart`
- Modify: `lib/game/content/asset_catalog.dart`
- Modify: `lib/game/content/actor_visual_spec.dart`
- Modify: `lib/game/components/enemy_component.dart`
- Modify: `lib/game/content/content_integrity.dart`
- Test: `test/game/content_integrity_test.dart`
- Test: `test/game/enemy_component_test.dart`
- Test: `test/game/sprite_atlas_contract_test.dart`

**Interfaces:**
- Produces: `ReplaceableArtCatalog.enemyByEnemyId(EnemyId)` for every ID in `enemyDefinitions`.
- Consumes: unchanged enemy behavior, collision, health, and IDs.

- [ ] **Step 1: Write failing coverage/no-fallback tests**

```dart
for (final id in enemyDefinitions.map((item) => item.id)) {
  final contract = ReplaceableArtCatalog.enemyByEnemyId(id);
  expect(contract.validatePngHeader(File(contract.runtimePath).readAsBytesSync()), isEmpty, reason: id);
}
expect(() => EnemyComponent.fromDefinition(definitionWithoutAtlas), throwsStateError);
```

- [ ] **Step 2: Generate/edit all missing atlases with the `imagegen` skill**

Create the nine missing atlases and quality-check the four existing ones. Preserve silhouette roles: swarm low/wide, dash forward-leaning, ranged long arms/projectile prop, tank broad front shield. Use transparent 4×4 grids and the fixed row contract.

- [ ] **Step 3: Register exact mappings and sizes**

Assign 36–48px normal, 56–64px elite, and 88px boss visual sizes without changing collisions. Set `FilterQuality.medium`.

- [ ] **Step 4: Remove production rectangle rendering**

Make missing production visuals fail during content validation/load instead of drawing colored rectangles. Allow a tiny diagnostic placeholder only in explicit test fixtures with an opt-in constructor flag defaulting to false.

- [ ] **Step 5: Test and commit**

Run: `F:\bin\flutter.bat test test/game/content_integrity_test.dart test/game/enemy_component_test.dart test/game/sprite_atlas_contract_test.dart`

Expected: PASS; all 13 atlases validate and no production path enables rectangles.

```powershell
git add assets/images/monsters lib/game/content/sprite_atlas_contract.dart lib/game/content/asset_catalog.dart lib/game/content/actor_visual_spec.dart lib/game/components/enemy_component.dart lib/game/content/content_integrity.dart test/game/content_integrity_test.dart test/game/enemy_component_test.dart test/game/sprite_atlas_contract_test.dart
git commit -m "feat: unify production enemy art"
```

### Task 9: Two Distinct High-Resolution Stage Backdrops

**Files:**
- Create: `assets/images/stages/moonlit_abandoned_office_1024.png`
- Create: `assets/images/stages/plague_market_1024.png`
- Modify: `lib/game/content/stage_definitions.dart`
- Modify: `lib/game/components/stage_backdrop_component.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Test: `test/game/stage_backdrop_component_test.dart`
- Test: `test/app/stage_select_screen_test.dart`

**Interfaces:**
- Produces: `StageDefinition.backdropAssetPath` and `StageBackdropComponent(stageId:, viewportSize:)`.

- [ ] **Step 1: Write failing stage-identity tests**

```dart
expect(stageDefinitionFor(moonlitAbandonedOffice).backdropAssetPath,
    isNot(stageDefinitionFor(plagueMarket).backdropAssetPath));
expect(await decodeSize(officePath), const Size(1024, 1024));
expect(await decodeSize(marketPath), const Size(1024, 1024));
```

- [ ] **Step 2: Generate the two backgrounds with the `imagegen` skill**

Use the exact motifs and low-contrast central 45% safe area from the design spec. No characters, UI, text, or copied game assets.

- [ ] **Step 3: Wire stage-specific tiled rendering**

Pass `selectedStageId` into `StageBackdropComponent`; tile the proper image behind existing lightweight decoration and keep collision-free rendering.

- [ ] **Step 4: Test and commit**

Run: `F:\bin\flutter.bat test test/game/stage_backdrop_component_test.dart test/app/stage_select_screen_test.dart`

Expected: PASS with distinct assets and unchanged stage IDs.

```powershell
git add assets/images/stages lib/game/content/stage_definitions.dart lib/game/components/stage_backdrop_component.dart lib/game/pixel_survivor_game.dart test/game/stage_backdrop_component_test.dart test/app/stage_select_screen_test.dart
git commit -m "feat: distinguish the two base stages"
```

### Task 10: Selection UI, Weapon Icons, and Legacy Goal Copy

**Files:**
- Modify: `lib/app/character_select_screen.dart`
- Modify: `lib/app/stage_select_screen.dart`
- Modify: `lib/app/level_up_overlay.dart`
- Modify: `lib/app/compendium_screen.dart`
- Modify: `lib/game/content/unlock_definitions.dart`
- Create: `assets/images/weapons/base_weapon_icons_64.png`
- Test: `test/app/character_select_screen_test.dart`
- Test: `test/app/stage_select_screen_test.dart`
- Test: `test/app/level_up_overlay_test.dart`
- Test: `test/game/unlock_definitions_test.dart`

**Interfaces:**
- Produces: `기본 제공` access label and 12 weapon icon cells.
- Consumes: legacy goal IDs unchanged, `masterName` from Task 2.

- [ ] **Step 1: Write failing access/master UI tests**

```dart
expect(find.text('기본 제공'), findsNWidgets(3));
expect(find.byIcon(Icons.lock), findsNothing);
expect(find.textContaining('6레벨 · 관월추성'), findsOneWidget);
```

- [ ] **Step 2: Create a distinct 12-icon atlas with the `imagegen` skill**

Each 64px cell must use the weapon palette and a single large silhouette; no text and no borrowed UI frame.

- [ ] **Step 3: Remove base lock presentation without deleting goals**

Render all base entries selectable and label them `기본 제공`. Keep goal IDs/completion/reward history, but describe their old base reward as a legacy achievement rather than a current access gate.

- [ ] **Step 4: Surface level 6 clearly**

Level-up cards show `마스터`, mastery name, behavior sentence, and the unique icon. HUD level badges accept 6 without clipping.

- [ ] **Step 5: Test and commit**

Run: `F:\bin\flutter.bat test test/app/character_select_screen_test.dart test/app/stage_select_screen_test.dart test/app/level_up_overlay_test.dart test/game/unlock_definitions_test.dart`

Expected: PASS; no base lock remains and Gakgung level 6 is visible.

```powershell
git add assets/images/weapons lib/app/character_select_screen.dart lib/app/stage_select_screen.dart lib/app/level_up_overlay.dart lib/app/compendium_screen.dart lib/game/content/unlock_definitions.dart test/app/character_select_screen_test.dart test/app/stage_select_screen_test.dart test/app/level_up_overlay_test.dart test/game/unlock_definitions_test.dart
git commit -m "feat: present complete base content"
```

### Task 11: Mobile Golden, Five-Minute Balance, and Release Gates

**Files:**
- Modify: `test/app/balanced_casual_combat_golden_test.dart`
- Replace: `test/app/goldens/balanced_casual_early_390x844.png`
- Replace: `test/app/goldens/balanced_casual_late_390x844.png`
- Modify: `test/game/five_minute_run_simulation_test.dart`
- Modify: `test/game/five_minute_performance_development_log_test.dart`
- Modify: `docs/playtest/2026-07-22-complete-base-roster-checklist.md`

**Interfaces:**
- Consumes: all prior tasks.
- Produces: release evidence and a phone playtest checklist; does not mark temporary art approved.

- [ ] **Step 1: Add failing end-to-end assertions**

```dart
expect(report.weaponIds, containsAll(BaseContentPolicy.weaponIds));
expect(report.lateAverageEnemyCount, inInclusiveRange(30, 55));
expect(report.maximumEnemyCount, lessThanOrEqualTo(96));
expect(report.minimumFps, greaterThanOrEqualTo(45));
expect(report.damageNumberPeak, lessThanOrEqualTo(24));
```

- [ ] **Step 2: Run focused simulations and adjust spawn mix only**

Run: `F:\bin\flutter.bat test test/game/five_minute_run_simulation_test.dart test/game/five_minute_performance_development_log_test.dart`

Expected: PASS after tuning enemy count/mix/direction; do not solve difficulty by globally inflating health.

- [ ] **Step 3: Regenerate and inspect 390×844 goldens**

Run: `F:\bin\flutter.bat test test/app/balanced_casual_combat_golden_test.dart --update-goldens`

Expected: PASS; early image shows readable player/enemy silhouettes and late image shows dense but legible master effects with no rectangles.

- [ ] **Step 4: Write phone checklist**

Include: all 3 characters selectable; both maps selectable; all 12 weapons can appear; no seventh weapon; Gakgung reaches 6 and visibly fires `관월추성`; all 13 enemies remain identifiable; no orange squares; attack warnings stay visible; master audio differs; late frame rate remains playable; a second run can start.

- [ ] **Step 5: Run all release gates**

```powershell
$env:TEMP='D:\CodexTemp\balanced-casual-art-overhaul'
$env:TMP='D:\CodexTemp\balanced-casual-art-overhaul'
F:\bin\flutter.bat analyze
F:\bin\flutter.bat test
F:\bin\flutter.bat build web --release
F:\bin\flutter.bat build apk --debug
```

Expected: analyze reports no issues; all tests pass; `build/web` exists; `build/app/outputs/flutter-apk/app-debug.apk` exists.

- [ ] **Step 6: Commit release evidence**

```powershell
git add test/app/balanced_casual_combat_golden_test.dart test/app/goldens test/game/five_minute_run_simulation_test.dart test/game/five_minute_performance_development_log_test.dart docs/playtest/2026-07-22-complete-base-roster-checklist.md
git commit -m "test: verify complete base roster slice"
```

- [ ] **Step 7: Publish external phone build without approving art**

Serve `build/web` on the existing external tunnel or replace it with a verified tunnel. Confirm the external root returns HTTP 200 and downloaded `main.dart.js` SHA-256 matches local `build/web/main.dart.js`. Report the URL and keep every new atlas status `temporary` until the user tests it on a phone.
