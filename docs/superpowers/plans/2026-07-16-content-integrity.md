# Content Integrity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a reusable pure content-integrity report and deterministic production-rule tests proving three distinct valid builds.

**Architecture:** `content_integrity.dart` aggregates immutable catalog definitions and existing specialist validators into stable issue strings without touching the filesystem or game boot. Tests inject the repository's bundled asset paths and use real progression, level-up, and weapon systems for build viability.

**Tech Stack:** Dart 3.12, Flutter test, Flame content models

## Global Constraints

- Validate exactly 3 characters, 8 weapons with 5 levels each, 16 augments, 8 normal enemies, 3 elites, 2 stages, 3 bosses, and 15 unlock goals.
- Validate ID uniqueness, references, unlock coverage, stage rosters, bosses, audio, and asset contracts.
- Prove at least three role-distinct builds through actual unlock and level-selection rules.
- Keep validation pure and out of runtime boot.
- Do not modify app, settings, QA, or `docs/master-development-todo.md` files.

---

### Task 1: Aggregate content integrity report

**Files:**
- Create: `lib/game/content/content_integrity.dart`
- Modify: `lib/game/content/asset_catalog.dart`
- Modify: `test/game/content_definitions_test.dart`
- Create: `test/game/content_integrity_test.dart`

**Interfaces:**
- Consumes: existing character, weapon, level, augment, enemy, stage, wave, boss, unlock, image, and audio catalogs.
- Produces: `ContentIntegrityReport`, `validateContentIntegrity({Set<String> bundledImagePaths})`.

- [ ] **Step 1: Write failing aggregate and malformed-catalog tests**

Add tests asserting the production report has the exact roster counts and no issues, and that injectable duplicate/missing references produce stable diagnostics. Add asset assertions requiring every roster ID to resolve to a bundled safe image path and every audio cue to resolve to a channel-compatible catalog path.

- [ ] **Step 2: Run tests to verify RED**

Run:

```powershell
A:\bin\flutter.bat test -r compact test/game/content_definitions_test.dart test/game/content_integrity_test.dart
```

Expected: compile failure because `content_integrity.dart`, `ContentIntegrityReport`, and `validateContentIntegrity` do not exist.

- [ ] **Step 3: Implement the minimal pure report**

Create a report with immutable `issues`, typed count getters, and `isValid`. Implement deterministic helpers for duplicate IDs, positive finite tuning, cross references, unlock reward coverage, wave/boss aggregation, asset key/path coverage, and audio path/channel coverage. Fill absent image catalog slots with existing bundled replaceable assets so all runtime-facing keys resolve.

- [ ] **Step 4: Run focused tests to verify GREEN**

Run the Step 2 command and require all tests to pass with no warnings.

- [ ] **Step 5: Commit**

```powershell
git add lib/game/content/content_integrity.dart lib/game/content/asset_catalog.dart test/game/content_definitions_test.dart test/game/content_integrity_test.dart
git commit -m "feat: audit complete content integrity"
```

### Task 2: Production-rule build viability

**Files:**
- Create: `test/game/content_build_viability_test.dart`
- Modify: `lib/game/content/content_integrity.dart` only if a small public combat-signature value is required by the test.

**Interfaces:**
- Consumes: `SaveState.defaults`, `ProgressionSystem.evaluate`, `LevelUpSystem.choices`, `WeaponSystem.upgrade`, weapon definitions, and level-five tuning.
- Produces: deterministic evidence for frontline-control, ranged-focus, and area-attrition builds.

- [ ] **Step 1: Write failing rule-driven build tests**

Create a fixed fully-qualified progression snapshot, evaluate it through `ProgressionSystem`, and assert target content is unlocked. For each build, repeatedly request production `LevelUpChoice` values with fixed random seeds, apply only offered target choices, and use `WeaponSystem.upgrade` to reach exact requested weapon levels. Derive and compare combat signatures using range, element, projectile/chain count, knockback, and duration.

- [ ] **Step 2: Run tests to verify RED**

Run:

```powershell
A:\bin\flutter.bat test -r compact test/game/content_build_viability_test.dart
```

Expected: at least one explicit viability assertion fails before the bounded builder/helper is completed.

- [ ] **Step 3: Implement the minimal deterministic builder or signature helper**

Add only the helper code needed to drive real systems: bounded seeded choice rounds, choice application maps, and a derived role signature. Do not replace production choices with direct target-level assignment.

- [ ] **Step 4: Run content tests to verify GREEN**

Run:

```powershell
A:\bin\flutter.bat test -r compact test/game/content_definitions_test.dart test/game/content_integrity_test.dart test/game/content_build_viability_test.dart
```

Expected: all content integrity and build viability tests pass.

- [ ] **Step 5: Commit**

```powershell
git add test/game/content_build_viability_test.dart lib/game/content/content_integrity.dart
git commit -m "test: prove three viable combat builds"
```

### Task 3: Verification and handoff

**Files:**
- Create: `docs/superpowers/verification/2026-07-16-content-integrity.md`

**Interfaces:**
- Consumes: completed implementation and test suite.
- Produces: exact reproducible validation evidence and a clean reviewable branch.

- [ ] **Step 1: Format and inspect scope**

Run `dart format` on owned Dart files, `git diff --check`, and confirm no app/settings/QA/master TODO paths changed.

- [ ] **Step 2: Run fresh verification**

From ASCII-mapped SDK and worktree paths with isolated `TEMP`, `TMP`, and `PUB_CACHE`, run:

```powershell
dart analyze
flutter test -r compact test/game/content_definitions_test.dart test/game/content_integrity_test.dart test/game/content_build_viability_test.dart
flutter test -r compact
flutter build web
```

Require exit code 0 for every command; use `flutter clean` first if the known Windows shader bundle cache is stale.

- [ ] **Step 3: Write verification record**

Record commands, exit codes, test counts, roster counts, build role evidence, and any environmental workaround in the verification document.

- [ ] **Step 4: Review and commit**

Run `git diff --check`, inspect the full branch diff, commit the verification record, and report commit SHAs plus residual risks for cross-review.
