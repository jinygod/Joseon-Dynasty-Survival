# Combat Performance, Cleanup, and Verification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Use superpowers:verification-before-completion before reporting completion. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Measure the completed visual overhaul honestly, optimize only proven bottlenecks, audit safe cleanup candidates, review the final diff once, and perform one final validation pass.

**Architecture:** Keep deterministic host simulation for logic/population comparisons and add a separate Chrome profile harness for real frame timing. Introduce explicit population indexes only where repeated root scans are measured, retain static sprite batches, and audit all deletion candidates before any removal.

**Tech Stack:** Flutter profile web, Dart/Flame instrumentation, Chrome DevTools frame timing, `flutter_test`, PowerShell verification.

## Global Constraints

- Run this plan after the other three plans pass their exit gates.
- Label fixed-`dt` results as logical FPS, never device or render FPS.
- Do not claim mobile performance without a real device run.
- Preserve balance and deterministic run outputs.
- Optimize in this order: preload, repeated root scans, duplicate VFX, retained owners, static batching, cached render objects.
- Add spatial partitioning or large pools only if before/after measurements show the relevant loop is a p95 or p99 bottleneck.
- Do not delete ambiguous assets, generated sources, or rights records.
- Reviewer runs once after the integrated final diff; main Sol runs final validation once after review fixes.
- Default concurrent subagents: 2; maximum 3 for independent read-only work; all models explicit and none use Sol.

---

### Task 1: Separate Logical and Render Performance Reports

**Files:**
- Create: `lib/game/performance/chrome_frame_profile.dart`
- Create: `test/game/chrome_frame_profile_test.dart`
- Modify: `lib/game/performance/performance_development_reporter.dart`
- Modify: `docs/testing/five-minute-performance-development-log.md`
- Create: `docs/testing/combat-visual-profile-procedure.md`
- Test: `test/game/performance_development_log_test.dart`

**Interfaces:**
- Consumes: frame durations, build/raster durations, image load events, component counts.
- Produces: p50/p95/p99, counts above 33ms/50ms, and clearly labeled logical/render reports.

- [ ] **Step 1: Write failing percentile and label tests**

```dart
test('profile reports percentiles and long frames', () {
  final profile = ChromeFrameProfile.fromMilliseconds(
    [8, 16, 17, 34, 51],
  );
  expect(profile.p50Ms, 17);
  expect(profile.framesOver33Ms, 2);
  expect(profile.framesOver50Ms, 1);
});

test('host report labels fixed dt as logical FPS', () {
  expect(report.toMarkdown(), contains('logical FPS'));
  expect(report.toMarkdown(), isNot(contains('device FPS')));
});
```

- [ ] **Step 2: Verify failure**

Run: `flutter test test/game/chrome_frame_profile_test.dart test/game/performance_development_log_test.dart`

Expected: profile type is absent or old report label assertion fails.

- [ ] **Step 3: Implement metrics**

Sort a copied duration list, use nearest-rank indexes for p50/p95/p99, count strict `>33` and `>50`, and keep build/raster series separate. Include first image-load timestamps and component create/remove rates as optional named series.

- [ ] **Step 4: Write exact profile procedure**

Document a 60–90 second Chrome profile run using seed 3107, release-like profile mode, a warm restart followed by a cold first-combat run, collection of Flutter frame timings, and export paths under `build/qa/combat-visual-profile/`. State that the existing shader compiler SIGSEGV occurs before app code and is an environment failure.

- [ ] **Step 5: Run and commit**

Run: `flutter test test/game/chrome_frame_profile_test.dart test/game/performance_development_log_test.dart`

Expected: percentile math and terminology tests pass.

```powershell
git add lib/game/performance/chrome_frame_profile.dart lib/game/performance/performance_development_reporter.dart test/game/chrome_frame_profile_test.dart test/game/performance_development_log_test.dart docs/testing/five-minute-performance-development-log.md docs/testing/combat-visual-profile-procedure.md
git commit -m "test: separate logical and render performance metrics"
```

### Task 2: Eliminate Repeated Root Population Scans

**Files:**
- Create: `lib/game/performance/game_population_index.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Test: `test/game/game_population_index_test.dart`
- Test: `test/game/game_performance_budget_test.dart`

**Interfaces:**
- Consumes: component add/remove events for enemies, projectiles, damage numbers, combat effects.
- Produces: constant-time counts and typed read-only views where needed.

- [ ] **Step 1: Write failing index tests**

```dart
test('population index tracks add and remove exactly once', () {
  final index = GamePopulationIndex();
  index.add(enemy);
  index.add(enemy);
  expect(index.enemyCount, 1);
  index.remove(enemy);
  index.remove(enemy);
  expect(index.enemyCount, 0);
});
```

- [ ] **Step 2: Verify failure**

Run: `flutter test test/game/game_population_index_test.dart`

Expected: index type is absent.

- [ ] **Step 3: Implement identity-backed sets**

```dart
class GamePopulationIndex {
  final Set<EnemyComponent> _enemies = HashSet.identity();
  final Set<ProjectileComponent> _projectiles = HashSet.identity();

  int get enemyCount => _enemies.length;
  Iterable<EnemyComponent> get enemies => _enemies;

  void add(Component component) {
    if (component is EnemyComponent) _enemies.add(component);
    if (component is ProjectileComponent) _projectiles.add(component);
  }

  void remove(Component component) {
    if (component is EnemyComponent) _enemies.remove(component);
    if (component is ProjectileComponent) _projectiles.remove(component);
  }
}
```

Extend the same pattern only to currently budgeted types. Hook registration into the game-owned creation/removal callbacks, not arbitrary component tree traversal.

- [ ] **Step 4: Replace measured count scans**

Replace `_enemyComponentCount` and corresponding projectile/effect count scans used by spawn/budget logic with index counts. Keep a test-only consistency assertion comparing the index to `children.whereType` after lifecycle settling.

- [ ] **Step 5: Run and commit**

Run: `flutter test test/game/game_population_index_test.dart test/game/game_performance_budget_test.dart test/game/pixel_survivor_game_loop_test.dart test/game/five_minute_run_simulation_test.dart`

Expected: counts remain identical and deterministic run outputs pass.

```powershell
git add lib/game/performance/game_population_index.dart lib/game/pixel_survivor_game.dart test/game/game_population_index_test.dart test/game/game_performance_budget_test.dart
git commit -m "perf: index active combat populations"
```

### Task 3: Measure Retained Owners and Render Allocations

**Files:**
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `lib/game/components/hwando_vfx_component.dart`
- Modify: `lib/game/components/area_vfx_component.dart`
- Modify: `lib/game/components/projectile_vfx_component.dart`
- Test: `test/game/game_performance_budget_test.dart`
- Test: `test/game/pixel_survivor_game_loop_test.dart`

**Interfaces:**
- Consumes: all game-owned maps/sets and completed VFX.
- Produces: complete retained-owner count, cached sprites/paints/paths, and zero post-expiry references.

- [ ] **Step 1: Add failing retained-owner assertions**

```dart
expect(game.performanceRetainedOwnerBreakdown.keys, contains(
  'talismanAttachments',
));
expect(game.performanceRetainedOwnerBreakdown.values.reduce((a, b) => a + b),
    game.performanceRetainedOwnerCount);
```

After expiry, assert the corresponding attack ID is absent from all owner collections.

- [ ] **Step 2: Verify old accounting fails**

Run: `flutter test test/game/game_performance_budget_test.dart test/game/pixel_survivor_game_loop_test.dart`

Expected: talisman ownership is missing from breakdown or stale references remain.

- [ ] **Step 3: Complete owner accounting**

Expose an immutable string-to-count breakdown for `_lastWeaponHitByEnemy`, `_recordedEnemyDefeats`, `_pendingSpiritJadeDrops`, `_talismanAttachmentComponents`, active attack tracking, and other production owner collections already counted in the scalar proxy.

- [ ] **Step 4: Cache render objects**

Create `Sprite` instances once from preloaded images. Reuse immutable or component-owned `Paint` and stable `Path` objects where geometry does not change. Do not cache paths whose size/direction changes without a keyed invalidation rule.

- [ ] **Step 5: Run and commit**

Run: `flutter test test/game/game_performance_budget_test.dart test/game/pixel_survivor_game_loop_test.dart test/game/hwando_vfx_component_test.dart test/game/combat_visual_factory_test.dart`

Expected: owner counts return to baseline and VFX lifetime tests pass.

```powershell
git add lib/game/pixel_survivor_game.dart lib/game/components/hwando_vfx_component.dart lib/game/components/area_vfx_component.dart lib/game/components/projectile_vfx_component.dart test/game/game_performance_budget_test.dart test/game/pixel_survivor_game_loop_test.dart
git commit -m "perf: account for retained combat visual owners"
```

### Task 4: Remeasure and Gate Further Optimization

**Files:**
- Modify: `docs/testing/five-minute-performance-development-log.md`
- Create: `docs/testing/combat-visual-performance-report.md`
- Modify: `test/game/five_minute_performance_development_log_test.dart` only if instrumentation fields changed

**Interfaces:**
- Consumes: same seed 3107 host run and 60–90 second Chrome profile.
- Produces: before/after table and an evidence-based decision on collision/aura optimization.

- [ ] **Step 1: Run the deterministic host profile**

Run: `flutter test test/game/five_minute_performance_development_log_test.dart -r expanded`

Expected: either PASS with 18,000 frames and complete metrics, or the known pre-app shader compiler failure recorded verbatim as environment-blocked.

- [ ] **Step 2: Run the Chrome profile procedure**

Run the exact commands documented in `docs/testing/combat-visual-profile-procedure.md`, capture p50/p95/p99, >33ms/>50ms, build/raster, first image events, and component rates.

- [ ] **Step 3: Write the before/after report**

Include baseline 6,318µs peak host update+lifecycle, enemy counts 15.68/51 and late 27.24/51, new values, environment, seed, build mode, and sample duration. Mark unavailable values as `not measured` with the blocking reason rather than estimating them.

- [ ] **Step 4: Apply the decision rule**

If projectile×enemy or aura traversal occupies a measured p95/p99 hot section, create a separately reviewed spatial-index task before changing it. If it does not, explicitly record “no spatial partition added” and keep the simpler code.

- [ ] **Step 5: Commit**

```powershell
git add docs/testing/five-minute-performance-development-log.md docs/testing/combat-visual-performance-report.md test/game/five_minute_performance_development_log_test.dart
git commit -m "docs: report combat visual performance"
```

### Task 5: Audit Assets, Old Paths, and UI Art Gaps

**Files:**
- Create: `docs/assets/combat-visual-cleanup-audit.csv`
- Create: `docs/assets/ui-art-gap-audit.md`
- Modify: no runtime files in this task
- Test: `test/game/content_integrity_test.dart`

**Interfaces:**
- Consumes: `rg` static references, dynamic path patterns, `pubspec`, tests, docs, SHA-256 inventory.
- Produces: explicit `keep`, `safe-delete`, and `defer` classifications.

- [ ] **Step 1: Inventory candidates**

For every old effect, stage temporary atlas mapping, duplicated enemy path, and geometric renderer, record path/symbol, SHA-256 when a file exists, static references, dynamic reference risk, `pubspec` coverage, replacement, and classification.

- [ ] **Step 2: Scan references**

Run:

```powershell
rg -n "weapon_effects_atlas_64|combat_effects_atlas_64|hwando_slash_effect_64|AttackEffectComponent|MeleeArcComponent|drawArc|drawCircle|drawLine|drawPath" lib test docs pubspec.yaml
```

Expected: every match is represented in the audit or explicitly identified as an allowed debug/auxiliary use.

- [ ] **Step 3: Audit UI art gaps**

Classify lobby, HUD, panels, buttons, icons, backgrounds, warnings, and status markers as `complete`, `image-unconnected`, `temporary-image`, `primary-geometry`, or `auxiliary-geometry-allowed`. Include exact file paths and symbols.

- [ ] **Step 4: Validate audit completeness**

Run: `flutter test test/game/content_integrity_test.dart`

Expected: PASS; this task performs no deletion and changes no runtime behavior.

- [ ] **Step 5: Commit**

```powershell
git add docs/assets/combat-visual-cleanup-audit.csv docs/assets/ui-art-gap-audit.md
git commit -m "docs: audit combat visual cleanup and UI gaps"
```

### Task 6: Remove Only Proven-Safe Legacy Files and Code

**Files:**
- Modify/Delete: only entries classified `safe-delete` in `docs/assets/combat-visual-cleanup-audit.csv`
- Modify: `pubspec.yaml`
- Modify: `lib/game/content/asset_catalog.dart`
- Modify: `lib/game/content/sprite_atlas_contract.dart`
- Test: `test/game/content_integrity_test.dart`
- Test: `test/game/sprite_atlas_contract_test.dart`

**Interfaces:**
- Consumes: reviewed cleanup audit.
- Produces: no unreferenced legacy runtime path and no silent normal-path fallback.

- [ ] **Step 1: Present material deletion list**

Before deleting source art, multiple runtime atlases, or any ambiguous file, stop and request user approval with exact paths and recovery status. Continue without a new prompt only for code branches and files explicitly classified safe and non-material in the reviewed audit.

- [ ] **Step 2: Remove approved targets**

Use exact literal paths. Remove catalog and atlas contracts in the same change as their approved files. Keep generated originals and ledger history.

- [ ] **Step 3: Prove no references remain**

Run the audit `rg` command again and:

```powershell
flutter test test/game/content_integrity_test.dart test/game/sprite_atlas_contract_test.dart test/game/asset_rights_policy_test.dart
git diff --check
```

Expected: no deleted path is referenced and all tests pass.

- [ ] **Step 4: Commit**

```powershell
git add -A -- assets/images lib/game/content pubspec.yaml docs/assets/combat-visual-cleanup-audit.csv test/game/content_integrity_test.dart test/game/sprite_atlas_contract_test.dart
git commit -m "refactor: remove superseded combat visual paths"
```

### Task 7: One Final Review and Validation Pass

**Files:**
- Modify: only files required by reviewer findings
- Create: `docs/testing/combat-visual-final-verification.md`

**Interfaces:**
- Consumes: integrated final diff against commit `190ede3`.
- Produces: one reviewer report, fixed findings, and final command evidence.

- [ ] **Step 1: Run the reviewer once**

Dispatch the project `reviewer` role explicitly on `gpt-5.6-terra`, read-only, high reasoning, against the complete diff. Ask only for functional bugs, regressions, state leaks, wrong asset paths, and missing tests. Do not ask it to implement.

- [ ] **Step 2: Resolve findings centrally**

Main Sol verifies every finding against code and tests, applies valid fixes, and records rejected findings with evidence. Do not dispatch the reviewer a second time.

- [ ] **Step 3: Run final formatting and static analysis once**

```powershell
dart format --output=none --set-exit-if-changed lib test
git diff --check
flutter analyze
```

Expected: all commands exit 0.

- [ ] **Step 4: Run the full test suite once**

Run: `flutter test -r compact`

Expected: exit 0. If the known shader compiler SIGSEGV occurs before app code, record the exact failure and run the unaffected focused groups; do not label the full suite passed.

- [ ] **Step 5: Build web once**

Run: `flutter build web --release`

Expected: exit 0 and `build/web` exists. Do not run Android or iOS builds.

- [ ] **Step 6: Write final verification evidence**

Record commit range, reviewer findings, exact commands, exit codes, test counts, web artifact path, performance report link, manual VFX gallery checks, known environment failures, and any user-deferred deletions.

- [ ] **Step 7: Commit**

```powershell
git add docs/testing/combat-visual-final-verification.md
git commit -m "test: verify combat visual overhaul"
```

## Program Exit Gate

- Every design completion criterion is mapped to evidence in the final verification report.
- Main model remains `gpt-5.6-sol`; every actual subagent invocation names Terra or Luna explicitly.
- Reviewer ran exactly once after integration.
- `flutter analyze`, full tests, and web build were each attempted exactly once in the final pass, with honest status.
- No balance change or unapproved material deletion is present.
