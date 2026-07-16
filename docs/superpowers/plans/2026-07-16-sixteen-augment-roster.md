# Sixteen Augment Roster Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement all 16 designed augments with one data source for balance values, runtime effects, and level-up card copy.

**Architecture:** `AugmentDefinition` owns typed effect data and balance values. A focused resolver converts definitions plus current levels and health into immutable modifiers, while a formatter renders the same effects for cards; `PixelSurvivorGame` consumes those two interfaces instead of ID switches. `RunProgressionSystem` retains fractional experience so percentage bonuses work correctly even for one-point gems.

**Tech Stack:** Dart 3, Flutter 3.44.4, Flame, `flutter_test`, SharedPreferences

## Global Constraints

- Implement exactly 16 augments with category distribution attack 5, survival 4, movement/acquisition 4, risk/reward 3.
- Keep every balance value in `lib/game/content/augment_definitions.dart`; do not duplicate numeric effect values in the game or card formatter.
- Add only the four new IDs `iron_armor_training`, `scholar_insight`, `blood_oath`, and `ghost_step`.
- New four augments use `startsUnlocked: true`; existing locked/unlocked flags remain unchanged.
- Percentage effects stack additively from the base multiplier.
- Critical chance clamps to 0–1; attack and movement multipliers clamp to at least 0.1; incoming contact damage clamps to at least 0; pickup radius stays at least 25% of its base; experience requirement reduction clamps at 80%.
- `last_stand` activates at health fraction `<= 0.35` and deactivates above it.
- `ritual_shortcut` never causes a level-up at selection time; its reduced threshold is used by the next positive experience gain and by the HUD immediately.
- Cards must show cumulative current-to-next values, fixed immediate healing, conditions, and penalties from the effect data.
- Do not add image assets, packages, save schema versions, unlock goals, or collection UI.
- Run focused tests during tasks and the full Flutter suite once at completion. In this Windows session prefix test commands with `$env:TEMP='C:\codex-temp'; $env:TMP='C:\codex-temp'`.

## File Structure

- Modify `lib/game/content/ids.dart`: typed augment category/effect model attached to `AugmentDefinition`.
- Modify `lib/game/content/augment_definitions.dart`: all 16 IDs, names, categories, levels, unlock flags, and balance values.
- Create `lib/game/systems/augment_effect_resolver.dart`: pure effect aggregation and safety clamps.
- Create `lib/game/systems/augment_effect_formatter.dart`: Korean card text derived from typed effects.
- Modify `lib/game/systems/level_up_system.dart`: remove the supported-ID set and ID-based augment description switch.
- Modify `lib/game/systems/run_progression_system.dart`: fractional experience accumulation and configurable gain/requirement multipliers.
- Modify `lib/game/pixel_survivor_game.dart`: consume resolver modifiers and apply definition-driven immediate effects.
- Keep `lib/game/systems/save_system.dart` production behavior unchanged: it already merges `startsUnlocked` augment IDs into older saves; add a regression test after the new definitions land.
- Keep `lib/app/run_summary_screen.dart` production behavior unchanged: it already resolves augment names from definitions; add a regression assertion for a new ID.
- Modify `docs/master-development-todo.md`: close `CNT-005` and `CNT-006`, then advance the queue.
- Create `docs/superpowers/verification/2026-07-16-sixteen-augment-roster.md`: record focused and full verification.
- Test the above in `test/game/content_definitions_test.dart`, `test/game/augment_effect_resolver_test.dart`, `test/game/level_up_system_test.dart`, `test/game/run_progression_system_test.dart`, `test/game/pixel_survivor_game_loop_test.dart`, and `test/game/save_system_test.dart`.

---

### Task 1: Typed Effect Model and 16-Definition Roster

**Files:**
- Modify: `lib/game/content/ids.dart`
- Modify: `lib/game/content/augment_definitions.dart`
- Modify: `test/game/content_definitions_test.dart`

**Interfaces:**
- Produces: `AugmentCategory`, `AugmentStat`, `AugmentEffectApplication`, `AugmentCondition`, `AugmentEffect`, and `AugmentDefinition.effects`.
- Produces: `augmentDefinitionFor(AugmentId id) -> AugmentDefinition?` for the resolver, level-up system, game, and summary UI.

- [ ] **Step 1: Replace the ordered-eight assertion with failing roster and effect-validation tests**

```dart
test('augment roster has the designed size and category distribution', () {
  expect(augmentDefinitions, hasLength(16));
  expect(augmentDefinitions.map((item) => item.id).toSet(), hasLength(16));
  expect(
    {for (final category in AugmentCategory.values)
      category: augmentDefinitions.where((a) => a.category == category).length},
    {
      AugmentCategory.attack: 5,
      AugmentCategory.survival: 4,
      AugmentCategory.movementAcquisition: 4,
      AugmentCategory.riskReward: 3,
    },
  );
  expect(augmentDefinitions.every((item) => item.effects.isNotEmpty), isTrue);
  expect(
    augmentDefinitions.expand((item) => item.effects).every(
      (effect) => effect.valuePerLevel.isFinite && effect.valuePerLevel != 0,
    ),
    isTrue,
  );
});

test('new augments use the approved names, levels, and default unlocks', () {
  expect(
    [ironArmorTraining, scholarInsight, bloodOath, ghostStep].map(
      (id) => augmentDefinitionFor(id),
    ),
    everyElement(isNotNull),
  );
  expect(augmentDefinitionFor(ironArmorTraining)?.name, '철갑 수련');
  expect(augmentDefinitionFor(scholarInsight)?.name, '선비의 통찰');
  expect(augmentDefinitionFor(bloodOath)?.maxLevel, 3);
  expect(augmentDefinitionFor(ghostStep)?.maxLevel, 3);
  expect(
    [ironArmorTraining, scholarInsight, bloodOath, ghostStep]
        .map((id) => augmentDefinitionFor(id)!.startsUnlocked),
    everyElement(isTrue),
  );
});
```

- [ ] **Step 2: Run the content test and confirm the missing-model failure**

Run:

```powershell
$env:TEMP='C:\codex-temp'; $env:TMP='C:\codex-temp'; flutter test test/game/content_definitions_test.dart
```

Expected: FAIL because the new effect types, IDs, and four definitions do not exist.

- [ ] **Step 3: Add the typed model to `ids.dart`**

```dart
enum AugmentCategory { attack, survival, movementAcquisition, riskReward }

enum AugmentStat {
  weaponDamage,
  fireDamage,
  attackSpeed,
  criticalChance,
  weaponSize,
  moveSpeed,
  incomingContactDamage,
  experienceGain,
  pickupRadius,
  experienceRequirement,
  maxHealth,
  healing,
}

enum AugmentEffectApplication { continuous, onAcquire }
enum AugmentCondition { always, healthAtOrBelow35 }

class AugmentEffect {
  const AugmentEffect({
    required this.stat,
    required this.valuePerLevel,
    this.application = AugmentEffectApplication.continuous,
    this.condition = AugmentCondition.always,
    this.isPenalty = false,
  });

  final AugmentStat stat;
  final double valuePerLevel;
  final AugmentEffectApplication application;
  final AugmentCondition condition;
  final bool isPenalty;
}
```

Extend `AugmentDefinition` with required `category` and `effects`, and remove the free-form `effectDescription` plus `effectDescriptionForLevel`; all consumers move to the typed formatter in Task 2.

- [ ] **Step 4: Replace `augment_definitions.dart` with the exact 16-effect data set**

Use one `AugmentEffect` per simple augment and two effects for `innerBreath`, `lastStand`, `heavyStrike`, `bloodOath`, and `ghostStep`. Encode these exact signed values:

```dart
const ironArmorTraining = 'iron_armor_training';
const scholarInsight = 'scholar_insight';
const bloodOath = 'blood_oath';
const ghostStep = 'ghost_step';

// stat, valuePerLevel, application, condition, isPenalty
// martialTraining: weaponDamage, 0.12
// rapidReload: attackSpeed, 0.10
// hawkEye: criticalChance, 0.05
// powderMastery: weaponSize, 0.10
// goblinFire: fireDamage, 0.15
// innerBreath: maxHealth, 10, onAcquire; healing, 10, onAcquire
// herbalTonic: healing, 12, onAcquire
// ironArmorTraining: incomingContactDamage, -0.06
// lastStand: incomingContactDamage, -0.10, continuous, healthAtOrBelow35;
//            weaponDamage, 0.20, continuous, healthAtOrBelow35
// quickStep: moveSpeed, 0.08
// jangseungBlessing: pickupRadius, 16
// scholarInsight: experienceGain, 0.10
// ritualShortcut: experienceRequirement, -0.15
// heavyStrike: weaponDamage, 0.18; attackSpeed, -0.08, penalty
// bloodOath: weaponDamage, 0.20; incomingContactDamage, 0.10, penalty
// ghostStep: moveSpeed, 0.15; pickupRadius, -12, penalty

AugmentDefinition? augmentDefinitionFor(AugmentId id) {
  for (final definition in augmentDefinitions) {
    if (definition.id == id) return definition;
  }
  return null;
}
```

Keep maximum levels `5,5,5,5,5,5,5,5,3,5,5,5,1,5,3,3` in table order from the design. Preserve the existing start flags and set only the new four to `true`. Keep `firstStageAugmentIds` unchanged so the first-stage contract remains the original ordered eight.

- [ ] **Step 5: Run the focused test and commit**

Run:

```powershell
$env:TEMP='C:\codex-temp'; $env:TMP='C:\codex-temp'; flutter test test/game/content_definitions_test.dart test/app/korean_strings_test.dart
```

Expected: PASS.

```powershell
git add lib/game/content/ids.dart lib/game/content/augment_definitions.dart test/game/content_definitions_test.dart
git commit -m "feat: define sixteen typed augments"
```

### Task 2: Shared Effect Resolver and Card Formatter

**Files:**
- Create: `lib/game/systems/augment_effect_resolver.dart`
- Create: `lib/game/systems/augment_effect_formatter.dart`
- Create: `test/game/augment_effect_resolver_test.dart`
- Modify: `lib/game/systems/level_up_system.dart`
- Modify: `test/game/level_up_system_test.dart`

**Interfaces:**
- Consumes: `AugmentDefinition.effects` and `augmentDefinitionFor` from Task 1.
- Produces: `AugmentEffectResolver.resolve({required Map<AugmentId, int> levels, double healthFraction = 1}) -> AugmentModifiers`.
- Produces: `AugmentEffectFormatter.describeLevelChange(AugmentDefinition definition, int currentLevel) -> String`.

- [ ] **Step 1: Add failing resolver tests for simple, elemental, conditional, and penalty effects**

```dart
test('resolver aggregates benefits and penalties from definitions', () {
  final result = const AugmentEffectResolver().resolve(
    levels: const {
      martialTraining: 2,
      heavyStrike: 1,
      bloodOath: 1,
      ghostStep: 2,
      goblinFire: 2,
    },
  );
  expect(result.weaponDamageMultiplier, closeTo(1.62, 0.0001));
  expect(result.attackSpeedMultiplier, closeTo(0.92, 0.0001));
  expect(result.incomingContactDamageMultiplier, closeTo(1.10, 0.0001));
  expect(result.moveSpeedMultiplier, closeTo(1.30, 0.0001));
  expect(result.pickupRadiusBonus, -24);
  expect(result.elementDamageMultipliers[ElementType.fire], closeTo(1.30, 0.0001));
});

test('last stand activates exactly at thirty-five percent health', () {
  final resolver = const AugmentEffectResolver();
  const levels = {lastStand: 2};
  expect(resolver.resolve(levels: levels, healthFraction: 0.351).weaponDamageMultiplier, 1);
  expect(resolver.resolve(levels: levels, healthFraction: 0.35).weaponDamageMultiplier, 1.4);
  expect(resolver.resolve(levels: levels, healthFraction: 0.35).incomingContactDamageMultiplier, 0.8);
});
```

- [ ] **Step 2: Add failing card tests that expose benefits, conditions, and penalties**

```dart
test('augment cards derive compound copy from effect data', () {
  final choices = LevelUpSystem(random: Random(1)).choices(
    unlockedWeaponIds: const {},
    unlockedAugmentIds: {heavyStrike, lastStand, herbalTonic},
    currentWeaponLevels: const {},
    currentAugmentLevels: const {heavyStrike: 1, lastStand: 1},
    maxChoices: 3,
  );
  final copy = {for (final choice in choices) choice.id: choice.effectDescription};
  expect(copy[heavyStrike], '무기 피해 +18% → +36% · 공격 속도 -8% → -16%');
  expect(copy[lastStand], '체력 35% 이하: 받는 접촉 피해 -10% → -20% · 무기 피해 +20% → +40%');
  expect(copy[herbalTonic], '체력 12 회복');
});
```

- [ ] **Step 3: Run both tests and confirm missing resolver/formatter failures**

Run:

```powershell
$env:TEMP='C:\codex-temp'; $env:TMP='C:\codex-temp'; flutter test test/game/augment_effect_resolver_test.dart test/game/level_up_system_test.dart
```

Expected: FAIL because the resolver and data-derived copy do not exist.

- [ ] **Step 4: Implement the pure resolver with safety clamps**

`AugmentModifiers` has base-one multiplier fields, zero additive fields, and an unmodifiable element map. Iterate definitions and skip `onAcquire` effects; skip `healthAtOrBelow35` unless `0 < healthFraction && healthFraction <= 0.35`. Add `effect.valuePerLevel * level` by `AugmentStat`, then return:

```dart
AugmentModifiers(
  weaponDamageMultiplier: max(0, 1 + weaponDamageBonus),
  attackSpeedMultiplier: max(0.1, 1 + attackSpeedBonus),
  criticalChanceBonus: criticalChanceBonus.clamp(0, 1).toDouble(),
  weaponSizeMultiplier: max(0.1, 1 + weaponSizeBonus),
  moveSpeedMultiplier: max(0.1, 1 + moveSpeedBonus),
  incomingContactDamageMultiplier: max(0, 1 + incomingDamageBonus),
  experienceGainMultiplier: max(0, 1 + experienceGainBonus),
  pickupRadiusBonus: pickupRadiusBonus,
  experienceRequirementMultiplier:
      (1 + experienceRequirementBonus).clamp(0.2, 1).toDouble(),
  elementDamageMultipliers: {
    if (fireDamageBonus != 0) ElementType.fire: max(0, 1 + fireDamageBonus),
  },
);
```

- [ ] **Step 5: Implement the stat-based formatter and remove ID allowlists**

Format signed percentages with rounded whole percents, numeric radius/health with `_number`, and join multiple effects with ` · `. Prefix grouped conditional effects once with `체력 35% 이하: `. For `healing`, always return `체력 N 회복`; for `maxHealth`, show cumulative current and next totals. `LevelUpSystem._augmentChoice` should reject only empty `effects` and call:

```dart
effectDescription: const AugmentEffectFormatter().describeLevelChange(
  definition,
  currentLevel,
),
```

Delete `_supportedAugmentIds` and `_augmentDeltaDescription`. Keep weapon formatting unchanged.

- [ ] **Step 6: Run focused tests and commit**

Run:

```powershell
$env:TEMP='C:\codex-temp'; $env:TMP='C:\codex-temp'; flutter test test/game/augment_effect_resolver_test.dart test/game/level_up_system_test.dart
```

Expected: PASS.

```powershell
git add lib/game/systems/augment_effect_resolver.dart lib/game/systems/augment_effect_formatter.dart lib/game/systems/level_up_system.dart test/game/augment_effect_resolver_test.dart test/game/level_up_system_test.dart
git commit -m "feat: resolve and describe augment effects"
```

### Task 3: Game Runtime and Fractional Experience Integration

**Files:**
- Modify: `lib/game/systems/run_progression_system.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `test/game/run_progression_system_test.dart`
- Modify: `test/game/pixel_survivor_game_loop_test.dart`

**Interfaces:**
- Consumes: `AugmentEffectResolver` and `AugmentModifiers` from Task 2.
- Produces: `RunProgressionSystem.addExperience(int amount, {double gainMultiplier = 1, double requirementMultiplier = 1})`.
- Produces: `RunProgressionSystem.experienceRequiredForLevel(int level, {double multiplier = 1})`.

- [ ] **Step 1: Add failing progression tests for fractional gain and reduced thresholds**

```dart
test('fractional gain bonuses accumulate without rounding each pickup', () {
  final progression = RunProgressionSystem();
  progression.addExperience(5, gainMultiplier: 1.1);
  progression.addExperience(5, gainMultiplier: 1.1);
  expect(progression.level, 2);
  expect(progression.currentExperience, 0);
});

test('requirement multiplier applies only when positive experience arrives', () {
  final progression = RunProgressionSystem()..addExperience(9);
  expect(progression.level, 1);
  expect(progression.experienceRequiredForLevel(1, multiplier: 0.85), 10);
  expect(progression.addExperience(0, requirementMultiplier: 0.85), isFalse);
  expect(progression.addExperience(1, requirementMultiplier: 0.85), isTrue);
});
```

- [ ] **Step 2: Add failing game tests for all runtime effect families**

Add one getter aggregation test covering martial training, heavy strike, blood oath, quick step, ghost step, rapid reload, iron armor, hawk eye, powder mastery, goblin fire, scholar insight, ritual shortcut, and pickup radius. Add a boundary test that damages the loaded player to exactly 35% and verifies `lastStand` changes weapon and incoming damage multipliers. Extend the immediate-effect test to verify `innerBreath` and `herbalTonic` apply once on selection, not from merely setting levels.

```dart
expect(game.elementDamageMultipliers[ElementType.fire], closeTo(1.30, 0.0001));
expect(game.experienceGainMultiplier, closeTo(1.20, 0.0001));
expect(game.experienceRequirementMultiplier, closeTo(0.85, 0.0001));
expect(game.experienceToNextLevel, 10);
```

- [ ] **Step 3: Run progression and loop tests to verify failures**

Run:

```powershell
$env:TEMP='C:\codex-temp'; $env:TMP='C:\codex-temp'; flutter test test/game/run_progression_system_test.dart test/game/pixel_survivor_game_loop_test.dart
```

Expected: FAIL because progression does not accept multipliers and the game still uses ID-specific getters.

- [ ] **Step 4: Preserve fractional experience inside `RunProgressionSystem`**

Store `_currentExperience` as `double`, keep the public getter as `int => _currentExperience.floor()`, validate non-finite multipliers back to `1`, and implement:

```dart
bool addExperience(
  int amount, {
  double gainMultiplier = 1,
  double requirementMultiplier = 1,
}) {
  if (amount <= 0) return false;
  final safeGain = gainMultiplier.isFinite ? max(0, gainMultiplier) : 1.0;
  _currentExperience += amount * safeGain;
  var leveledUp = false;
  while (_currentExperience + 1e-9 >=
      experienceRequiredForLevel(_level, multiplier: requirementMultiplier)) {
    _currentExperience -=
        experienceRequiredForLevel(_level, multiplier: requirementMultiplier);
    _level += 1;
    leveledUp = true;
  }
  return leveledUp;
}

int experienceRequiredForLevel(int level, {double multiplier = 1}) {
  final safeMultiplier = multiplier.isFinite
      ? multiplier.clamp(0.2, 1).toDouble()
      : 1.0;
  return ((9 + (level * 2)) * safeMultiplier).ceil();
}
```

Keep `experienceToNextLevel` using multiplier 1 so existing direct-system behavior stays stable; `PixelSurvivorGame` exposes its augmented threshold.

- [ ] **Step 5: Replace game ID switches with resolved modifiers**

Add `AugmentEffectResolver`, resolve with the mounted living player's health fraction, merge passive magic damage with resolved elemental multipliers, and use the result for every existing public getter. Clamp effective pickup bonus so `28 + bonus >= 7` before passing it to both experience gems and spirit jade.

Update gain flow:

```dart
int get experienceToNextLevel => runProgression.experienceRequiredForLevel(
  runProgression.level,
  multiplier: experienceRequirementMultiplier,
);

bool gainExperience(int amount) {
  final leveledUp = runProgression.addExperience(
    amount,
    gainMultiplier: experienceGainMultiplier,
    requirementMultiplier: experienceRequirementMultiplier,
  );
  if (leveledUp && !isLevelUpPending) _queueLevelUpChoices();
  return leveledUp;
}
```

For immediate effects, find the selected definition and iterate only `onAcquire` effects. Dispatch by `AugmentStat.maxHealth` to `increaseMaxHealth(valuePerLevel)` and `AugmentStat.healing` to `heal(valuePerLevel)`. This makes `innerBreath` apply max health +10 and healing +10 exactly once without an ID switch.

- [ ] **Step 6: Run focused gameplay tests and commit**

Run:

```powershell
$env:TEMP='C:\codex-temp'; $env:TMP='C:\codex-temp'; flutter test test/game/run_progression_system_test.dart test/game/pixel_survivor_game_loop_test.dart test/game/combat_system_test.dart test/game/weapon_system_test.dart
```

Expected: PASS.

```powershell
git add lib/game/systems/run_progression_system.dart lib/game/pixel_survivor_game.dart test/game/run_progression_system_test.dart test/game/pixel_survivor_game_loop_test.dart
git commit -m "feat: apply all augment effects in runs"
```

### Task 4: Existing-Save Compatibility Regression and Completion Evidence

**Files:**
- Modify: `test/game/save_system_test.dart`
- Modify: `test/game/run_summary_progression_test.dart`
- Modify: `docs/master-development-todo.md`
- Create: `docs/superpowers/verification/2026-07-16-sixteen-augment-roster.md`

**Interfaces:**
- Consumes: `augmentDefinitions`, `augmentDefinitionFor`, and `startsUnlocked` from Task 1.
- Verifies: existing saves union all current default augment IDs without changing schema version.
- Verifies: run-summary labels continue to come from augment definitions, including new IDs.

- [ ] **Step 1: Add old-save and dynamic-label regression tests**

```dart
test('fromJson adds newly starting augments without unlocking locked ones', () {
  final restored = SaveState.fromJson({
    'schemaVersion': SaveState.currentSchemaVersion,
    'unlockedAugmentIds': [martialTraining],
  });
  expect(
    restored.unlockedAugmentIds,
    containsAll([ironArmorTraining, scholarInsight, bloodOath, ghostStep]),
  );
  expect(restored.unlockedAugmentIds, isNot(contains(lastStand)));
});
```

Add a run-summary assertion using `bloodOath` and expect `피의 맹세`, proving the existing definition lookup handles new IDs without a manual label entry.

- [ ] **Step 2: Run save and summary tests to verify existing generic behavior**

Run:

```powershell
$env:TEMP='C:\codex-temp'; $env:TMP='C:\codex-temp'; flutter test test/game/save_system_test.dart test/game/run_summary_progression_test.dart
```

Expected: PASS. `SaveState._fromSupportedJson` already passes `defaults.unlockedAugmentIds` as `_stringSet` fallback, and `_displayName` already iterates `augmentDefinitions`. If either regression fails, repair only that generic behavior rather than adding new-ID branches.

- [ ] **Step 3: Run the complete focused augment suite**

Run:

```powershell
$env:TEMP='C:\codex-temp'; $env:TMP='C:\codex-temp'; flutter test test/game/content_definitions_test.dart test/game/augment_effect_resolver_test.dart test/game/level_up_system_test.dart test/game/run_progression_system_test.dart test/game/pixel_survivor_game_loop_test.dart test/game/save_system_test.dart test/game/run_summary_progression_test.dart
```

Expected: PASS.

- [ ] **Step 4: Run static analysis and the full test suite once**

Run:

```powershell
$env:TEMP='C:\codex-temp'; $env:TMP='C:\codex-temp'; flutter analyze
$env:TEMP='C:\codex-temp'; $env:TMP='C:\codex-temp'; flutter test
```

Expected: analyzer reports no issues and all tests pass.

- [ ] **Step 5: Record completion and commit**

Mark `CNT-005` and `CNT-006` complete in `docs/master-development-todo.md`, change the next queue to `CNT-007`, and write the exact commands, test counts, analyzer result, and commit IDs to the verification document.

```powershell
git add test/game/save_system_test.dart test/game/run_summary_progression_test.dart docs/master-development-todo.md docs/superpowers/verification/2026-07-16-sixteen-augment-roster.md
git commit -m "feat: complete sixteen augment roster"
git status --short
```

Expected: commit succeeds and status is clean.
