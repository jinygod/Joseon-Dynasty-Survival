# Content Integrity Review Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close every Critical and Important content-audit review finding with deterministic, production-rule build viability and fully injected, non-throwing integrity validation.

**Architecture:** Keep the aggregate validator pure by validating only the catalogs passed to it and by moving the approved exact roster into one immutable contract. Specialized enemy, wave, and boss validators accept injected definitions. Build viability starts from the selected character's real level-one weapon and applies exactly one offered choice per level.

**Tech Stack:** Dart, Flutter test, existing content definitions and progression/level-up systems.

## Global Constraints

- Preserve deterministic issue ordering and accumulate malformed-catalog issues instead of throwing.
- Use `SaveState.defaults()` as the source of initially unlocked IDs.
- Every simulated level-up applies one of the production `LevelUpSystem.choices` results; no reroll, skip, or free continuation.
- Keep unrelated roadmap, settings, boss, and QA files unchanged.

---

### Task 1: Injected validator regressions

**Files:**
- Modify: `test/game/content_integrity_test.dart`
- Modify: `lib/game/content/enemy_definitions.dart`
- Modify: `lib/game/content/wave_definitions.dart`
- Modify: `lib/game/content/boss_definitions.dart`
- Modify: `lib/game/content/content_integrity.dart`

**Interfaces:**
- `validateEnemyContent([Iterable<EnemyDefinition> definitions])`
- `validateWaveContent({required Map<String, List<WaveDefinition>> stageWaves, required Iterable<EnemyDefinition> enemies})`
- `validateBossDefinitions(Iterable<BossDefinition>, {required Iterable<EnemyDefinition> enemies})`

- [ ] Add malformed injected enemy, wave, and boss tests, including a wave ending before boss arrival/target.
- [ ] Run `flutter test test/game/content_integrity_test.dart` and confirm the new assertions fail because production globals are still read.
- [ ] Parameterize the specialized validators and aggregate stage/boss checks so only injected values are read.
- [ ] Re-run the focused test and confirm it passes.

### Task 2: Exact roster and safe unlock contract

**Files:**
- Create: `lib/game/content/content_roster_contract.dart`
- Modify: `lib/game/content/ids.dart`
- Modify: `lib/game/content/content_integrity.dart`
- Modify: `test/game/content_integrity_test.dart`

**Interfaces:**
- `ContentRosterContract` exposes approved character, weapon, augment, enemy, stage, boss, unlock-goal, and stage-boss ID sets.
- Unlock validation reads the four nullable reward fields directly and compares against `SaveState.defaults()` unlocked sets.

- [ ] Add tests that replace a planned ID without changing counts, inject zero/multiple reward fields, and add orphan asset keys.
- [ ] Run the focused test and confirm exact-ID and reward-cardinality assertions fail.
- [ ] Add the central exact-ID contract, remove constructor-time reward cardinality assertion, and accumulate safe validation issues from raw fields.
- [ ] Add orphan asset diagnostics and re-run the focused test to green.

### Task 3: Legal deterministic build viability

**Files:**
- Modify: `test/game/content_build_viability_test.dart`

**Interfaces:**
- `_constructBuild` initializes the character starting weapon through `WeaponSystem.upgrade` and selects one offered production choice on every iteration.
- `_ConstructedBuild` records applied choices and rounds while target maps are treated as required subsets.

- [ ] Rewrite the test expectations to require the real starting weapon at level one, exactly one application per offered round, and target-role completion without skipped offers.
- [ ] Run `flutter test test/game/content_build_viability_test.dart` and confirm the old helper fails the new legality assertions.
- [ ] Implement deterministic target-first selection with the first offered choice as the legal fallback.
- [ ] Re-run the focused build test and confirm all three roles pass.

### Task 4: Verification and evidence

**Files:**
- Modify: `docs/superpowers/verification/2026-07-16-content-integrity.md`

- [ ] Run `dart format` on changed Dart files and `git diff --check`.
- [ ] Run focused content tests.
- [ ] Run full `dart analyze`, `flutter test --concurrency=1`, and `flutter build web --release` using ASCII drive mappings if required.
- [ ] Record exact fresh results in the verification document.
- [ ] Review the final diff for unrelated changes and commit the complete remediation.
