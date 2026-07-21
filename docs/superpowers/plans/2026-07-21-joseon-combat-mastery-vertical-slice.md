# Joseon Combat Mastery Vertical Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the approved six-stage hwando and talisman mastery slice, Sealing Slash synergy, four readable enemy roles, late-run horde pressure, combat feedback, and playtest telemetry without deleting save or unlock data.

**Architecture:** Keep the six existing non-slice weapons on `WeaponSystem`'s current path. Add immutable shared attack geometry, focused hwando and talisman executors, and a game-level synergy resolver; every hit test and visual reads the same attack instance. Inject playtest unlock policy and extend telemetry compatibly while preserving existing IDs, save schema, user-owned uncommitted presentation work, collision sizes, and performance caps.

**Tech Stack:** Dart 3.12, Flutter, Flame 1.18, `flutter_test`, `flame_test`, SharedPreferences-backed local repositories, PowerShell ASCII `subst` verification.

## Global Constraints

- Hwando and talisman use levels 1-5 plus level 6 `master`; the other six weapons remain capped at 5 in this slice.
- Development playtest exposes all eight implemented base weapons; normal mode preserves existing unlock rules and save data.
- Do not add placeholder weapons to fake the 10-12 weapon target.
- Do not create final bulk character or monster art; use enlarged temporary assets and readable code-rendered shapes.
- Damage geometry, visual geometry, direction, and timing derive from one immutable attack instance.
- All dangerous enemy actions have a visible warning and a dodge window.
- Preserve the existing frame spawn cap of 8, gem merging, accessibility settings, and population caps.
- Do not add monetization, shops, unrelated meta progression, or remove existing features and save fields.
- Preserve all pre-existing uncommitted files and review overlapping diffs before every commit.
- Use test-first red-green-refactor for every production behavior.

---

## File Structure

### New production files

- `lib/game/combat/attack_spec.dart`: immutable attack shape, timing, traits, presentation, and runtime instance contracts.
- `lib/game/combat/attack_geometry.dart`: pure sector, circle, and line/capsule containment calculations.
- `lib/game/systems/hwando_executor.dart`: six-level hwando cooldown, queued stages, and kill-refund behavior.
- `lib/game/systems/talisman_executor.dart`: attached seals, delayed explosions, transfer limits, and ward scheduling.
- `lib/game/systems/weapon_synergy_resolver.dart`: Sealing Slash marks, detonations, transfer cap, and first-use notice.
- `lib/game/components/attack_effect_component.dart`: renders an `AttackInstance` without redefining geometry.
- `lib/game/components/five_color_ward_component.dart`: timed ward ticks, slow amount, and O-bang presentation.
- `lib/game/components/enemy_projectile_component.dart`: readable hostile projectile with lifetime and player overlap.
- `lib/game/content/playtest_content_policy.dart`: injected all-base-weapons versus saved/default unlock resolution.
- `lib/game/systems/combat_feedback_controller.dart`: capped hit stop, shake requests, streak window, and notices.
- `lib/game/models/combat_playtest_metrics.dart`: immutable mastery, synergy, enemy-role, density, and FPS result fields.
- `lib/game/systems/combat_playtest_tracker.dart`: runtime recording and final metrics snapshot.
- `lib/game/systems/playtest_session_repository.dart`: persistent run ordinal used for second-run reporting.

### Existing production files to modify

- `lib/game/content/ids.dart`: attack traits and ranged enemy behavior kind.
- `lib/game/content/weapon_definitions.dart`: hwando/talisman max level 6.
- `lib/game/content/weapon_level_definitions.dart`: level 6 rows and behavior labels.
- `lib/game/systems/weapon_system.dart`: delegate slice weapons and return attack instances/feedback events.
- `lib/game/models/damage_event.dart`: carry attack traits and stable damage-source ID.
- `lib/game/pixel_survivor_game.dart`: resolve instances, synergy, marks, hostile projectiles, feedback, metrics, and policy.
- `lib/game/components/enemy_component.dart`: facing direction, warning pose, preferred-range movement, and directional defense.
- `lib/game/content/enemy_behavior_definitions.dart`: ranged profile and longer readable dash warning.
- `lib/game/systems/enemy_behavior_controller.dart`: ranged shot requests and preferred-range phases.
- `lib/game/content/enemy_definitions.dart`: add temporary sakkat specter and classify the four roles.
- `lib/game/content/asset_catalog.dart`: register the temporary sakkat specter asset slot without requiring final art.
- `lib/game/content/content_roster_contract.dart`: add the stable sakkat specter ID to the production roster.
- `lib/game/content/wave_definitions.dart`: mix all four roles and raise late density by spawn pressure first.
- `lib/game/game_performance_budget.dart`: hostile projectile/ward ownership budgets if separate caps are required.
- `lib/game/audio/audio_cue.dart`, `lib/game/audio/audio_asset_catalog.dart`, `lib/game/audio/game_audio_service.dart`: mastery and synergy cue layering.
- `lib/app/game_hud_source.dart`, `lib/app/game_hud.dart`: limited mastery/synergy/streak notice surface.
- `lib/app/game_screen.dart`, `lib/app/pixel_survivor_app.dart`: policy and persistent playtest run ordinal injection.
- `lib/game/models/run_result.dart`, `lib/game/models/run_telemetry.dart`, `lib/game/systems/run_stats_tracker.dart`: schema 2 metrics with schema 1 read compatibility.
- `lib/game/content/content_integrity.dart`: expected 42 weapon-level rows and added enemy references.
- `docs/assets/art-style-guide.md`, `lib/game/content/art_style_guide.dart`: approved non-pixel 3-4-head cel-shaded direction.
- `docs/telemetry/run-telemetry-schema.md`, `docs/testing/local-playtest.md`: schema and manual checklist.

### New focused tests

- `test/game/attack_geometry_test.dart`
- `test/game/playtest_content_policy_test.dart`
- `test/game/hwando_executor_test.dart`
- `test/game/talisman_executor_test.dart`
- `test/game/weapon_synergy_resolver_test.dart`
- `test/game/five_color_ward_component_test.dart`
- `test/game/enemy_projectile_component_test.dart`
- `test/game/combat_feedback_controller_test.dart`
- `test/game/combat_playtest_tracker_test.dart`
- `test/game/playtest_session_repository_test.dart`

Existing tests are extended where their fixture ownership already matches the behavior.

---

### Task 1: Lock the new art contract and playtest weapon access

**Files:**
- Create: `lib/game/content/playtest_content_policy.dart`
- Modify: `docs/assets/art-style-guide.md`
- Modify: `lib/game/content/art_style_guide.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `lib/app/game_screen.dart`
- Test: `test/game/playtest_content_policy_test.dart`
- Test: `test/game/art_style_guide_test.dart`
- Test: `test/game/pixel_survivor_game_loop_test.dart`

**Interfaces:**
- Produces: `PlaytestContentPolicy({required bool unlockAllBaseWeapons})`
- Produces: `Set<WeaponId> resolveWeaponIds(Iterable<WeaponId> normalIds)`
- Consumes: `weaponDefinitions` and the existing starting weapon injection.

- [ ] **Step 1: Write failing policy and game-construction tests**

```dart
test('playtest policy opens every implemented base weapon without mutating input', () {
  final saved = <WeaponId>{hwandoSlash};
  final resolved = const PlaytestContentPolicy(
    unlockAllBaseWeapons: true,
  ).resolveWeaponIds(saved);
  expect(resolved, weaponDefinitions.map((item) => item.id).toSet());
  expect(saved, {hwandoSlash});
});

test('normal policy preserves the supplied unlock set', () {
  expect(
    const PlaytestContentPolicy(unlockAllBaseWeapons: false)
        .resolveWeaponIds({hwandoSlash, talismanThrow}),
    {hwandoSlash, talismanThrow},
  );
});
```

- [ ] **Step 2: Run the focused tests and verify RED**

Run: `flutter test test/game/playtest_content_policy_test.dart test/game/art_style_guide_test.dart test/game/pixel_survivor_game_loop_test.dart`

Expected: FAIL because `PlaytestContentPolicy` and the new non-pixel art contract do not exist.

- [ ] **Step 3: Implement the policy and inject it into new runs**

```dart
class PlaytestContentPolicy {
  const PlaytestContentPolicy({required this.unlockAllBaseWeapons});

  final bool unlockAllBaseWeapons;

  Set<WeaponId> resolveWeaponIds(Iterable<WeaponId> normalIds) => {
    ...normalIds,
    if (unlockAllBaseWeapons)
      ...weaponDefinitions.map((definition) => definition.id),
  };
}
```

Add `PlaytestContentPolicy contentPolicy = const PlaytestContentPolicy(unlockAllBaseWeapons: false)` to `PixelSurvivorGame`, resolve the normal `startsUnlocked` set through it, and pass a debug `dart-define` default from `GameScreen` without changing saved unlock fields.

Replace the old pixel-only guide with the approved 3-4-head proportions, bold outline, 2-3 shade cel rendering, Joseon clothing vocabulary, ten monster silhouettes, forbidden samurai/wuxia cues, current 108/54/81/126 temporary render sizes, and no-bulk-art rule. Mirror machine-testable constants in `JoseonArtStyle`.

- [ ] **Step 4: Run focused tests and verify GREEN**

Run: `flutter test test/game/playtest_content_policy_test.dart test/game/art_style_guide_test.dart test/game/pixel_survivor_game_loop_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit the isolated policy and art contract**

```powershell
git add -- docs/assets/art-style-guide.md lib/game/content/art_style_guide.dart lib/game/content/playtest_content_policy.dart lib/game/pixel_survivor_game.dart lib/app/game_screen.dart test/game/playtest_content_policy_test.dart test/game/art_style_guide_test.dart test/game/pixel_survivor_game_loop_test.dart
git diff --cached --check
git commit -m "feat: add combat slice playtest content policy"
```

### Task 2: Add one immutable attack geometry contract

**Files:**
- Create: `lib/game/combat/attack_spec.dart`
- Create: `lib/game/combat/attack_geometry.dart`
- Create: `test/game/attack_geometry_test.dart`
- Modify: `lib/game/models/damage_event.dart`

**Interfaces:**
- Produces: `enum AttackShape { sector, circle, line }`
- Produces: `enum AttackTrait { melee, projectile, piercing, explosion, master, synergy }`
- Produces: `AttackSpec`, `AttackInstance`, and `bool AttackGeometry.contains(AttackInstance attack, Vector2 targetCenter, double targetRadius)`.
- Produces: `DamageEvent.sourceId` and `DamageEvent.traits`.

- [ ] **Step 1: Write failing pure geometry tests**

```dart
test('sector visual and hit test use the same frozen direction', () {
  final attack = AttackInstance(
    spec: const AttackSpec(
      id: 'test_sector', shape: AttackShape.sector, damage: 8,
      range: 60, angleRadians: pi / 2, radius: 0, width: 0,
      windupSeconds: 0, activeSeconds: .08, lingerSeconds: .12,
      knockback: 20, slowFraction: 0,
      traits: {AttackTrait.melee}, presentation: AttackPresentation.normal,
    ),
    origin: Vector2.zero(), direction: Vector2(1, 0), sequenceIndex: 0,
  );
  expect(AttackGeometry.contains(attack, Vector2(40, 10), 9), isTrue);
  expect(AttackGeometry.contains(attack, Vector2(-40, 0), 9), isFalse);
  expect(attack.direction, Vector2(1, 0));
});
```

Add circle edge and line capsule width tests plus zero-direction normalization.

- [ ] **Step 2: Run and verify RED**

Run: `flutter test test/game/attack_geometry_test.dart`

Expected: FAIL because the combat attack contracts are absent.

- [ ] **Step 3: Implement the immutable contracts**

```dart
enum AttackShape { sector, circle, line }
enum AttackTrait { melee, projectile, piercing, explosion, master, synergy }
enum AttackPresentation { normal, strong, master, synergy }

@immutable
class AttackSpec {
  const AttackSpec({
    required this.id, required this.shape, required this.damage,
    required this.range, required this.angleRadians, required this.radius,
    required this.width, required this.windupSeconds,
    required this.activeSeconds, required this.lingerSeconds,
    required this.knockback, required this.slowFraction,
    required this.traits, required this.presentation,
  });
  final String id;
  final AttackShape shape;
  final double damage, range, angleRadians, radius, width;
  final double windupSeconds, activeSeconds, lingerSeconds;
  final double knockback, slowFraction;
  final Set<AttackTrait> traits;
  final AttackPresentation presentation;
}

@immutable
class AttackInstance {
  AttackInstance({required this.spec, required Vector2 origin,
    required Vector2 direction, required this.sequenceIndex})
      : origin = origin.clone(), direction = _unit(direction);
  final AttackSpec spec;
  final Vector2 origin, direction;
  final int sequenceIndex;
}
```

Use squared-distance and dot-product calculations in `AttackGeometry`; do not read render component sizes. Extend `DamageEvent` with defaulted immutable `sourceId` and `Set<AttackTrait> traits` so old callers remain source-compatible.

- [ ] **Step 4: Run geometry and existing combat tests**

Run: `flutter test test/game/attack_geometry_test.dart test/game/combat_system_test.dart test/game/weapon_system_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add -- lib/game/combat lib/game/models/damage_event.dart test/game/attack_geometry_test.dart
git diff --cached --check
git commit -m "feat: add shared attack geometry contract"
```

### Task 3: Expand hwando and talisman content to six levels

**Files:**
- Modify: `lib/game/content/weapon_definitions.dart`
- Modify: `lib/game/content/weapon_level_definitions.dart`
- Modify: `lib/game/content/content_integrity.dart`
- Modify: `lib/game/systems/level_up_system.dart`
- Test: `test/game/content_definitions_test.dart`
- Test: `test/game/content_integrity_test.dart`
- Test: `test/game/level_up_system_test.dart`

**Interfaces:**
- Produces: `WeaponLevelDefinition.isMaster` and `behaviorDescription`.
- Produces: exactly 42 level rows: 6 hwando, 6 talisman, 5 for each of six other weapons.

- [ ] **Step 1: Write failing level-contract tests**

```dart
test('slice weapons have a distinct sixth master level', () {
  expect(weaponDefinitions.singleWhere((w) => w.id == hwandoSlash).maxLevel, 6);
  expect(weaponDefinitions.singleWhere((w) => w.id == talismanThrow).maxLevel, 6);
  expect(weaponLevelFor(hwandoSlash, 6).isMaster, isTrue);
  expect(weaponLevelFor(talismanThrow, 6).isMaster, isTrue);
  expect(weaponDefinitions.where((w) => w.id != hwandoSlash && w.id != talismanThrow)
      .every((w) => w.maxLevel == 5), isTrue);
});
```

- [ ] **Step 2: Run and verify RED**

Run: `flutter test test/game/content_definitions_test.dart test/game/content_integrity_test.dart test/game/level_up_system_test.dart`

Expected: FAIL with old max level 5 and old expected row count 40.

- [ ] **Step 3: Add explicit behavior metadata and level 6 rows**

```dart
class WeaponLevelDefinition {
  const WeaponLevelDefinition({
    required this.damage, required this.cooldownSeconds,
    required this.range, required this.projectileCount,
    required this.pierce, required this.chainCount,
    required this.knockback, required this.displayEffect,
    required this.behaviorDescription,
    this.isMaster = false, this.durationSeconds = 0, this.slowFraction = 0,
  });
  final bool isMaster;
  final String behaviorDescription;
  // Existing numeric fields remain unchanged.
}
```

Give every row a concrete Korean behavior description. Set hwando L6 to master storm values and talisman L6 to multi-ward values. Update level-up descriptions so acquiring level 6 starts with `마스터 ·` and uses the behavior description instead of presenting only numeric deltas.

- [ ] **Step 4: Run focused tests and verify GREEN**

Run: `flutter test test/game/content_definitions_test.dart test/game/content_integrity_test.dart test/game/level_up_system_test.dart`

Expected: PASS with 42 rows.

- [ ] **Step 5: Commit**

```powershell
git add -- lib/game/content/weapon_definitions.dart lib/game/content/weapon_level_definitions.dart lib/game/content/content_integrity.dart lib/game/systems/level_up_system.dart test/game/content_definitions_test.dart test/game/content_integrity_test.dart test/game/level_up_system_test.dart
git diff --cached --check
git commit -m "feat: define six-stage slice weapon growth"
```

### Task 4: Implement the six-stage hwando executor

**Files:**
- Create: `lib/game/systems/hwando_executor.dart`
- Create: `test/game/hwando_executor_test.dart`
- Modify: `lib/game/systems/weapon_system.dart`
- Modify: `test/game/weapon_system_test.dart`

**Interfaces:**
- Produces: `HwandoExecutor.tick(HwandoTickInput) -> List<AttackInstance>`.
- Produces: `HwandoExecutor.recordKill({required int count})`.
- Consumes: frozen aim from `HwandoAimResolver` and level definitions.

- [ ] **Step 1: Write failing behavior tests for levels 1, 3, 4, 5, and 6**

```dart
test('master queues targeted opener, two half sweeps, circle, and finisher', () {
  final executor = HwandoExecutor();
  final emitted = <AttackInstance>[];
  for (var frame = 0; frame < 40; frame++) {
    emitted.addAll(executor.tick(HwandoTickInput(
      dt: .02, level: 6, origin: Vector2.zero(),
      aimDirection: Vector2(0, -1), damageMultiplier: 1, sizeMultiplier: 1,
    )));
  }
  expect(emitted.map((a) => a.spec.id), [
    'hwando_master_opener', 'hwando_master_left', 'hwando_master_right',
    'hwando_master_circle', 'hwando_master_finisher',
  ]);
  expect(emitted.every((a) => a.spec.traits.contains(AttackTrait.master)), isTrue);
});
```

Add tests proving L3 attacks are time-separated, L4 emits a line blade wave after the second slash, L5 kill refund cannot exceed the configured per-cycle cap, and dead/out-of-range targets do not change the frozen direction.

- [ ] **Step 2: Run and verify RED**

Run: `flutter test test/game/hwando_executor_test.dart test/game/weapon_system_test.dart`

Expected: FAIL because `HwandoExecutor` does not exist.

- [ ] **Step 3: Implement a bounded scheduled-stage executor**

```dart
class HwandoTickInput {
  const HwandoTickInput({required this.dt, required this.level,
    required this.origin, required this.aimDirection,
    required this.damageMultiplier, required this.sizeMultiplier});
  final double dt, damageMultiplier, sizeMultiplier;
  final int level;
  final Vector2 origin, aimDirection;
}

class HwandoExecutor {
  static const maxKillRefundPerCycle = .24;
  final List<_ScheduledHwandoStage> _stages = [];
  double _cooldown = 0;
  double _refundedThisCycle = 0;

  List<AttackInstance> tick(HwandoTickInput input) {
    final dt = input.dt.clamp(0, .05).toDouble();
    _cooldown = max(0, _cooldown - dt);
    for (final stage in _stages) {
      stage.remainingSeconds -= dt;
    }
    final ready = _stages.where((stage) => stage.remainingSeconds <= 0).toList();
    _stages.removeWhere((stage) => stage.remainingSeconds <= 0);
    if (ready.isNotEmpty) {
      return [for (final stage in ready) stage.instantiate(input)];
    }
    if (_cooldown > 0 || _stages.isNotEmpty || input.level == 0) return const [];
    final level = weaponLevelFor(hwandoSlash, input.level);
    _cooldown = level.cooldownSeconds;
    _refundedThisCycle = 0;
    _stages.addAll(_scheduleFor(input.level));
    return tick(HwandoTickInput(
      dt: 0, level: input.level, origin: input.origin,
      aimDirection: input.aimDirection,
      damageMultiplier: input.damageMultiplier,
      sizeMultiplier: input.sizeMultiplier,
    ));
  }
  void recordKill({required int count}) {
    final refund = min(maxKillRefundPerCycle - _refundedThisCycle, count * .06);
    if (refund <= 0) return;
    _cooldown = max(0, _cooldown - refund);
    _refundedThisCycle += refund;
  }
}

List<_ScheduledHwandoStage> _scheduleFor(int level) => switch (level) {
  1 || 2 => [_ScheduledHwandoStage('hwando_slash', 0, 0)],
  3 => [_ScheduledHwandoStage('hwando_slash_left', 0, 0),
        _ScheduledHwandoStage('hwando_slash_right', .10, 1)],
  4 || 5 => [_ScheduledHwandoStage('hwando_slash_left', 0, 0),
        _ScheduledHwandoStage('hwando_slash_right', .10, 1),
        _ScheduledHwandoStage('hwando_blade_wave', .18, 2)],
  6 => [_ScheduledHwandoStage('hwando_master_opener', 0, 0),
        _ScheduledHwandoStage('hwando_master_left', .10, 1),
        _ScheduledHwandoStage('hwando_master_right', .20, 2),
        _ScheduledHwandoStage('hwando_master_circle', .32, 3),
        _ScheduledHwandoStage('hwando_master_finisher', .46, 4)],
  _ => throw RangeError.range(level, 1, 6, 'level'),
};
```

Replace only `_fireHwando` with delegation. `WeaponTickResult` gains `attackInstances`; existing `meleeArcs` compatibility remains until the game integration task replaces it.

- [ ] **Step 4: Run focused tests and verify GREEN**

Run: `flutter test test/game/hwando_executor_test.dart test/game/weapon_system_test.dart test/game/hwando_aim_resolver_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add -- lib/game/systems/hwando_executor.dart lib/game/systems/weapon_system.dart test/game/hwando_executor_test.dart test/game/weapon_system_test.dart
git diff --cached --check
git commit -m "feat: implement hwando mastery attack sequence"
```

### Task 5: Render and resolve shared attacks with capped combat feedback

**Files:**
- Create: `lib/game/components/attack_effect_component.dart`
- Create: `lib/game/systems/combat_feedback_controller.dart`
- Create: `test/game/combat_feedback_controller_test.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `lib/game/systems/combat_feedback_tuning.dart`
- Modify: `lib/game/audio/audio_cue.dart`
- Modify: `lib/game/audio/audio_asset_catalog.dart`
- Modify: `test/game/pixel_survivor_game_loop_test.dart`
- Modify: `test/game/audio_cue_test.dart`

**Interfaces:**
- Produces: `AttackEffectComponent(instance: AttackInstance)`.
- Produces: `CombatFeedbackController.request(CombatFeedbackRequest)` and `tick(dt)`.
- Consumes: `AttackGeometry.contains`, accessibility shake setting, existing audio service.

- [ ] **Step 1: Write failing cap and integration tests**

```dart
test('master feedback caps stacked hit stop and honors disabled shake', () {
  final feedback = CombatFeedbackController(screenShakeEnabled: false);
  feedback.request(const CombatFeedbackRequest.master());
  feedback.request(const CombatFeedbackRequest.master());
  expect(feedback.hitStopRemaining, .035);
  expect(feedback.pendingShakeMagnitude, 0);
});
```

Add a mounted game test proving a master attack's affected enemy set equals `AttackGeometry` and that one master cue is emitted at sequence start, not for every stage.

- [ ] **Step 2: Run and verify RED**

Run: `flutter test test/game/combat_feedback_controller_test.dart test/game/pixel_survivor_game_loop_test.dart test/game/audio_cue_test.dart`

Expected: FAIL because shared attack rendering and feedback do not exist.

- [ ] **Step 3: Implement shared resolution and rendering**

```dart
class CombatFeedbackRequest {
  const CombatFeedbackRequest({required this.hitStopSeconds,
    required this.shakeMagnitude, required this.presentation});
  const CombatFeedbackRequest.master()
      : hitStopSeconds = .035, shakeMagnitude = 4,
        presentation = AttackPresentation.master;
  final double hitStopSeconds, shakeMagnitude;
  final AttackPresentation presentation;
}
```

`AttackEffectComponent.render` switches on `AttackShape` and `AttackPresentation`, drawing cyan-white/gold hwando master geometry directly from the instance. `PixelSurvivorGame` resolves targets with `AttackGeometry`, creates `DamageEvent` values with matching traits, adds one visual per stage under the combat-effect budget, and pauses combat simulation only for the controller's capped remaining hit-stop duration.

Add `hwandoMasterAttack`, `talismanMasterAttack`, and `sealingSlash` audio cues. Map them to approved existing SFX files as replaceable temporary layers; emit the ordinary and strong cue sequence through `GameAudioService` without adding unlicensed files.

- [ ] **Step 4: Run focused tests and verify GREEN**

Run: `flutter test test/game/combat_feedback_controller_test.dart test/game/pixel_survivor_game_loop_test.dart test/game/audio_cue_test.dart test/game/game_performance_budget_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add -- lib/game/components/attack_effect_component.dart lib/game/systems/combat_feedback_controller.dart lib/game/systems/combat_feedback_tuning.dart lib/game/pixel_survivor_game.dart lib/game/audio test/game/combat_feedback_controller_test.dart test/game/pixel_survivor_game_loop_test.dart test/game/audio_cue_test.dart
git diff --cached --check
git commit -m "feat: add mastery combat presentation pipeline"
```

### Task 6: Implement attached talismans and five-color wards

**Files:**
- Create: `lib/game/systems/talisman_executor.dart`
- Create: `lib/game/components/five_color_ward_component.dart`
- Create: `test/game/talisman_executor_test.dart`
- Create: `test/game/five_color_ward_component_test.dart`
- Modify: `lib/game/systems/weapon_system.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `test/game/weapon_system_test.dart`

**Interfaces:**
- Produces: `TalismanExecutor.tick(TalismanTickInput) -> TalismanTickResult`.
- Produces: `TalismanTickResult.attached`, `.attacks`, `.wards`, `.removedTargetIds`.
- Produces: `List<DamageEvent> FiveColorWardComponent.collectDamageEvents(Iterable<EnemyComponent> enemies)` and `double slowFor(EnemyComponent enemy)`.

- [ ] **Step 1: Write failing attachment, transfer, cleanup, and master tests**

```dart
test('level six creates bounded wards at distinct dense enemy centers', () {
  final result = TalismanExecutor().tick(TalismanTickInput(
    dt: 2, level: 6, now: 2, origin: Vector2.zero(), enemies: clusteredEnemies,
    damageMultiplier: 1, sizeMultiplier: 1,
  ));
  expect(result.wards, hasLength(3));
  expect(result.wards.every((ward) => ward.presentation == AttackPresentation.master), isTrue);
});
```

Add tests for L3 delayed explosion, L4 transfer only to unmarked living targets, L5 small ward, maximum 24 attached seals, maximum transfer depth 2, maximum 3 master wards, and cleanup when targets die or remove.

- [ ] **Step 2: Run and verify RED**

Run: `flutter test test/game/talisman_executor_test.dart test/game/five_color_ward_component_test.dart test/game/weapon_system_test.dart`

Expected: FAIL because talisman stateful execution does not exist.

- [ ] **Step 3: Implement bounded state and ward ticks**

```dart
class TalismanTickResult {
  const TalismanTickResult({this.attacks = const [], this.wards = const []});
  final List<AttackInstance> attacks;
  final List<WardSpawnRequest> wards;
}

class TalismanExecutor {
  static const maxAttachedSeals = 24;
  static const maxTransferDepth = 2;
  static const maxMasterWards = 3;
  final Map<EnemyComponent, AttachedTalisman> _attached = {};
  TalismanTickResult tick(TalismanTickInput input) {
    _attached.removeWhere((enemy, seal) => enemy.isDead || enemy.isRemoving);
    final attacks = <AttackInstance>[];
    final wards = <WardSpawnRequest>[];
    final expired = _attached.entries
        .where((entry) => entry.value.explodeAtSeconds <= input.now)
        .toList(growable: false);
    for (final entry in expired) {
      _attached.remove(entry.key);
      attacks.add(_explosionFor(entry.key, input));
      if (input.level >= 5) wards.add(_smallWardFor(entry.key.position, input));
      if (input.level >= 4 && entry.value.transferDepth < maxTransferDepth) {
        _transferFrom(entry.key, entry.value.transferDepth + 1, input);
      }
    }
    if (_canFire(input)) _attachOrStrikeNearest(input, attacks);
    if (input.level == 6 && _canCreateMasterWards(input)) {
      wards.addAll(_masterWardsFor(input).take(maxMasterWards));
    }
    return TalismanTickResult(attacks: attacks, wards: wards);
  }
}
```

The ward component owns radius, duration, tick interval, slow fraction, `AttackInstance`, and a pending tick count. It renders five fixed O-bang arcs plus a hanji center. `PixelSurvivorGame` applies the strongest active ward slow once per frame, as it already does for frost fields.

- [ ] **Step 4: Run focused tests and verify GREEN**

Run: `flutter test test/game/talisman_executor_test.dart test/game/five_color_ward_component_test.dart test/game/weapon_system_test.dart test/game/pixel_survivor_game_loop_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add -- lib/game/systems/talisman_executor.dart lib/game/components/five_color_ward_component.dart lib/game/systems/weapon_system.dart lib/game/pixel_survivor_game.dart test/game/talisman_executor_test.dart test/game/five_color_ward_component_test.dart test/game/weapon_system_test.dart test/game/pixel_survivor_game_loop_test.dart
git diff --cached --check
git commit -m "feat: implement talisman mastery wards"
```

### Task 7: Implement Sealing Slash as a rule-changing synergy

**Files:**
- Create: `lib/game/systems/weapon_synergy_resolver.dart`
- Create: `test/game/weapon_synergy_resolver_test.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `lib/game/systems/run_stats_tracker.dart`
- Modify: `test/game/pixel_survivor_game_loop_test.dart`
- Modify: `test/game/run_stats_tracker_test.dart`

**Interfaces:**
- Produces: `const sealingSlash = 'sealing_slash'`.
- Produces: `SynergyResolution WeaponSynergyResolver.onHwandoHit({required EnemyComponent target, required Iterable<EnemyComponent> nearby, required double now, required int originatingAttackId})`.
- Produces: first-activation notice and separate synergy damage source.

- [ ] **Step 1: Write failing mark, detonation, transfer, and notice tests**

```dart
test('second hwando hit consumes mark, explodes, and transfers bounded marks', () {
  final resolver = WeaponSynergyResolver();
  resolver.onHwandoHit(target: center, nearby: enemies, now: 1);
  final result = resolver.onHwandoHit(target: center, nearby: enemies, now: 2);
  expect(result.attack?.spec.id, sealingSlash);
  expect(result.markedTargets, hasLength(3));
  expect(result.showFirstActivationNotice, isTrue);
  expect(resolver.onHwandoHit(target: center, nearby: enemies, now: 3)
      .showFirstActivationNotice, isFalse);
});
```

Add dead-target cleanup and maximum one detonation per target per originating attack test.

- [ ] **Step 2: Run and verify RED**

Run: `flutter test test/game/weapon_synergy_resolver_test.dart test/game/run_stats_tracker_test.dart test/game/pixel_survivor_game_loop_test.dart`

Expected: FAIL because the synergy resolver and source ID are absent.

- [ ] **Step 3: Implement resolver and game integration**

```dart
class SynergyResolution {
  const SynergyResolution({this.attack, this.markedTargets = const [],
    this.showFirstActivationNotice = false});
  final AttackInstance? attack;
  final List<EnemyComponent> markedTargets;
  final bool showFirstActivationNotice;
}
```

Activate only while both weapon levels are greater than zero. Add golden/O-bang synergy rendering through `AttackPresentation.synergy`, emit `AudioCue.sealingSlash`, and expose a 1.2-second first-use HUD notice. Record damage under `sealing_slash`, not `hwando_slash` or `talisman_throw`.

- [ ] **Step 4: Run focused tests and verify GREEN**

Run: `flutter test test/game/weapon_synergy_resolver_test.dart test/game/run_stats_tracker_test.dart test/game/pixel_survivor_game_loop_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add -- lib/game/systems/weapon_synergy_resolver.dart lib/game/pixel_survivor_game.dart lib/game/systems/run_stats_tracker.dart test/game/weapon_synergy_resolver_test.dart test/game/pixel_survivor_game_loop_test.dart test/game/run_stats_tracker_test.dart
git diff --cached --check
git commit -m "feat: add sealing slash weapon synergy"
```

### Task 8: Add ranged and directional-defense enemies and strengthen telegraphs

**Files:**
- Create: `lib/game/components/enemy_projectile_component.dart`
- Create: `test/game/enemy_projectile_component_test.dart`
- Modify: `lib/game/content/ids.dart`
- Modify: `lib/game/content/enemy_behavior_definitions.dart`
- Modify: `lib/game/systems/enemy_behavior_controller.dart`
- Modify: `lib/game/content/enemy_definitions.dart`
- Modify: `lib/game/content/asset_catalog.dart`
- Modify: `lib/game/content/content_roster_contract.dart`
- Modify: `lib/game/content/content_integrity.dart`
- Modify: `lib/game/components/enemy_component.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Test: `test/game/enemy_behavior_controller_test.dart`
- Test: `test/game/enemy_component_test.dart`
- Test: `test/game/content_definitions_test.dart`

**Interfaces:**
- Adds: `EnemyBehaviorKind.ranged` and `EnemyAttackKind.projectile`.
- Produces: `EnemyComponent.resolveIncomingDamage(DamageEvent) -> double`.
- Produces: `EnemyProjectileComponent(sourceId, damage, position, velocity)`.

- [ ] **Step 1: Write failing role behavior tests**

```dart
test('ranged profile retreats inside minimum range and warns before shooting', () {
  final controller = EnemyBehaviorController(profile: enemyBehaviorProfiles['sakkat_ranged']!);
  final close = controller.tick(dt: .1, origin: Vector2.zero(), target: Vector2(40, 0));
  expect(close.movementMultiplier, lessThan(0));
  // Advance through the complete warning window.
  EnemyAttackRequest? shot;
  for (var i = 0; i < 20; i++) {
    shot ??= controller.tick(dt: .05, origin: Vector2.zero(), target: Vector2(180, 0)).attack;
  }
  expect(shot?.kind, EnemyAttackKind.projectile);
});

test('dokkaebi reduces frontal normal hits but not rear explosions', () {
  final enemy = EnemyComponent.fromDefinition(enemyDefinitionFor(dokkaebi)!, position: Vector2.zero());
  enemy.debugFace(Vector2(1, 0));
  expect(enemy.resolveIncomingDamage(frontMeleeEvent), 5);
  expect(enemy.resolveIncomingDamage(rearExplosionEvent), 10);
});
```

Add projectile warning/lifetime/player-overlap tests and assert the dash profile warning is at least `.5` seconds.

- [ ] **Step 2: Run and verify RED**

Run: `flutter test test/game/enemy_behavior_controller_test.dart test/game/enemy_component_test.dart test/game/enemy_projectile_component_test.dart test/game/content_definitions_test.dart`

Expected: FAIL because ranged behavior, projectile, and defense resolution are absent.

- [ ] **Step 3: Implement four explicit role contracts**

Add `sakkatSpecter` with normal rank, spirit faction, readable fallback silhouette, health between swarm and tank, and profile values: preferred range 170, minimum range 105, warning `.7`, cooldown `2.6`, projectile speed 150. Negative movement multiplier means move away from the target; zero means hold position.

Register the stable ID in `ContentRosterContract`, change the production normal-enemy count from 8 to 9, and add an `AssetCatalog.monsters` temporary slot. Do not add an `EnemySpriteSheet` entry for this ID in the slice: the component's code-rendered wide gat and trailing spirit body must remain active until a distinct approved sprite exists.

Update `EnemyBehaviorTick` to carry `movementDirection` or an explicit approach/retreat mode instead of encoding retreat only in speed. Freeze shot direction at warning start. Draw a danger-colored aim line and a widening charge circle.

Track enemy facing from meaningful movement or locked attack direction. For tank behavior use this exact rule:

```dart
double resolveIncomingDamage(DamageEvent event) {
  if (behaviorType != EnemyBehaviorType.tank) return event.damage;
  if (event.traits.contains(AttackTrait.explosion) ||
      event.traits.contains(AttackTrait.synergy)) return event.damage;
  final frontal = facingDirection.dot(-event.direction) >= cos(pi / 3);
  if (!frontal) return event.damage;
  final reduction = event.traits.contains(AttackTrait.piercing) ? .2 : .5;
  return event.damage * (1 - reduction);
}
```

Resolve hostile projectiles under the projectile population cap, use a distinct red-violet outline, and remove them on hit, lifetime expiry, or world bounds.

- [ ] **Step 4: Run focused tests and verify GREEN**

Run: `flutter test test/game/enemy_behavior_controller_test.dart test/game/enemy_component_test.dart test/game/enemy_projectile_component_test.dart test/game/content_definitions_test.dart test/game/pixel_survivor_game_loop_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add -- lib/game/content/ids.dart lib/game/content/enemy_behavior_definitions.dart lib/game/content/enemy_definitions.dart lib/game/content/asset_catalog.dart lib/game/content/content_roster_contract.dart lib/game/content/content_integrity.dart lib/game/systems/enemy_behavior_controller.dart lib/game/components/enemy_component.dart lib/game/components/enemy_projectile_component.dart lib/game/pixel_survivor_game.dart test/game/enemy_behavior_controller_test.dart test/game/enemy_component_test.dart test/game/enemy_projectile_component_test.dart test/game/content_definitions_test.dart
git diff --cached --check
git commit -m "feat: add ranged and directional defense enemies"
```

### Task 9: Tune late-run mixed horde pressure and performance bounds

**Files:**
- Modify: `lib/game/content/wave_definitions.dart`
- Modify: `lib/game/game_performance_budget.dart`
- Modify: `lib/game/performance/performance_development_log.dart`
- Modify: `docs/testing/five-minute-performance-development-log.md`
- Test: `test/game/wave_director_test.dart`
- Test: `test/game/five_minute_performance_development_log_test.dart`
- Test: `test/game/five_minute_run_simulation_test.dart`

**Interfaces:**
- Consumes: all four normal enemy roles and existing elite pools.
- Produces: fixed-seed observed average/maximum enemies and late-frame metrics.

- [ ] **Step 1: Write failing wave-composition and pressure assertions**

```dart
test('180-270 second waves contain all four vertical-slice roles', () {
  final ids = moonlitAbandonedOfficeWaves
      .where((w) => w.startSecond >= 180 && w.startSecond < 270)
      .expand((w) => w.enemyWeights.keys).toSet();
  expect(ids, containsAll({plagueRatSwarm, vengefulSpirit, sakkatSpecter, dokkaebi}));
});

test('late pressure prioritizes count without inflating normal health', () {
  final pressure = wavePressureForSecond(255);
  expect(pressure.maxActiveEnemies, greaterThanOrEqualTo(90));
  expect(enemyDefinitionFor(plagueRatSwarm)!.maxHealth, 8);
});
```

- [ ] **Step 2: Run and verify RED**

Run: `flutter test test/game/wave_director_test.dart test/game/five_minute_run_simulation_test.dart test/game/five_minute_performance_development_log_test.dart`

Expected: FAIL because the new ranged role is not in late waves and the log lacks average/maximum active-enemy fields.

- [ ] **Step 3: Tune weights and extend deterministic performance logging**

Raise spawn rate and group size before health. Keep boss-second behavior and frame spawn cap unchanged. Extend the development collector with sum/sample/max active enemy values and late-window average/minimum simulated FPS derived from raw frame duration, not the game's clamped combat `dt`.

- [ ] **Step 4: Run the five-minute deterministic tests**

Run: `flutter test test/game/wave_director_test.dart test/game/five_minute_run_simulation_test.dart test/game/five_minute_performance_development_log_test.dart test/game/game_performance_budget_test.dart`

Expected: PASS with no population or retained-owner violations, exactly one boss request, and recorded late density.

- [ ] **Step 5: Commit**

```powershell
git add -- lib/game/content/wave_definitions.dart lib/game/game_performance_budget.dart lib/game/performance/performance_development_log.dart docs/testing/five-minute-performance-development-log.md test/game/wave_director_test.dart test/game/five_minute_run_simulation_test.dart test/game/five_minute_performance_development_log_test.dart
git diff --cached --check
git commit -m "balance: raise mixed late-run horde pressure"
```

### Task 10: Capture mastery, synergy, enemy-role, density, and FPS metrics

**Files:**
- Create: `lib/game/models/combat_playtest_metrics.dart`
- Create: `lib/game/systems/combat_playtest_tracker.dart`
- Create: `test/game/combat_playtest_tracker_test.dart`
- Modify: `lib/game/models/run_result.dart`
- Modify: `lib/game/models/run_telemetry.dart`
- Modify: `lib/game/systems/run_stats_tracker.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `docs/telemetry/run-telemetry-schema.md`
- Test: `test/game/run_telemetry_test.dart`
- Test: `test/game/run_stats_tracker_test.dart`

**Interfaces:**
- Produces: `CombatPlaytestTracker.recordOffer`, `recordLevel`, `recordMasterActivation`, `recordKill`, `recordSynergyDamage`, `recordEnemyDamage`, `recordEnemyDeath`, `recordFrame`.
- Produces: immutable `CombatPlaytestMetrics snapshot()`.
- Produces: telemetry schema 2 writer and schema 1/2 reader.

- [ ] **Step 1: Write failing metric-window and compatibility tests**

```dart
test('master activation counts kills only inside the following ten seconds', () {
  final tracker = CombatPlaytestTracker();
  tracker.recordMasterActivation(weaponId: hwandoSlash, atSeconds: 200);
  tracker.recordKill(atSeconds: 209, sourceId: hwandoSlash, enemyBehaviorId: 'swarm');
  tracker.recordKill(atSeconds: 211, sourceId: hwandoSlash, enemyBehaviorId: 'tank');
  expect(tracker.snapshot().masterKillsInTenSeconds[hwandoSlash], 1);
});

test('schema one telemetry loads with empty combat metrics', () {
  final loaded = RunTelemetry.fromJson(schemaOneFixture);
  expect(loaded.combatMetrics, CombatPlaytestMetrics.empty);
});
```

Add offer/selection, first synergy time, damage totals, role damage/death cause, average/max enemy count, late average/min FPS, and mastery flag tests.

- [ ] **Step 2: Run and verify RED**

Run: `flutter test test/game/combat_playtest_tracker_test.dart test/game/run_telemetry_test.dart test/game/run_stats_tracker_test.dart`

Expected: FAIL because schema 2 and combat metrics are absent.

- [ ] **Step 3: Implement immutable metrics and schema migration**

```dart
@immutable
class CombatPlaytestMetrics {
  const CombatPlaytestMetrics({required this.weaponOfferCounts,
    required this.weaponSelectionCounts, required this.weaponLevelTimes,
    required this.firstMasterAtSeconds, required this.masterKillsInTenSeconds,
    required this.firstSynergyAtSeconds, required this.synergyDamageTotals,
    required this.enemyRoleDamageToPlayer, required this.enemyRoleDeathCauses,
    required this.averageEnemyCount, required this.maxEnemyCount,
    required this.lateAverageFps, required this.lateMinFps,
    required this.masteredWeaponIds, required this.isRepeatRun});
  static const empty = CombatPlaytestMetrics(
    weaponOfferCounts: {}, weaponSelectionCounts: {}, weaponLevelTimes: {},
    firstMasterAtSeconds: {}, masterKillsInTenSeconds: {},
    firstSynergyAtSeconds: {}, synergyDamageTotals: {},
    enemyRoleDamageToPlayer: {}, enemyRoleDeathCauses: {},
    averageEnemyCount: 0, maxEnemyCount: 0,
    lateAverageFps: 0, lateMinFps: 0,
    masteredWeaponIds: {}, isRepeatRun: false,
  );
  // Exact typed fields mirror the constructor names above.
}
```

Increment telemetry schema to 2. Parse schema 1 with `CombatPlaytestMetrics.empty`; parse schema 2 strictly. Record choice offers when `_queueLevelUpChoices` produces the list, selections when applied, raw frame `dt` before clamping, and final metrics in `RunResult`.

- [ ] **Step 4: Run focused tests and verify GREEN**

Run: `flutter test test/game/combat_playtest_tracker_test.dart test/game/run_telemetry_test.dart test/game/run_stats_tracker_test.dart test/game/pixel_survivor_game_loop_test.dart test/app/game_screen_telemetry_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add -- lib/game/models/combat_playtest_metrics.dart lib/game/systems/combat_playtest_tracker.dart lib/game/models/run_result.dart lib/game/models/run_telemetry.dart lib/game/systems/run_stats_tracker.dart lib/game/pixel_survivor_game.dart docs/telemetry/run-telemetry-schema.md test/game/combat_playtest_tracker_test.dart test/game/run_telemetry_test.dart test/game/run_stats_tracker_test.dart test/game/pixel_survivor_game_loop_test.dart test/app/game_screen_telemetry_test.dart
git diff --cached --check
git commit -m "feat: record combat mastery playtest metrics"
```

### Task 11: Record repeat runs and show bounded combat notices

**Files:**
- Create: `lib/game/systems/playtest_session_repository.dart`
- Create: `test/game/playtest_session_repository_test.dart`
- Modify: `lib/app/game_hud_source.dart`
- Modify: `lib/app/game_hud.dart`
- Modify: `lib/app/game_screen.dart`
- Modify: `lib/app/pixel_survivor_app.dart`
- Test: `test/app/game_hud_test.dart`
- Test: `test/app/repeated_run_lifecycle_test.dart`

**Interfaces:**
- Produces: `Future<int> PlaytestSessionRepository.beginRun()` returning 1-based run ordinal.
- Adds HUD getters: `combatNotice`, `combatNoticeSecondsRemaining`, `killStreak`.

- [ ] **Step 1: Write failing repository and HUD tests**

```dart
test('second begun run is reported as repeat play', () async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final repository = PlaytestSessionRepository(preferences: preferences);
  expect(await repository.beginRun(), 1);
  expect(await repository.beginRun(), 2);
});

testWidgets('combat notice does not cover boss warning and expires', (tester) async {
  final source = FakeHudSource(combatNotice: '봉마참', combatNoticeSecondsRemaining: 1.2);
  await tester.pumpWidget(MaterialApp(home: GameHud(source: source)));
  expect(find.text('봉마참'), findsOneWidget);
  expect(tester.getTopLeft(find.text('봉마참')).dy, greaterThan(80));
});
```

- [ ] **Step 2: Run and verify RED**

Run: `flutter test test/game/playtest_session_repository_test.dart test/app/game_hud_test.dart test/app/repeated_run_lifecycle_test.dart`

Expected: FAIL because the repository and HUD contract are absent.

- [ ] **Step 3: Implement run ordinal and bounded notices**

Persist only an integer playtest run count in a new key; do not touch `SaveState`. Pass `ordinal > 1` into `CombatPlaytestTracker`. Add one centered notice below boss/status warnings and a small kill-streak label; refresh through the existing HUD timer and hide when remaining time reaches zero.

- [ ] **Step 4: Run focused tests and verify GREEN**

Run: `flutter test test/game/playtest_session_repository_test.dart test/app/game_hud_test.dart test/app/repeated_run_lifecycle_test.dart test/app/responsive_layout_test.dart`

Expected: PASS with no portrait overflow.

- [ ] **Step 5: Commit**

```powershell
git add -- lib/game/systems/playtest_session_repository.dart lib/app/game_hud_source.dart lib/app/game_hud.dart lib/app/game_screen.dart lib/app/pixel_survivor_app.dart test/game/playtest_session_repository_test.dart test/app/game_hud_test.dart test/app/repeated_run_lifecycle_test.dart test/app/responsive_layout_test.dart
git diff --cached --check
git commit -m "feat: surface combat notices and repeat-run metric"
```

### Task 12: Add aggregate reporting and the actual-play checklist

**Files:**
- Modify: `lib/game/systems/telemetry_export_service.dart`
- Modify: `docs/testing/local-playtest.md`
- Create: `docs/testing/combat-mastery-vertical-slice-report.md`
- Test: `test/game/telemetry_export_service_test.dart`

**Interfaces:**
- Produces: aggregate mastery versus non-mastery win rates and damage shares from exported runs.
- Consumes: schema 1 and schema 2 telemetry records.

- [ ] **Step 1: Write a failing aggregate report test**

```dart
test('aggregate separates mastered and non-mastered win rates', () {
  final report = TelemetryExportService().aggregate([masterWin, masterLoss, noMasterLoss]);
  expect(report.masteredRunWinRate, .5);
  expect(report.nonMasteredRunWinRate, 0);
  expect(report.synergyDamageShare, closeTo(.2, .0001));
});
```

- [ ] **Step 2: Run and verify RED**

Run: `flutter test test/game/telemetry_export_service_test.dart`

Expected: FAIL because mastery aggregates are absent.

- [ ] **Step 3: Implement aggregation and write the manual checklist**

Add typed aggregate fields for weapon offer/selection rates, weapon damage shares, master timing, ten-second kills, synergy timing/share, enemy-role damage/death causes, density, late FPS, mastery win split, and repeat-run rate. Keep raw CSV/JSON export intact.

Write the approved twelve manual questions covering silhouette readability, each weapon's visible transition points, mastery hero moment, Sealing Slash identity, enemy warning visibility, ranged/charge/defense decisions, 240-270-second horde clearing, non-master survivability, feedback comfort, accessibility, and second-run intent. Leave observed-result cells as unchecked checkboxes, not invented evidence.

- [ ] **Step 4: Run exporter tests and documentation checks**

Run: `flutter test test/game/telemetry_export_service_test.dart test/game/run_telemetry_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add -- lib/game/systems/telemetry_export_service.dart docs/testing/local-playtest.md docs/testing/combat-mastery-vertical-slice-report.md test/game/telemetry_export_service_test.dart
git diff --cached --check
git commit -m "feat: report combat mastery playtest outcomes"
```

### Task 13: Run the complete verification gate and record evidence

**Files:**
- Modify: `docs/testing/combat-mastery-vertical-slice-report.md`
- Modify only if a regression is reproduced by a new failing test: the responsible source and test files.

**Interfaces:**
- Consumes: all prior task deliverables.
- Produces: dated command, exit code, test count, build artifact path, fixed-seed density/performance values, and unresolved manual checks.

The four mandatory Flutter gates are `flutter analyze`, `flutter test`, `flutter build web`, and `flutter build apk --debug`; the ASCII commands below are path-safe equivalents of those exact gates.

- [ ] **Step 1: Review repository state and formatting without discarding changes**

Run:

```powershell
git status --short
git diff --check
dart format --output=none --set-exit-if-changed lib test
```

Expected: no whitespace errors and no Dart formatting changes. If formatting is needed, run `dart format` only on files changed by this plan and re-run focused tests.

- [ ] **Step 2: Run static analysis through temporary ASCII drives**

```powershell
$repoPath=(Resolve-Path '.').Path
$flutterPath='C:\Users\전성진\source\flutter'
subst Y: $flutterPath
subst Z: $repoPath
try { Push-Location Z:\; & Y:\bin\flutter.bat analyze; if($LASTEXITCODE){exit $LASTEXITCODE} } finally { Pop-Location; subst Z: /D; subst Y: /D }
```

Expected: `No issues found!`

- [ ] **Step 3: Run every Flutter test**

Use the same ASCII mapping and run: `Y:\bin\flutter.bat test -r compact`

Expected: exit 0 and `All tests passed!` Record the exact test count from fresh output.

- [ ] **Step 4: Build web release**

Use the same ASCII mapping and run: `Y:\bin\flutter.bat build web`

Expected: exit 0 and `build/web` generated.

- [ ] **Step 5: Build Android debug APK**

Use `tool/release_check.ps1 -IncludeAndroid` or equivalent ASCII mappings for repository, Flutter SDK, and a non-ASCII Android SDK path.

Run inside the mapped repository: `Y:\bin\flutter.bat build apk --debug`

Expected: exit 0 and `build/app/outputs/flutter-apk/app-debug.apk` generated.

- [ ] **Step 6: Re-run the fixed-seed five-minute slice tests**

Run: `flutter test test/game/five_minute_run_simulation_test.dart test/game/five_minute_performance_development_log_test.dart test/game/multi_seed_run_regression_test.dart`

Expected: no population/memory violations, one boss request, nonzero late mixed-role population, and telemetry values for average/max enemies and late average/min FPS.

- [ ] **Step 7: Update the result report with evidence only**

Record actual command timestamps, exit codes, test counts, build paths, simulation measurements, and any manual checks that remain for the user. Do not mark subjective fun or device FPS as passed from host automation.

- [ ] **Step 8: Commit the verification report**

```powershell
git add -- docs/testing/combat-mastery-vertical-slice-report.md
git diff --cached --check
git commit -m "docs: record combat mastery slice verification"
```

---

## Execution Order and Checkpoints

1. Tasks 1-3 establish policy, art contract, shared attack data, and six-level content.
2. Tasks 4-5 complete and visually validate hwando mastery before talisman implementation begins.
3. Tasks 6-7 add talisman mastery and Sealing Slash only after hwando focused tests are green.
4. Tasks 8-9 add the four-role enemy mix and late pressure.
5. Tasks 10-12 connect metrics, UI, repeat-run evidence, exports, and manual QA.
6. Task 13 is the fresh completion gate; no completion claim precedes it.

After Task 5, run a browser/mobile preview and inspect only attack direction, hit alignment, master scale, enemy warning visibility, and frame stability. If the hwando master scene is not visibly different from level 5, adjust its sequence and presentation before starting Task 6; do not compensate by adding weapons.
