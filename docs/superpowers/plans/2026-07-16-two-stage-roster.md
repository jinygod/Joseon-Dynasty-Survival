# Two Stage Roster Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a selectable high-pressure `역병 장터` stage whose waves differ materially from the standard `달빛 폐관아` run.

**Architecture:** Stage presentation metadata stays in `stage_definitions.dart`, while stage-specific wave lists stay in `wave_definitions.dart`. `GameScreen` passes the saved stage ID into `PixelSurvivorGame`, which constructs a `WaveDirector` from the central stage wave lookup.

**Tech Stack:** Dart 3.12.2, Flutter 3.44.4, Flame, flutter_test

## Global Constraints

- Both stages remain five-minute runs with one boss request at 270 seconds.
- `WaveDirector.frameSpawnCap` remains 8.
- Existing saves with `moonlit_abandoned_office` remain valid.
- No new image, audio, terrain collision, or boss asset is introduced.

---

### Task 1: Define stage metadata and wave rosters

**Files:**
- Modify: `lib/game/content/stage_definitions.dart`
- Modify: `lib/game/content/wave_definitions.dart`
- Modify: `test/game/content_definitions_test.dart`
- Modify: `test/game/wave_director_test.dart`

**Interfaces:**
- Produces: `plagueMarket`, `StageVisualTheme`, `plagueMarketWaves`, `waveDefinitionsForStage(String)`
- Consumes: existing enemy IDs and `WaveDefinition`

- [ ] **Step 1: Write failing content and pressure tests**

Assert that two stage definitions exist, their IDs/themes/risks differ, the lookup returns different wave lists, all content validates, and plague market pressure exceeds moonlit pressure at 0, 120, and 240 seconds.

```dart
for (final second in [0.0, 120.0, 240.0]) {
  final moonlit = wavePressureForSecond(
    second,
    definitions: waveDefinitionsForStage(moonlitAbandonedOffice),
  );
  final plague = wavePressureForSecond(
    second,
    definitions: waveDefinitionsForStage(plagueMarket),
  );
  expect(plague.spawnsPerSecond, greaterThan(moonlit.spawnsPerSecond));
  expect(plague.maxActiveEnemies, greaterThan(moonlit.maxActiveEnemies));
}
```

- [ ] **Step 2: Run tests and verify RED**

Run: `flutter test test/game/content_definitions_test.dart test/game/wave_director_test.dart`
Expected: compile failures for the new stage and lookup symbols.

- [ ] **Step 3: Add metadata and six plague-market waves**

Define plague waves for 0-60, 60-120, 120-180, 180-240, 240-270, and 270-330 seconds. Use `plagueRatSwarm`, `plagueCrow`, and `rottenHerbalist` as the early identity; mix `graveEmber`, `dokkaebi`, and explicit elite IDs later. Keep the existing list as `waveDefinitions` compatibility data for moonlit.

- [ ] **Step 4: Validate all stage wave lists**

Update `validateWaveContent` to iterate every stage list, check valid ranks and positive weights, and verify continuous non-empty time ranges beginning at zero.

- [ ] **Step 5: Run focused tests and verify GREEN**

Run: `flutter test test/game/content_definitions_test.dart test/game/wave_director_test.dart`
Expected: all selected tests pass.

- [ ] **Step 6: Commit**

Run: `git add lib/game/content/stage_definitions.dart lib/game/content/wave_definitions.dart test/game/content_definitions_test.dart test/game/wave_director_test.dart && git commit -m "feat: define moonlit and plague stage rosters"`

### Task 2: Route selected stages into the game loop

**Files:**
- Modify: `lib/game/systems/wave_director.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Modify: `lib/app/game_screen.dart`
- Modify: `test/game/pixel_survivor_game_loop_test.dart`

**Interfaces:**
- Consumes: `waveDefinitionsForStage(stageId)`, `GameScreen.stageId`
- Produces: `PixelSurvivorGame.stageId` and a stage-configured `WaveDirector`

- [ ] **Step 1: Write a failing game construction test**

Construct `PixelSurvivorGame(stageId: plagueMarket, random: Random(7), ...)`, tick its director at the opening, and assert every normal request belongs to the plague market opening pool.

- [ ] **Step 2: Run test and verify RED**

Run: `flutter test test/game/pixel_survivor_game_loop_test.dart`
Expected: compile failure because `PixelSurvivorGame` has no `stageId` argument.

- [ ] **Step 3: Pass stage data through constructors**

Add a defaulted `stageId` field to `PixelSurvivorGame`, create its director with `waveDefinitionsForStage(stageId)`, and pass `GameScreen.stageId` when the screen creates a game. Keep injected test games unchanged.

```dart
PixelSurvivorGame(
  playerSlot: widget.playerSlot,
  stageId: widget.stageId,
  onRunEnded: _handleRunEnded,
  onAudioCue: _playAudio,
)
```

- [ ] **Step 4: Run game and screen tests**

Run: `flutter test test/game/pixel_survivor_game_loop_test.dart test/app/game_screen_pause_test.dart test/app/lobby_screen_test.dart`
Expected: all selected tests pass.

- [ ] **Step 5: Commit**

Run: `git add lib/game/systems/wave_director.dart lib/game/pixel_survivor_game.dart lib/app/game_screen.dart test/game/pixel_survivor_game_loop_test.dart && git commit -m "feat: route stage waves into game runs"`

### Task 3: Make both stages selectable

**Files:**
- Modify: `lib/app/stage_select_screen.dart`
- Modify: `test/app/stage_select_screen_test.dart`
- Modify: `test/app/responsive_layout_test.dart`

**Interfaces:**
- Consumes: `stageDefinitions`, `StageVisualTheme`, `StageDefinition.backgroundColorValue`
- Produces: tappable keys `stage-moonlit_abandoned_office` and `stage-plague_market`

- [ ] **Step 1: Write a failing selection test**

Pump the screen with moonlit selected, tap `stage-plague_market`, confirm, and assert the returned ID is `plagueMarket`. Also assert both Korean names and the `위험` risk label are visible after selection.

- [ ] **Step 2: Run widget tests and verify RED**

Run: `flutter test test/app/stage_select_screen_test.dart`
Expected: the plague market card finder returns no widgets.

- [ ] **Step 3: Render two stage cards**

Replace the single selected card with an expanded row generated from `stageDefinitions`. Map `StageVisualTheme.moonlit` to `Icons.nightlight_round` and plague to `Icons.coronavirus_outlined`; use the definition background color and a gold selected border.

- [ ] **Step 4: Run selection and responsive tests**

Run: `flutter test test/app/stage_select_screen_test.dart test/app/responsive_layout_test.dart`
Expected: all selected tests pass with no overflow exceptions at supported sizes.

- [ ] **Step 5: Commit**

Run: `git add lib/app/stage_select_screen.dart test/app/stage_select_screen_test.dart test/app/responsive_layout_test.dart && git commit -m "feat: add plague market stage selection"`

### Task 4: Update delivery tracking

**Files:**
- Modify: `docs/master-development-todo.md`
- Create: `docs/superpowers/verification/2026-07-16-two-stage-and-audio-mute.md`

**Interfaces:**
- Consumes: fresh test, analyze, web build, and Android debug build results
- Produces: completed `CNT-009`, `CNT-010`, and documented audio regression fix

- [ ] **Step 1: Run full verification**

Run: `dart format --output=none --set-exit-if-changed lib test`, `dart analyze`, `flutter test`, `flutter build web`, and `flutter build apk --debug` through the ASCII drive mappings.

- [ ] **Step 2: Record exact evidence**

Write the command outcomes, test count, and changed behavior to the verification document. Mark `CNT-009` and `CNT-010` complete only after all required commands exit zero.

- [ ] **Step 3: Commit**

Run: `git add docs/master-development-todo.md docs/superpowers/verification/2026-07-16-two-stage-and-audio-mute.md && git commit -m "test: verify stages and realtime audio mute"`
