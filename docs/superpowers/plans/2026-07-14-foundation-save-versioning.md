# Foundation Save Versioning Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an explicit save schema version, preserve versionless alpha saves, reject unsafe future or malformed schemas, and document the app version policy.

**Architecture:** `SaveState` owns the current schema number and performs a single boundary migration when decoding JSON. Missing `schemaVersion` is the legacy schema 0 and is read with the existing field fallbacks; schema 1 is current; invalid, negative, or future versions return `SaveState.defaults()`. `SaveSystem` continues to isolate JSON parse failures and uses the same shared-preferences key, so existing installations remain readable.

**Tech Stack:** Dart 3.12.2, Flutter 3.44.4, `shared_preferences`, `flutter_test`

## Global Constraints

- Android remains the primary 1.0 platform.
- The game remains offline and stores progression locally.
- The existing shared-preferences key stays `save_state`.
- The current schema version is exactly `1`.
- A missing `schemaVersion` means legacy schema `0` and must preserve valid existing fields.
- Negative, non-integer, and greater-than-1 schema versions must return defaults without throwing.
- No new runtime dependency is allowed for this milestone.
- Every behavior change starts with a failing test.

---

### Task 1: Persist schema version 1 and migrate versionless saves

**Files:**
- Modify: `lib/game/systems/save_system.dart`
- Test: `test/game/save_system_test.dart`

**Interfaces:**
- Consumes: Existing `SaveState.defaults()`, `SaveState.copyWith()`, `SaveState.toJson()`, and `SaveState.fromJson()`.
- Produces: `SaveState.currentSchemaVersion`, `SaveState.schemaVersion`, JSON field `schemaVersion`, and versionless schema 0 migration.

- [ ] **Step 1: Add failing serialization and legacy migration tests**

Append inside `main()` in `test/game/save_system_test.dart`:

```dart
  test('save state writes the current schema version', () {
    final state = SaveState.defaults();

    expect(SaveState.currentSchemaVersion, 1);
    expect(state.schemaVersion, SaveState.currentSchemaVersion);
    expect(state.toJson()['schemaVersion'], SaveState.currentSchemaVersion);
  });

  test('versionless alpha save migrates to schema one', () {
    final restored = SaveState.fromJson({
      'unlockedCharacterIds': [rookieConstable, exorcistDosa],
      'unlockedWeaponIds': [hwandoSlash, gakgungShot, talismanThrow],
      'unlockedAugmentIds': [martialTraining, rapidReload],
      'completedGoalIds': ['survive_3_minutes'],
      'totalKills': 321,
      'bestSurvivalSeconds': 240,
      'levelReachedInRun': 12,
      'bossDefeats': 2,
      'unlockedWeaponCount': 4,
      'lowHealthWinCount': 1,
    });

    expect(restored.schemaVersion, SaveState.currentSchemaVersion);
    expect(restored.totalKills, 321);
    expect(restored.bestSurvivalSeconds, 240);
    expect(restored.unlockedCharacterIds, contains(exorcistDosa));
    expect(restored.unlockedWeaponIds, contains(talismanThrow));
    expect(restored.unlockedAugmentIds, contains(rapidReload));
    expect(restored.completedGoalIds, contains('survive_3_minutes'));
  });
```

- [ ] **Step 2: Run the focused test and confirm failure**

Run:

```powershell
$env:Path = "$env:USERPROFILE\source\flutter\bin;$env:Path"
flutter test test/game/save_system_test.dart --plain-name "save state writes the current schema version"
```

Expected: compilation fails because `currentSchemaVersion` and `schemaVersion` do not exist.

- [ ] **Step 3: Add the schema field to `SaveState`**

In `lib/game/systems/save_system.dart`, change the beginning of `SaveState` to:

```dart
class SaveState {
  SaveState({
    this.schemaVersion = currentSchemaVersion,
    required Set<String> unlockedCharacterIds,
    required Set<String> unlockedWeaponIds,
    required Set<String> unlockedAugmentIds,
    required Set<String> completedGoalIds,
    required this.totalKills,
    required this.bestSurvivalSeconds,
    required this.levelReachedInRun,
    required this.bossDefeats,
    required this.unlockedWeaponCount,
    required this.lowHealthWinCount,
  }) : unlockedCharacterIds = Set.unmodifiable(unlockedCharacterIds),
       unlockedWeaponIds = Set.unmodifiable(unlockedWeaponIds),
       unlockedAugmentIds = Set.unmodifiable(unlockedAugmentIds),
       completedGoalIds = Set.unmodifiable(completedGoalIds);

  static const currentSchemaVersion = 1;
```

Add the field before the unlock fields:

```dart
  final int schemaVersion;
```

Add `schemaVersion` to `copyWith` and preserve it:

```dart
  SaveState copyWith({
    int? schemaVersion,
    Set<String>? unlockedCharacterIds,
    Set<String>? unlockedWeaponIds,
    Set<String>? unlockedAugmentIds,
    Set<String>? completedGoalIds,
    int? totalKills,
    int? bestSurvivalSeconds,
    int? levelReachedInRun,
    int? bossDefeats,
    int? unlockedWeaponCount,
    int? lowHealthWinCount,
  }) {
    return SaveState(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      unlockedCharacterIds:
          unlockedCharacterIds ?? Set<String>.of(this.unlockedCharacterIds),
      unlockedWeaponIds:
          unlockedWeaponIds ?? Set<String>.of(this.unlockedWeaponIds),
      unlockedAugmentIds:
          unlockedAugmentIds ?? Set<String>.of(this.unlockedAugmentIds),
      completedGoalIds:
          completedGoalIds ?? Set<String>.of(this.completedGoalIds),
      totalKills: totalKills ?? this.totalKills,
      bestSurvivalSeconds: bestSurvivalSeconds ?? this.bestSurvivalSeconds,
      levelReachedInRun: levelReachedInRun ?? this.levelReachedInRun,
      bossDefeats: bossDefeats ?? this.bossDefeats,
      unlockedWeaponCount: unlockedWeaponCount ?? this.unlockedWeaponCount,
      lowHealthWinCount: lowHealthWinCount ?? this.lowHealthWinCount,
    );
  }
```

Add the first entry to `toJson()`:

```dart
  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'unlockedCharacterIds': _sorted(unlockedCharacterIds),
```

- [ ] **Step 4: Run the focused test and confirm success**

Run the Step 2 command again.

Expected: both new tests pass.

- [ ] **Step 5: Commit Task 1**

```powershell
git add lib/game/systems/save_system.dart test/game/save_system_test.dart
git commit -m "feat: version save state schema"
```

---

### Task 2: Reject future and malformed schemas safely

**Files:**
- Modify: `lib/game/systems/save_system.dart`
- Test: `test/game/save_system_test.dart`

**Interfaces:**
- Consumes: `SaveState.currentSchemaVersion == 1` from Task 1.
- Produces: A schema boundary that accepts versionless schema 0 and current schema 1, while rejecting future, negative, and non-integer versions.

- [ ] **Step 1: Add failing unsafe-schema tests**

Append inside `main()`:

```dart
  group('unsupported save schemas', () {
    test('future schema returns defaults', () {
      final restored = SaveState.fromJson({
        'schemaVersion': SaveState.currentSchemaVersion + 1,
        'totalKills': 999,
        'unlockedCharacterIds': [exorcistDosa],
      });

      expect(restored.schemaVersion, SaveState.currentSchemaVersion);
      expect(restored.totalKills, 0);
      expect(restored.unlockedCharacterIds, {rookieConstable});
    });

    test('negative schema returns defaults', () {
      final restored = SaveState.fromJson({
        'schemaVersion': -1,
        'totalKills': 999,
      });

      expect(restored.totalKills, 0);
    });

    test('non-integer schema returns defaults', () {
      final restored = SaveState.fromJson({
        'schemaVersion': '1',
        'totalKills': 999,
      });

      expect(restored.totalKills, 0);
    });
  });

  test('save system loads defaults for unsupported stored schema', () async {
    SharedPreferences.setMockInitialValues({
      'save_state': '{"schemaVersion":2,"totalKills":999}',
    });

    final save = await SaveSystem().load();

    expect(save.schemaVersion, SaveState.currentSchemaVersion);
    expect(save.totalKills, 0);
    expect(save.unlockedCharacterIds, {rookieConstable});
  });
```

- [ ] **Step 2: Run the focused test and confirm failure**

```powershell
flutter test test/game/save_system_test.dart --plain-name "unsupported save schemas"
```

Expected: at least the future-schema assertion fails because unsupported versions are currently decoded as normal saves.

- [ ] **Step 3: Decode supported schemas through a private boundary**

Replace `SaveState.fromJson` with:

```dart
  factory SaveState.fromJson(Map<String, dynamic> json) {
    final rawSchemaVersion = json['schemaVersion'];
    final schemaVersion = rawSchemaVersion == null ? 0 : rawSchemaVersion;
    if (schemaVersion is! int ||
        schemaVersion < 0 ||
        schemaVersion > currentSchemaVersion) {
      return SaveState.defaults();
    }

    return _fromSupportedJson(json);
  }

  static SaveState _fromSupportedJson(Map<String, dynamic> json) {
    final defaults = SaveState.defaults();
    return SaveState(
      schemaVersion: currentSchemaVersion,
      unlockedCharacterIds: _stringSet(
        json['unlockedCharacterIds'],
        fallback: defaults.unlockedCharacterIds,
      ),
      unlockedWeaponIds: _stringSet(
        json['unlockedWeaponIds'],
        fallback: defaults.unlockedWeaponIds,
      ),
      unlockedAugmentIds: _stringSet(
        json['unlockedAugmentIds'],
        fallback: defaults.unlockedAugmentIds,
      ),
      completedGoalIds: _stringSet(json['completedGoalIds']),
      totalKills: _intValue(json['totalKills']),
      bestSurvivalSeconds: _intValue(json['bestSurvivalSeconds']),
      levelReachedInRun: _intValue(json['levelReachedInRun']),
      bossDefeats: _intValue(json['bossDefeats']),
      unlockedWeaponCount: _intValue(
        json['unlockedWeaponCount'],
        fallback: defaults.unlockedWeaponCount,
      ),
      lowHealthWinCount: _intValue(json['lowHealthWinCount']),
    );
  }
```

- [ ] **Step 4: Run all save tests**

```powershell
flutter test test/game/save_system_test.dart
```

Expected: all save-system tests pass.

- [ ] **Step 5: Commit Task 2**

```powershell
git add lib/game/systems/save_system.dart test/game/save_system_test.dart
git commit -m "feat: reject unsupported save schemas"
```

---

### Task 3: Document app and save version policy

**Files:**
- Create: `docs/release/versioning.md`
- Modify: `README.md`
- Modify: `docs/master-development-todo.md`

**Interfaces:**
- Consumes: `SaveState.currentSchemaVersion == 1` and `pubspec.yaml` version `0.1.0+1`.
- Produces: Release version rules used by every future build and marks `FND-006` through `FND-009` complete.

- [ ] **Step 1: Create the exact version policy document**

Create `docs/release/versioning.md` with:

```markdown
# Versioning Policy

## App version

The project uses `MAJOR.MINOR.PATCH+BUILD` in `pubspec.yaml`.

- `MAJOR`: incompatible public release or save-policy change requiring an explicit product decision.
- `MINOR`: backward-compatible content or feature release.
- `PATCH`: backward-compatible bug fix or balance release.
- `BUILD`: monotonically increasing Google Play build number for every uploaded artifact.

The current alpha line is `0.1.x`. Android 1.0 starts at `1.0.0` only after every release gate in `docs/master-development-todo.md` passes.

## Save schema

`SaveState.currentSchemaVersion` is independent from the app version.

- Schema `0`: versionless alpha saves.
- Schema `1`: first explicit schema; current.
- Missing schema values migrate from schema 0 to schema 1.
- Negative, malformed, or future schema values load defaults without crashing.
- A schema increment requires migration tests from every previously shipped schema.
- The shared-preferences key remains `save_state` until a reviewed migration changes it.

## Release checklist

1. Increment the app build number for every uploaded APK or AAB.
2. Increment PATCH, MINOR, or MAJOR according to the rules above.
3. Add save migration tests before incrementing `SaveState.currentSchemaVersion`.
4. Run `.\tool\release_check.ps1`.
5. Run `.\tool\release_check.ps1 -IncludeAndroid` on an Android-ready machine.
6. Record user-visible changes in the release notes before upload.
```

- [ ] **Step 2: Link the policy from README**

Add after the local release-gate section in `README.md`:

```markdown
App and save version rules are documented in `docs/release/versioning.md`.
```

- [ ] **Step 3: Update the master TODO evidence**

In `docs/master-development-todo.md`:

- Change `FND-006`, `FND-007`, `FND-008`, and `FND-009` to `[x]`.
- Change the current next execution queue to `FND-010 → FND-011 → TEL-001`.
- Keep stage 2 open because Android SDK and the first remote CI run remain user-dependent.

- [ ] **Step 4: Run documentation and diff checks**

```powershell
git diff --check
rg -n "FND-00[6-9].*\[P" docs/master-development-todo.md
rg -n "currentSchemaVersion|schema 0|schema 1|BUILD" docs/release/versioning.md
```

Expected: `git diff --check` exits 0 and every required version term is present.

- [ ] **Step 5: Commit Task 3**

```powershell
git add README.md docs/release/versioning.md docs/master-development-todo.md
git commit -m "docs: define app and save version policy"
```

---

### Task 4: Run the full foundation release gate

**Files:**
- Verify only: all tracked project files

**Interfaces:**
- Consumes: Tasks 1 through 3.
- Produces: Verified foundation milestone ready for remote Android CI and telemetry work.

- [ ] **Step 1: Run the complete local release gate**

```powershell
$env:Path = "$env:USERPROFILE\source\flutter\bin;$env:Path"
.\tool\release_check.ps1
```

Expected:

- Dart analysis reports `No issues found!`.
- All tests pass; the count is greater than 82 because new save tests were added.
- Web release build succeeds.
- Script prints `Release checks passed.` and exits 0.

- [ ] **Step 2: Confirm the worktree is clean except intended commits**

```powershell
git status --short
git log --oneline -3
```

Expected: no uncommitted files. The latest commits correspond to schema persistence and migration, unsupported-schema handling, and version policy.

- [ ] **Step 3: Record the remaining external gate**

Do not mark `FND-010` or `FND-011` complete locally. Report that Android SDK installation and the first successful remote GitHub Actions run remain required before stage 2 closes.
