# Character Roster and Horde Ramp Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a fully playable 산길 사냥꾼, expose all three playtest characters, and make enemy pressure increase continuously from a denser opening through the boss fight.

**Architecture:** Character-specific combat behavior is represented by a typed `CharacterPassive` value and resolved into neutral-by-default modifiers owned by `PixelSurvivorGame`. Development roster availability is centralized outside the selection UI. Wave definitions store start/end pressure values, and `WaveDirector` resolves a clamped linear snapshot for the current elapsed second while retaining the existing spawn budget and frame cap.

**Tech Stack:** Dart 3.12, Flutter 3.44, Flame, flutter_test, deterministic `Random`-driven simulations.

## Global Constraints

- All three characters are selectable in Web and Android release playtest builds, not only `kDebugMode` builds.
- Unknown character IDs fall back to 신참 포졸.
- Missing passive data resolves to neutral modifiers.
- The frame spawn cap remains exactly eight and the boss request remains exactly once at 270 seconds.
- The 4:00-4:30 active cap rises from 80 to 92; normal enemies continue during the boss phase.
- Every existing reference experience profile ends between 9 and 12 level-ups, inclusive.
- No new final image or audio asset is required.

---

### Task 1: Typed Character Roster and Passives

**Files:**
- Modify: `lib/game/content/ids.dart`
- Modify: `lib/game/content/character_definitions.dart`
- Create: `test/game/character_roster_test.dart`

**Interfaces:**
- Produces: `enum CharacterPassive { none, patrolGrit, exorcismScript, hawkEye }`
- Produces: `CharacterDefinition.passive`, `passiveName`, and `passiveDescription`
- Produces: `const mountainHunter = 'mountain_hunter'`
- Consumes: existing weapon IDs `hwandoSlash`, `talismanThrow`, and `gakgungShot`

- [ ] **Step 1: Write the failing roster definition test**

```dart
test('playtest roster has three distinct roles and valid starting weapons', () {
  expect(characterDefinitions.map((item) => item.id).toSet(), {
    rookieConstable,
    exorcistDosa,
    mountainHunter,
  });
  expect(characterDefinitions.map((item) => item.startingWeaponId).toSet(), {
    hwandoSlash,
    talismanThrow,
    gakgungShot,
  });
  expect(characterDefinitions.map((item) => item.passive).toSet(), {
    CharacterPassive.patrolGrit,
    CharacterPassive.exorcismScript,
    CharacterPassive.hawkEye,
  });
  expect(characterDefinitions.every((item) => item.passiveDescription.isNotEmpty), isTrue);
});

test('mountain hunter is the fast ranged critical character', () {
  final hunter = characterDefinitions.singleWhere((item) => item.id == mountainHunter);
  expect(hunter.maxHealth, 90);
  expect(hunter.moveSpeed, 140);
  expect(hunter.startingWeaponId, gakgungShot);
  expect(hunter.passive, CharacterPassive.hawkEye);
});
```

- [ ] **Step 2: Run the test and verify RED**

Run: `flutter test test/game/character_roster_test.dart -r expanded`

Expected: compilation fails because `CharacterPassive`, `mountainHunter`, and passive fields do not exist.

- [ ] **Step 3: Add the typed passive contract and the third character**

```dart
enum CharacterPassive { none, patrolGrit, exorcismScript, hawkEye }

class CharacterDefinition {
  const CharacterDefinition({
    required this.id,
    required this.name,
    required this.maxHealth,
    required this.moveSpeed,
    required this.damageMultiplier,
    required this.startingWeaponId,
    this.passive = CharacterPassive.none,
    this.passiveName = '',
    this.passiveDescription = '',
  });

  final CharacterPassive passive;
  final String passiveName;
  final String passiveDescription;
}
```

Add `산길 사냥꾼` with health `90`, move speed `140`, neutral base damage multiplier `1`, starting weapon `gakgungShot`, and passive copy `매의 눈 / 치명타 확률 +10%p`. Give the constable `순라의 끈기 / 접촉 피해 -12%` and the dosa `퇴마 서법 / 마법 무기 피해 +15%`.

- [ ] **Step 4: Run the focused test and verify GREEN**

Run: `flutter test test/game/character_roster_test.dart -r expanded`

Expected: both tests pass.

- [ ] **Step 5: Commit the roster contract**

```powershell
git add lib/game/content/ids.dart lib/game/content/character_definitions.dart test/game/character_roster_test.dart
git commit -m "feat: define three-character playtest roster"
```

---

### Task 2: Development Roster Availability and Selection UI

**Files:**
- Create: `lib/game/content/playtest_roster.dart`
- Modify: `lib/game/systems/save_system.dart`
- Modify: `lib/app/character_select_screen.dart`
- Modify: `test/game/save_system_test.dart`
- Modify: `test/app/character_select_screen_test.dart`
- Modify: `test/app/korean_strings_test.dart`

**Interfaces:**
- Produces: `PlaytestRoster.selectableCharacterIds`
- Produces: `PlaytestRoster.resolveUnlocked(Set<CharacterId>) -> Set<CharacterId>`
- Consumes: `characterDefinitions` and saved `unlockedCharacterIds`

- [ ] **Step 1: Write failing availability and three-card widget tests**

```dart
test('development roster unions every current character without losing saved ids', () {
  expect(PlaytestRoster.resolveUnlocked({rookieConstable}), {
    rookieConstable,
    exorcistDosa,
    mountainHunter,
  });
});

testWidgets('all three playtest characters are selectable', (tester) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  PlayerSlot? launched;
  await tester.pumpWidget(MaterialApp(
    home: CharacterSelectScreen(
      saveSystem: SaveSystem(preferences: preferences),
      onStart: (slot) => launched = slot,
    ),
  ));
  await tester.pumpAndSettle();

  for (final definition in characterDefinitions) {
    expect(find.byKey(Key('character-${definition.id}')), findsOneWidget);
    expect(find.byKey(Key('character-lock-${definition.id}')), findsNothing);
  }
  await tester.tap(find.byKey(const Key('character-mountain_hunter')));
  await tester.tap(find.byKey(const Key('character-start')));
  expect(launched?.characterId, mountainHunter);
});
```

- [ ] **Step 2: Run the focused tests and verify RED**

Run: `flutter test test/game/save_system_test.dart test/app/character_select_screen_test.dart -r expanded`

Expected: `PlaytestRoster` and the hunter card are missing; the dosa remains locked in existing expectations.

- [ ] **Step 3: Centralize roster availability**

```dart
abstract final class PlaytestRoster {
  static Set<CharacterId> get selectableCharacterIds =>
      characterDefinitions.map((item) => item.id).toSet();

  static Set<CharacterId> resolveUnlocked(Iterable<CharacterId> savedIds) => {
    ...savedIds,
    ...selectableCharacterIds,
  };
}
```

Use `resolveUnlocked` when constructing defaults and when reading supported JSON. Preserve counters, completed goals, and unrelated unlock sets. Keep the policy independent of `kDebugMode`.

- [ ] **Step 4: Show the third card and passive copy**

Render `definition.passiveName` and `definition.passiveDescription` below the starting weapon. Map the hunter to a distinct built-in icon and add `mountainHunter => '산길 사냥꾼'` to `_localizedName`.

- [ ] **Step 5: Update expectations and verify GREEN**

Run: `flutter test test/game/save_system_test.dart test/app/character_select_screen_test.dart test/app/korean_strings_test.dart -r expanded`

Expected: all tests pass; existing and fresh saves expose three characters.

- [ ] **Step 6: Commit playtest availability**

```powershell
git add lib/game/content/playtest_roster.dart lib/game/systems/save_system.dart lib/app/character_select_screen.dart test/game/save_system_test.dart test/app/character_select_screen_test.dart test/app/korean_strings_test.dart
git commit -m "feat: unlock the full playtest roster"
```

---

### Task 3: Apply Character Passives at Combat Boundaries

**Files:**
- Create: `lib/game/systems/character_passive_modifiers.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `lib/game/systems/combat_system.dart`
- Create: `test/game/character_passive_modifiers_test.dart`
- Modify: `test/game/combat_system_test.dart`
- Modify: `test/game/pixel_survivor_game_loop_test.dart`

**Interfaces:**
- Produces: immutable `CharacterPassiveModifiers`
- Produces: `CharacterPassiveModifiers.forPassive(CharacterPassive)`
- Modifies: `CombatSystem.applyContactDamage(..., double incomingDamageMultiplier = 1)`
- Consumes: selected `CharacterDefinition.passive`, weapon `ElementType`, and existing critical chance

- [ ] **Step 1: Write failing modifier tests**

```dart
test('passives resolve to exact neutral-safe modifiers', () {
  expect(CharacterPassiveModifiers.forPassive(CharacterPassive.none),
      const CharacterPassiveModifiers());
  expect(CharacterPassiveModifiers.forPassive(CharacterPassive.patrolGrit)
      .incomingContactDamageMultiplier, 0.88);
  expect(CharacterPassiveModifiers.forPassive(CharacterPassive.exorcismScript)
      .magicDamageMultiplier, 1.15);
  expect(CharacterPassiveModifiers.forPassive(CharacterPassive.hawkEye)
      .bonusCriticalChance, 0.10);
});
```

Add combat tests proving a 10-damage contact hit removes `8.8` health at multiplier `0.88`, while the default remains 10.

- [ ] **Step 2: Run focused tests and verify RED**

Run: `flutter test test/game/character_passive_modifiers_test.dart test/game/combat_system_test.dart -r expanded`

Expected: modifier type and contact multiplier parameter are missing.

- [ ] **Step 3: Implement neutral-safe modifier resolution**

```dart
class CharacterPassiveModifiers {
  const CharacterPassiveModifiers({
    this.incomingContactDamageMultiplier = 1,
    this.magicDamageMultiplier = 1,
    this.bonusCriticalChance = 0,
  });

  final double incomingContactDamageMultiplier;
  final double magicDamageMultiplier;
  final double bonusCriticalChance;

  static CharacterPassiveModifiers forPassive(CharacterPassive passive) => switch (passive) {
    CharacterPassive.patrolGrit => const CharacterPassiveModifiers(incomingContactDamageMultiplier: 0.88),
    CharacterPassive.exorcismScript => const CharacterPassiveModifiers(magicDamageMultiplier: 1.15),
    CharacterPassive.hawkEye => const CharacterPassiveModifiers(bonusCriticalChance: 0.10),
    CharacterPassive.none => const CharacterPassiveModifiers(),
  };
}
```

- [ ] **Step 4: Apply modifiers in the game loop**

Resolve the selected character once when the player is added and retain its modifiers. Add the bonus to `criticalChance` with a `[0,1]` clamp. Pass `incomingContactDamageMultiplier` to `CombatSystem`. Add `Map<ElementType, double> elementDamageMultipliers = const {}` to `WeaponSystem.tick`; resolve each weapon's element from `weaponDefinitions`, default missing entries to `1`, and multiply its base damage by the resolved value. Pass `{ElementType.magic: 1.15}` only for the dosa so physical and fire attacks remain unchanged.

- [ ] **Step 5: Verify exact passive isolation**

Run: `flutter test test/game/character_passive_modifiers_test.dart test/game/combat_system_test.dart test/game/pixel_survivor_game_loop_test.dart test/game/weapon_system_test.dart -r expanded`

Expected: passive tests and existing weapon/combat regressions pass.

- [ ] **Step 6: Commit passive behavior**

```powershell
git add lib/game/systems/character_passive_modifiers.dart lib/game/pixel_survivor_game.dart lib/game/systems/combat_system.dart lib/game/systems/weapon_system.dart test/game/character_passive_modifiers_test.dart test/game/combat_system_test.dart test/game/pixel_survivor_game_loop_test.dart test/game/weapon_system_test.dart
git commit -m "feat: apply character combat passives"
```

---

### Task 4: Continuous Horde Pressure Curve

**Files:**
- Modify: `lib/game/content/wave_definitions.dart`
- Modify: `lib/game/systems/wave_director.dart`
- Modify: `lib/game/balance/wave_regression_simulator.dart`
- Modify: `test/game/wave_director_test.dart`
- Modify: `test/game/multi_seed_run_regression_test.dart`
- Modify: `test/game/enemy_balance_baseline_test.dart`

**Interfaces:**
- Produces: start/end spawn rate, active cap, and elite chance on `WaveDefinition`
- Produces: `WavePressure wavePressureForSecond(double elapsedSeconds)`
- Consumes: interpolated `WavePressure` inside `WaveDirector.tick`

- [ ] **Step 1: Write failing interpolation tests**

```dart
test('pressure interpolates continuously inside the opening phase', () {
  expect(wavePressureForSecond(0).spawnsPerSecond, 1.0);
  expect(wavePressureForSecond(30).spawnsPerSecond, closeTo(1.2, 0.001));
  expect(wavePressureForSecond(59.999).spawnsPerSecond, closeTo(1.4, 0.001));
  expect(wavePressureForSecond(30).maxActiveEnemies, 36);
});

test('pre-boss pressure reaches the approved cap and boss phase stays populated', () {
  expect(wavePressureForSecond(240).maxActiveEnemies, 80);
  expect(wavePressureForSecond(269.999).maxActiveEnemies, 92);
  expect(wavePressureForSecond(270).spawnsPerSecond, 1.5);
  expect(wavePressureForSecond(329.999).maxActiveEnemies, 64);
});
```

- [ ] **Step 2: Run wave tests and verify RED**

Run: `flutter test test/game/wave_director_test.dart test/game/multi_seed_run_regression_test.dart -r expanded`

Expected: interpolation API is missing and old caps/rates fail approved expectations.

- [ ] **Step 3: Implement the wave pressure value object and exact table**

Store the approved start/end pairs from the design for all six phases. Compute progress as `(elapsed - start) / (end - start)`, clamped to `[0,1]`. Interpolate doubles directly and round the active cap to the nearest integer. Keep group size phase-specific and clamp negative elapsed time to the first phase.

- [ ] **Step 4: Consume resolved pressure and bound backlog**

Use resolved spawn rate, elite chance, and active cap in `WaveDirector.tick`. Clamp `_spawnBudget` to `WaveDirector.frameSpawnCap.toDouble()` after accumulation so pause/slow-frame recovery cannot retain an unlimited backlog. Expose `static const frameSpawnCap = 8` for regression tests.

- [ ] **Step 5: Tighten deterministic simulation gates**

Require each of seeds `0..19` to have one boss request, zero cap violations, zero invalid pool requests, max frame spawns `<= 8`, max active enemies `<= 92`, and total normal spawns `>= 400`. Keep fingerprint determinism and require pressure-phase elites across the seed set.

- [ ] **Step 6: Run wave and balance tests and verify GREEN**

Run: `flutter test test/game/wave_director_test.dart test/game/multi_seed_run_regression_test.dart test/game/enemy_balance_baseline_test.dart -r expanded`

Expected: all wave tests pass with continuously increasing pressure.

- [ ] **Step 7: Commit the horde ramp**

```powershell
git add lib/game/content/wave_definitions.dart lib/game/systems/wave_director.dart lib/game/balance/wave_regression_simulator.dart test/game/wave_director_test.dart test/game/multi_seed_run_regression_test.dart test/game/enemy_balance_baseline_test.dart
git commit -m "feat: add continuous horde pressure ramp"
```

---

### Task 5: Retune Experience and Record the Milestone

**Files:**
- Modify: `lib/game/balance/experience_balance_baseline.dart`
- Modify: `lib/game/systems/run_progression_system.dart`
- Modify: `test/game/experience_balance_baseline_test.dart`
- Modify: `docs/master-development-todo.md`

**Interfaces:**
- Consumes: continuous wave pressure integration over five minutes
- Produces: an experience requirement curve that keeps all three profiles at 9-12 level-ups

- [ ] **Step 1: Make the experience simulator integrate the new curve**

Replace phase-wide `spawnsPerSecond` and `eliteChance` multiplication with deterministic one-second samples from `wavePressureForSecond(second + 0.5)`. Keep weighted enemy experience by the current phase pool.

- [ ] **Step 2: Run the experience regression and verify the expected RED values**

Run: `flutter test test/game/experience_balance_baseline_test.dart -r expanded`

Expected: old expected experience fails near `987.5269`, and the old `4 + level` production curve pushes one or more acquisition profiles above the target band.

- [ ] **Step 3: Retune the single production experience curve**

Change `RunProgressionSystem.experienceRequiredForLevel` to `9 + (level * 2)`. Do not change enemy experience values. Update simulator expectations to spawned experience `closeTo(987.5269, 0.001)`, profile results `[9, 11, 12]`, cumulative cost for eight level-ups `144`, and cumulative cost for twelve level-ups `264`.

- [ ] **Step 4: Run progression and full focused balance tests**

Run: `flutter test test/game/experience_balance_baseline_test.dart test/game/run_progression_system_test.dart test/game/multi_seed_run_regression_test.dart -r expanded`

Expected: all tests pass; no profile is below 9 or above 12.

- [ ] **Step 5: Update the master milestone evidence**

Record `CNT-001` and `CNT-002` completion, the selected hunter passive/start weapon, development-wide three-character access, the approved horde pressure values, fixed-seed results, and the new total test count in `docs/master-development-todo.md`. Leave audio polish and final images pending.

- [ ] **Step 6: Run the complete release gate**

Run: `.\tool\release_check.ps1 -IncludeAndroid`

Expected: formatting, static analysis, all Flutter tests, Web build, and Android debug APK build pass.

- [ ] **Step 7: Commit documentation and any final regression adjustments**

```powershell
git add lib/game/balance/experience_balance_baseline.dart lib/game/systems/run_progression_system.dart test/game/experience_balance_baseline_test.dart docs/master-development-todo.md
git commit -m "docs: record roster and horde milestone"
```

---

### Task 6: Browser Playtest Checkpoint and Merge

**Files:**
- No source files unless verification exposes a defect.

**Interfaces:**
- Consumes: the release Web build produced by Task 5
- Produces: a locally playable Chrome checkpoint on `master`

- [ ] **Step 1: Serve the release Web build**

Run the existing local static-server workflow for `build/web` and open or refresh the game in Chrome.

- [ ] **Step 2: Verify the player-visible flow**

Confirm all three cards are unlocked, 산길 사냥꾼 launches with 각궁, enemy density is higher from the opening minute, pressure rises through 4:30, and the boss fight retains normal enemies. Browser audio is not an acceptance criterion for this slice.

- [ ] **Step 3: Fast-forward merge the completed feature branch into `master`**

```powershell
git switch master
git merge --ff-only character-horde-ramp
git branch -d character-horde-ramp
```

Expected: `master` contains every reviewed commit and `git status --short` is empty.
