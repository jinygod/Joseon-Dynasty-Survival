# Pixel Survivor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first Flutter + Flame playable MVP for Pixel Survivor with solo survival, unlockable progression, AI pixel-art asset structure, and architecture that keeps same-device two-player co-op possible.

**Architecture:** Flutter owns the app shell, menus, overlays, and persistence. Flame owns the real-time game world, components, collision, spawning, and weapon updates. Gameplay content is data-driven so weapons, augments, monsters, characters, unlock goals, and future co-op player entities can grow without rewriting the core loop.

**Tech Stack:** Flutter, Dart, Flame, flame_test, flutter_test, shared_preferences, Git.

---

## Scope Notes

The first implemented game mode is solo. Two-player co-op is not implemented in this plan, but the player/input/enemy-targeting architecture must not assume there can only ever be one player.

Flutter is not currently available on PATH in this workspace. Task 1 installs or links Flutter before scaffolding the app.

## File Structure

Expected project files after scaffolding:

- `pubspec.yaml`: dependencies, assets, app metadata.
- `lib/main.dart`: Flutter entry point and top-level app.
- `lib/app/pixel_survivor_app.dart`: app shell, theme, route to menu.
- `lib/app/main_menu_screen.dart`: start screen, unlock summary, start-run button.
- `lib/app/run_summary_screen.dart`: post-run summary and unlock notices.
- `lib/game/pixel_survivor_game.dart`: Flame game root, run timer, game state orchestration.
- `lib/game/models/vector_input.dart`: normalized movement input.
- `lib/game/models/player_slot.dart`: player slot id and selected character.
- `lib/game/components/player_component.dart`: player movement, health, pickup radius.
- `lib/game/components/enemy_component.dart`: enemy movement, health, contact damage.
- `lib/game/components/projectile_component.dart`: projectile behavior for Magic Bolt and Ice Shard.
- `lib/game/components/experience_gem_component.dart`: pickup and level experience.
- `lib/game/systems/spawn_system.dart`: timed enemy spawning.
- `lib/game/systems/weapon_system.dart`: automatic weapon ticking and upgrades.
- `lib/game/systems/level_up_system.dart`: experience thresholds and choice generation.
- `lib/game/systems/progression_system.dart`: unlock goal evaluation.
- `lib/game/systems/save_system.dart`: local save load and write.
- `lib/game/content/character_definitions.dart`: character data.
- `lib/game/content/weapon_definitions.dart`: weapon data.
- `lib/game/content/augment_definitions.dart`: augment data.
- `lib/game/content/enemy_definitions.dart`: monster and boss data.
- `lib/game/content/unlock_definitions.dart`: unlock goals.
- `lib/game/content/asset_catalog.dart`: logical asset ids and paths.
- `test/game/progression_system_test.dart`: unlock tests.
- `test/game/level_up_system_test.dart`: level-up choice tests.
- `test/game/save_system_test.dart`: save default tests.
- `test/game/weapon_system_test.dart`: weapon upgrade tests.
- `assets/images/...`: generated pixel-art assets and simple development fallback images.
- `docs/assets/pixel-art-prompts.md`: prompts and asset metadata.

## Task 1: Prepare Flutter Toolchain

**Files:**
- Read: `docs/superpowers/specs/2026-06-30-pixel-survivor-design.md`

- [ ] **Step 1: Check Flutter availability**

Run:

```powershell
flutter --version
```

Expected now: FAIL with `flutter : The term 'flutter' is not recognized`.

- [ ] **Step 2: Install or expose Flutter SDK**

Install Flutter for Windows from the official SDK instructions, or add an existing Flutter SDK `bin` directory to PATH for this shell.

If Flutter is already installed at `C:\src\flutter`, run:

```powershell
$env:Path = "C:\src\flutter\bin;$env:Path"
flutter --version
```

Expected: Flutter prints a version and Dart version.

- [ ] **Step 3: Run doctor**

Run:

```powershell
flutter doctor
```

Expected: Flutter is available. Android toolchain warnings are acceptable for this task, but the command must run.

- [ ] **Step 4: Commit if PATH helper files were added**

Only commit if a repo file was created, such as a setup note.

```powershell
git status --short
git add docs/setup.md
git commit -m "docs: add Flutter setup notes"
```

Expected: commit only when `docs/setup.md` exists.

## Task 2: Scaffold Flutter App

**Files:**
- Create: Flutter project files in repository root
- Modify: `pubspec.yaml`
- Create: `lib/app/pixel_survivor_app.dart`
- Create: `lib/app/main_menu_screen.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Create Flutter project in the existing repository**

Run:

```powershell
flutter create --project-name pixel_survivor --org com.pixel.survivor .
```

Expected: `lib/main.dart`, `pubspec.yaml`, `android/`, `ios/`, `test/`, and platform files are created.

- [ ] **Step 2: Add dependencies**

Update `pubspec.yaml` dependencies to include:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flame: ^1.18.0
  shared_preferences: ^2.2.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  flame_test: ^1.16.0
  flutter_lints: ^4.0.0
```

Run:

```powershell
flutter pub get
```

Expected: dependencies resolve without errors.

- [ ] **Step 3: Replace `lib/main.dart`**

Use:

```dart
import 'package:flutter/material.dart';
import 'app/pixel_survivor_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PixelSurvivorApp());
}
```

- [ ] **Step 4: Create `lib/app/pixel_survivor_app.dart`**

Use:

```dart
import 'package:flutter/material.dart';
import 'main_menu_screen.dart';

class PixelSurvivorApp extends StatelessWidget {
  const PixelSurvivorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixel Survivor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff3fbf7f)),
        useMaterial3: true,
      ),
      home: const MainMenuScreen(),
    );
  }
}
```

- [ ] **Step 5: Create `lib/app/main_menu_screen.dart`**

Use:

```dart
import 'package:flutter/material.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pixel Survivor', style: TextStyle(fontSize: 32)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {},
                child: const Text('Start Run'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Verify**

Run:

```powershell
flutter test
```

Expected: default tests may need removal if they reference the old counter app. If so, delete the generated counter test and rerun until PASS.

- [ ] **Step 7: Commit**

```powershell
git add .
git commit -m "feat: scaffold Flutter app"
```

Expected: one commit containing the generated Flutter shell and app entry point.

## Task 3: Add Core Content Models

**Files:**
- Create: `lib/game/content/ids.dart`
- Create: `lib/game/content/character_definitions.dart`
- Create: `lib/game/content/weapon_definitions.dart`
- Create: `lib/game/content/augment_definitions.dart`
- Create: `lib/game/content/enemy_definitions.dart`
- Create: `lib/game/content/unlock_definitions.dart`

- [ ] **Step 1: Create ids and model records**

Create `lib/game/content/ids.dart`:

```dart
typedef CharacterId = String;
typedef WeaponId = String;
typedef AugmentId = String;
typedef EnemyId = String;
typedef UnlockGoalId = String;

enum ElementType { physical, magic, fire, ice, lightning }

enum UnlockMetric {
  bestSurvivalSeconds,
  totalKills,
  levelReachedInRun,
  bossDefeats,
  unlockedWeaponCount,
  lowHealthWinCount,
}

class CharacterDefinition {
  const CharacterDefinition({
    required this.id,
    required this.name,
    required this.maxHealth,
    required this.moveSpeed,
    required this.damageMultiplier,
    required this.startingWeaponId,
  });

  final CharacterId id;
  final String name;
  final double maxHealth;
  final double moveSpeed;
  final double damageMultiplier;
  final WeaponId startingWeaponId;
}

class WeaponDefinition {
  const WeaponDefinition({
    required this.id,
    required this.name,
    required this.element,
    required this.maxLevel,
    required this.startsUnlocked,
  });

  final WeaponId id;
  final String name;
  final ElementType element;
  final int maxLevel;
  final bool startsUnlocked;
}

class AugmentDefinition {
  const AugmentDefinition({
    required this.id,
    required this.name,
    required this.maxLevel,
    required this.startsUnlocked,
  });

  final AugmentId id;
  final String name;
  final int maxLevel;
  final bool startsUnlocked;
}

class EnemyDefinition {
  const EnemyDefinition({
    required this.id,
    required this.name,
    required this.maxHealth,
    required this.moveSpeed,
    required this.damage,
    required this.experience,
    this.isBoss = false,
  });

  final EnemyId id;
  final String name;
  final double maxHealth;
  final double moveSpeed;
  final double damage;
  final int experience;
  final bool isBoss;
}

class UnlockGoalDefinition {
  const UnlockGoalDefinition({
    required this.id,
    required this.description,
    required this.metric,
    required this.threshold,
    this.unlocksCharacterId,
    this.unlocksWeaponId,
    this.unlocksAugmentId,
  });

  final UnlockGoalId id;
  final String description;
  final UnlockMetric metric;
  final int threshold;
  final CharacterId? unlocksCharacterId;
  final WeaponId? unlocksWeaponId;
  final AugmentId? unlocksAugmentId;
}
```

- [ ] **Step 2: Add content definitions**

Create definition files using the spec names:

```dart
// lib/game/content/weapon_definitions.dart
import 'ids.dart';

const magicBolt = 'magic_bolt';
const bladeArc = 'blade_arc';
const orbitingDagger = 'orbiting_dagger';
const lightningStrike = 'lightning_strike';
const flameField = 'flame_field';
const iceShard = 'ice_shard';

const weaponDefinitions = <WeaponDefinition>[
  WeaponDefinition(id: magicBolt, name: 'Magic Bolt', element: ElementType.magic, maxLevel: 5, startsUnlocked: true),
  WeaponDefinition(id: bladeArc, name: 'Blade Arc', element: ElementType.physical, maxLevel: 5, startsUnlocked: true),
  WeaponDefinition(id: orbitingDagger, name: 'Orbiting Dagger', element: ElementType.physical, maxLevel: 5, startsUnlocked: false),
  WeaponDefinition(id: lightningStrike, name: 'Lightning Strike', element: ElementType.lightning, maxLevel: 5, startsUnlocked: false),
  WeaponDefinition(id: flameField, name: 'Flame Field', element: ElementType.fire, maxLevel: 5, startsUnlocked: false),
  WeaponDefinition(id: iceShard, name: 'Ice Shard', element: ElementType.ice, maxLevel: 5, startsUnlocked: false),
];
```

Create `lib/game/content/character_definitions.dart`:

```dart
import 'ids.dart';
import 'weapon_definitions.dart';

const apprenticeWanderer = 'apprentice_wanderer';
const ironPilgrim = 'iron_pilgrim';

const characterDefinitions = <CharacterDefinition>[
  CharacterDefinition(
    id: apprenticeWanderer,
    name: 'Apprentice Wanderer',
    maxHealth: 100,
    moveSpeed: 130,
    damageMultiplier: 1,
    startingWeaponId: magicBolt,
  ),
  CharacterDefinition(
    id: ironPilgrim,
    name: 'Iron Pilgrim',
    maxHealth: 140,
    moveSpeed: 105,
    damageMultiplier: 0.95,
    startingWeaponId: bladeArc,
  ),
];
```

Create `lib/game/content/augment_definitions.dart`:

```dart
import 'ids.dart';

const attackUp = 'attack_up';
const haste = 'haste';
const swiftFeet = 'swift_feet';
const vitality = 'vitality';
const magnetSense = 'magnet_sense';
const recovery = 'recovery';
const extraProjectile = 'extra_projectile';
const criticalSpark = 'critical_spark';
const elementFocus = 'element_focus';
const desperation = 'desperation';
const evolutionShortcut = 'evolution_shortcut';
const heavyImpact = 'heavy_impact';

const augmentDefinitions = <AugmentDefinition>[
  AugmentDefinition(id: attackUp, name: 'Attack Up', maxLevel: 5, startsUnlocked: true),
  AugmentDefinition(id: haste, name: 'Haste', maxLevel: 5, startsUnlocked: true),
  AugmentDefinition(id: swiftFeet, name: 'Swift Feet', maxLevel: 5, startsUnlocked: true),
  AugmentDefinition(id: vitality, name: 'Vitality', maxLevel: 5, startsUnlocked: true),
  AugmentDefinition(id: magnetSense, name: 'Magnet Sense', maxLevel: 5, startsUnlocked: true),
  AugmentDefinition(id: recovery, name: 'Recovery', maxLevel: 5, startsUnlocked: true),
  AugmentDefinition(id: extraProjectile, name: 'Extra Projectile', maxLevel: 1, startsUnlocked: false),
  AugmentDefinition(id: criticalSpark, name: 'Critical Spark', maxLevel: 5, startsUnlocked: false),
  AugmentDefinition(id: elementFocus, name: 'Element Focus', maxLevel: 5, startsUnlocked: false),
  AugmentDefinition(id: desperation, name: 'Desperation', maxLevel: 3, startsUnlocked: false),
  AugmentDefinition(id: evolutionShortcut, name: 'Evolution Shortcut', maxLevel: 1, startsUnlocked: false),
  AugmentDefinition(id: heavyImpact, name: 'Heavy Impact', maxLevel: 5, startsUnlocked: false),
];
```

Create `lib/game/content/enemy_definitions.dart`:

```dart
import 'ids.dart';

const slime = 'slime';
const bat = 'bat';
const armoredHusk = 'armored_husk';
const spitter = 'spitter';
const graveGolem = 'grave_golem';

const enemyDefinitions = <EnemyDefinition>[
  EnemyDefinition(id: slime, name: 'Slime', maxHealth: 12, moveSpeed: 45, damage: 8, experience: 1),
  EnemyDefinition(id: bat, name: 'Bat', maxHealth: 8, moveSpeed: 85, damage: 6, experience: 1),
  EnemyDefinition(id: armoredHusk, name: 'Armored Husk', maxHealth: 35, moveSpeed: 32, damage: 12, experience: 3),
  EnemyDefinition(id: spitter, name: 'Spitter', maxHealth: 20, moveSpeed: 38, damage: 10, experience: 2),
  EnemyDefinition(id: graveGolem, name: 'Grave Golem', maxHealth: 650, moveSpeed: 28, damage: 18, experience: 20, isBoss: true),
];
```

Create `lib/game/content/unlock_definitions.dart`:

```dart
import 'augment_definitions.dart';
import 'character_definitions.dart';
import 'ids.dart';
import 'weapon_definitions.dart';

const unlockGoals = <UnlockGoalDefinition>[
  UnlockGoalDefinition(
    id: 'survive_3_minutes',
    description: 'Survive for 3 minutes once.',
    metric: UnlockMetric.bestSurvivalSeconds,
    threshold: 180,
    unlocksWeaponId: orbitingDagger,
  ),
  UnlockGoalDefinition(
    id: 'defeat_300_monsters',
    description: 'Defeat 300 monsters total.',
    metric: UnlockMetric.totalKills,
    threshold: 300,
    unlocksWeaponId: lightningStrike,
  ),
  UnlockGoalDefinition(
    id: 'reach_level_10',
    description: 'Reach level 10 in one run.',
    metric: UnlockMetric.levelReachedInRun,
    threshold: 10,
    unlocksWeaponId: iceShard,
    unlocksAugmentId: extraProjectile,
  ),
  UnlockGoalDefinition(
    id: 'defeat_first_boss',
    description: 'Defeat the first boss once.',
    metric: UnlockMetric.bossDefeats,
    threshold: 1,
    unlocksCharacterId: ironPilgrim,
  ),
  UnlockGoalDefinition(
    id: 'survive_5_minutes',
    description: 'Survive for 5 minutes once.',
    metric: UnlockMetric.bestSurvivalSeconds,
    threshold: 300,
    unlocksAugmentId: criticalSpark,
  ),
  UnlockGoalDefinition(
    id: 'unlock_three_weapons',
    description: 'Unlock three weapons.',
    metric: UnlockMetric.unlockedWeaponCount,
    threshold: 3,
    unlocksAugmentId: elementFocus,
  ),
  UnlockGoalDefinition(
    id: 'defeat_500_monsters',
    description: 'Defeat 500 monsters total.',
    metric: UnlockMetric.totalKills,
    threshold: 500,
    unlocksWeaponId: flameField,
  ),
  UnlockGoalDefinition(
    id: 'low_health_win',
    description: 'Win a run with less than 30 percent health remaining.',
    metric: UnlockMetric.lowHealthWinCount,
    threshold: 1,
    unlocksAugmentId: desperation,
  ),
];
```

- [ ] **Step 3: Analyze**

Run:

```powershell
flutter analyze
```

Expected: no analyzer errors.

- [ ] **Step 4: Commit**

```powershell
git add lib/game/content
git commit -m "feat: add gameplay content definitions"
```

## Task 4: Add Save and Progression Rules

**Files:**
- Create: `lib/game/systems/save_system.dart`
- Create: `lib/game/systems/progression_system.dart`
- Create: `test/game/progression_system_test.dart`
- Create: `test/game/save_system_test.dart`

- [ ] **Step 1: Write progression tests**

Create tests that prove unlock goals work:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/systems/progression_system.dart';

void main() {
  test('surviving 180 seconds unlocks orbiting dagger', () {
    final save = SaveState.defaults().copyWith(bestSurvivalSeconds: 180);
    final result = ProgressionSystem().evaluate(save);
    expect(result.unlockedWeaponIds, contains('orbiting_dagger'));
  });

  test('defeating first boss unlocks iron pilgrim', () {
    final save = SaveState.defaults().copyWith(bossDefeats: 1);
    final result = ProgressionSystem().evaluate(save);
    expect(result.unlockedCharacterIds, contains('iron_pilgrim'));
  });
}
```

- [ ] **Step 2: Run tests and confirm failure**

Run:

```powershell
flutter test test/game/progression_system_test.dart
```

Expected: FAIL because `ProgressionSystem` and `SaveState` do not exist.

- [ ] **Step 3: Implement save state and progression**

Create `SaveState` with unlocked id sets and counters. Create `ProgressionSystem.evaluate` to apply goals from `unlock_definitions.dart`.

Required behavior:

- Defaults unlock `apprentice_wanderer`, `magic_bolt`, `blade_arc`, and starting augments.
- Unlock evaluation is repeatable and does not remove existing unlocks.
- Counters are integers.

- [ ] **Step 4: Run tests**

```powershell
flutter test test/game/progression_system_test.dart test/game/save_system_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add lib/game/systems test/game
git commit -m "feat: add save progression rules"
```

## Task 5: Add Flame Game Shell

**Files:**
- Create: `lib/game/pixel_survivor_game.dart`
- Modify: `lib/app/main_menu_screen.dart`
- Create: `lib/app/game_screen.dart`
- Create: `lib/game/models/player_slot.dart`
- Create: `lib/game/models/vector_input.dart`

- [ ] **Step 1: Create co-op-ready player slot model**

Use:

```dart
class PlayerSlot {
  const PlayerSlot({
    required this.index,
    required this.characterId,
    this.isActive = true,
  });

  final int index;
  final String characterId;
  final bool isActive;
}
```

- [ ] **Step 2: Create vector input model**

Use:

```dart
class VectorInput {
  const VectorInput(this.x, this.y);

  static const zero = VectorInput(0, 0);

  final double x;
  final double y;
}
```

- [ ] **Step 3: Create Flame game root**

`PixelSurvivorGame` should extend `FlameGame` and accept `List<PlayerSlot> playerSlots`. The first run passes one active slot, but the list shape preserves the co-op path.

- [ ] **Step 4: Add game screen**

Create a `GameWidget` wrapper and navigate to it from `Start Run`.

- [ ] **Step 5: Verify**

Run:

```powershell
flutter test
flutter analyze
```

Expected: PASS and no analyzer errors.

- [ ] **Step 6: Commit**

```powershell
git add lib/app lib/game
git commit -m "feat: add Flame game shell"
```

## Task 6: Implement Player, Enemies, and Spawning

**Files:**
- Create: `lib/game/components/player_component.dart`
- Create: `lib/game/components/enemy_component.dart`
- Create: `lib/game/systems/spawn_system.dart`
- Test: `test/game/spawn_system_test.dart`

- [ ] **Step 1: Test spawn schedule**

Create a test proving early seconds spawn slimes and later seconds include bats and armored husks.

- [ ] **Step 2: Implement spawn system**

`SpawnSystem.enemiesForSecond(int second)` returns enemy ids based on timer bands:

- 0 to 59: `slime`
- 60 to 119: `slime`, `bat`
- 120 to 299: `slime`, `bat`, `armored_husk`, `spitter`
- 300 and above: `grave_golem`

- [ ] **Step 3: Implement components**

Player component:

- Stores slot index.
- Stores health.
- Moves from `VectorInput`.

Enemy component:

- Stores enemy definition id.
- Moves toward nearest active player component.
- Deals contact damage.

- [ ] **Step 4: Verify**

```powershell
flutter test test/game/spawn_system_test.dart
flutter analyze
```

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add lib/game/components lib/game/systems test/game
git commit -m "feat: add player enemy spawning"
```

## Task 7: Implement Weapons and Experience

**Files:**
- Create: `lib/game/components/projectile_component.dart`
- Create: `lib/game/components/experience_gem_component.dart`
- Create: `lib/game/systems/weapon_system.dart`
- Create: `test/game/weapon_system_test.dart`

- [ ] **Step 1: Test weapon upgrade caps**

Test that Magic Bolt cannot exceed level 5 and locked weapons cannot be offered before unlock.

- [ ] **Step 2: Implement first four weapons**

Implement:

- Magic Bolt.
- Blade Arc.
- Orbiting Dagger.
- Lightning Strike.

Use Flame rectangle or circle components as visible development fallback art if pixel sprites are not ready.

- [ ] **Step 3: Implement experience gem pickup**

Gems add experience when the player is within pickup radius. Magnet Sense modifies the radius.

- [ ] **Step 4: Verify**

```powershell
flutter test test/game/weapon_system_test.dart
flutter analyze
```

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add lib/game/components lib/game/systems test/game
git commit -m "feat: add weapons and experience"
```

## Task 8: Implement Level-Up Choices and Augments

**Files:**
- Create: `lib/game/systems/level_up_system.dart`
- Create: `lib/app/level_up_overlay.dart`
- Create: `test/game/level_up_system_test.dart`

- [ ] **Step 1: Test choices**

Tests:

- Choices count is three when at least three valid choices exist.
- Locked augments do not appear.
- Max-level weapons do not appear.

- [ ] **Step 2: Implement level-up system**

The system accepts unlocked weapons, unlocked augments, current weapon levels, and current augment levels. It returns three choices where possible.

- [ ] **Step 3: Implement overlay**

The overlay pauses gameplay and shows three touch-friendly buttons. Selecting one applies it and resumes gameplay.

- [ ] **Step 4: Verify**

```powershell
flutter test test/game/level_up_system_test.dart
flutter analyze
```

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add lib/app lib/game/systems test/game
git commit -m "feat: add level up choices"
```

## Task 9: Implement Run Summary and Unlock Notices

**Files:**
- Create: `lib/app/run_summary_screen.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `lib/game/systems/progression_system.dart`

- [ ] **Step 1: Add run result model**

Create a model with:

- `survivalSeconds`
- `kills`
- `level`
- `bossDefeated`
- `wonWithLowHealth`
- `weaponKillCounts`

- [ ] **Step 2: Apply run result to save**

Update best survival time, total kills, boss defeats, and goal completion.

- [ ] **Step 3: Show summary**

Display survived time, kills, level, and newly unlocked content.

- [ ] **Step 4: Verify**

```powershell
flutter test
flutter analyze
```

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add lib/app lib/game
git commit -m "feat: add run summary unlocks"
```

## Task 10: Add Pixel-Art Asset Structure

**Files:**
- Create: `assets/images/player/.gitkeep`
- Create: `assets/images/characters/.gitkeep`
- Create: `assets/images/monsters/.gitkeep`
- Create: `assets/images/weapons/.gitkeep`
- Create: `assets/images/effects/.gitkeep`
- Create: `assets/images/stages/.gitkeep`
- Create: `assets/images/ui/.gitkeep`
- Create: `docs/assets/pixel-art-prompts.md`
- Modify: `pubspec.yaml`
- Create: `lib/game/content/asset_catalog.dart`

- [ ] **Step 1: Add asset folders**

Create the folders listed above.

- [ ] **Step 2: Add prompt document**

Document prompts for:

- Apprentice Wanderer.
- Iron Pilgrim.
- Slime.
- Bat.
- Armored Husk.
- Spitter.
- Grave Golem.
- Six weapon icons.
- Twelve augment icons.
- Experience gem.
- Health pickup.
- Ruined grassland tile.

- [ ] **Step 3: Register assets**

Add to `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/images/player/
    - assets/images/characters/
    - assets/images/monsters/
    - assets/images/weapons/
    - assets/images/effects/
    - assets/images/stages/
    - assets/images/ui/
```

- [ ] **Step 4: Add catalog**

Create a map from logical ids to paths for the generated images. For assets that are not generated yet, keep the logical id out of the catalog and let development fallback art render instead.

- [ ] **Step 5: Verify**

```powershell
flutter pub get
flutter test
```

Expected: PASS.

- [ ] **Step 6: Commit**

```powershell
git add assets docs/assets pubspec.yaml lib/game/content/asset_catalog.dart
git commit -m "chore: add pixel art asset pipeline"
```

## Task 11: Generate First AI Pixel-Art Batch

**Files:**
- Add: PNG files under `assets/images/...`
- Modify: `docs/assets/pixel-art-prompts.md`
- Modify: `lib/game/content/asset_catalog.dart`

- [ ] **Step 1: Generate transparent sprites**

Generate small pixel-art PNGs for the first playable set:

- Apprentice Wanderer idle.
- Slime.
- Bat.
- Armored Husk.
- Grave Golem.
- Magic Bolt icon.
- Blade Arc icon.
- Orbiting Dagger icon.
- Lightning Strike icon.
- Experience gem.
- Ruined grassland tile.

- [ ] **Step 2: Update catalog paths**

Point each logical id to the generated PNG.

- [ ] **Step 3: Run visual smoke test**

Run the app on an available target:

```powershell
flutter run
```

Expected: menu loads and game starts without missing-asset exceptions.

- [ ] **Step 4: Commit**

```powershell
git add assets docs/assets lib/game/content/asset_catalog.dart
git commit -m "art: add first pixel asset batch"
```

## Task 12: Mobile Build Preparation

**Files:**
- Modify: `android/app/build.gradle`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `pubspec.yaml`
- Create: `docs/release/android-checklist.md`

- [ ] **Step 1: Set app identity**

Use app label `Pixel Survivor` and package `com.pixel.survivor`.

- [ ] **Step 2: Add Android release checklist**

Include:

- App icon required.
- Signing key required.
- Version name/code update.
- Play Store graphics required.
- Privacy policy decision required if analytics or ads are added.

- [ ] **Step 3: Build debug APK**

Run:

```powershell
flutter build apk --debug
```

Expected: debug APK builds successfully.

- [ ] **Step 4: Commit**

```powershell
git add android pubspec.yaml docs/release
git commit -m "chore: prepare Android build"
```

## Self-Review

Spec coverage:

- Flutter + Flame app: Tasks 1, 2, and 5.
- Solo survival loop: Tasks 5, 6, 7, 8, and 9.
- Unlockable weapons, augments, and character progress: Tasks 3, 4, 8, and 9.
- More than two weapon designs: Task 3 defines six; Task 7 implements the first four.
- AI pixel-art pipeline: Tasks 10 and 11.
- Git history: every task ends with a commit.
- Future two-player possibility: Tasks 5 and 6 use player slots, input abstractions, and nearest-active-player targeting.
- Mobile app release path: Task 12.

Known deferred work:

- Online co-op is intentionally out of scope.
- Same-device two-player gameplay is prepared architecturally but not implemented.
- Flame Field and Ice Shard can be implemented after the first four weapons work.
