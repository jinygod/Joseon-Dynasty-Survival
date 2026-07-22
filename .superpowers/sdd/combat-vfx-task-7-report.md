# Task 7 report: prominent level/XP header and queued multi-level choices

Date: 2026-07-23

## Outcome

- Rebuilt the combat status surface as a SafeArea-contained, available-width HUD with a gold level badge, a 16 px cyan/blue XP track, a bright leading cap, visible numeric XP, and stable `hud-player-level`, `hud-xp-bar`, and `hud-xp-fill` keys.
- Kept a 64 px leading clearance when the 48 px pause control is present. Time, kills, health, and up to three weapon slots remain in the compact row below the level/XP header.
- Preserved the existing aggregate status semantics and weapon-slot semantics. Large system text, landscape layouts, and boss/notice/streak ordering remain within the HUD budget.
- Changed experience gain reporting to preserve the exact number of thresholds crossed without changing the XP requirement curve.
- Added a scalar pending-choice counter. Each accepted choice consumes one count, closes the current overlay, and immediately opens a freshly generated choice set while counts remain.

## RED evidence

1. Initial focused command:

   `flutter test test/app/game_hud_test.dart test/game/run_progression_system_test.dart test/game/pixel_survivor_game_loop_test.dart`

   Expected failures observed:

   - portrait HUD width was `292.0`, below the required `310.0` available-width target;
   - the existing XP track was 9 px and the new level/fill keys were absent;
   - `RunProgressionSystem.addExperience` still returned `bool`, so the typed result API was absent;
   - `PixelSurvivorGame.pendingLevelChoiceCount` was absent.

2. After adding the smallest typed result/count surface, the behavioral RED tests failed for the intended reason:

   - `reports every level crossed by one experience collection`: expected `2`, actual `1`;
   - `queues one choice for every level crossed in one collection`: expected `2`, actual `1`;
   - `keeps later level choices while an overlay choice is pending`: expected `2`, actual `1`.

3. Superseded initial bound-specific RED:

   `flutter test test/game/pixel_survivor_game_loop_test.dart --plain-name "bounds accumulated level choices from oversized experience"`

   Expected `100`, actual `136` before restoring the saturation clamp. The later review found that cap conflicted with the one-choice-per-threshold contract; the review evidence below supersedes this defensive-cap decision.

## GREEN evidence

- `flutter test test/app/game_hud_test.dart --plain-name "portrait HUD keeps combat controls compact"`
  - passed, 1/1.
- `flutter test test/game/run_progression_system_test.dart test/game/pixel_survivor_game_loop_test.dart`
  - passed, 73/73.
- Final requested focused suite:

  `flutter test test/app/game_hud_test.dart test/app/accessibility_surfaces_test.dart test/app/responsive_layout_test.dart test/game/run_progression_system_test.dart test/game/pixel_survivor_game_loop_test.dart`

  - passed, 98/98.
- `flutter analyze`
  - passed with `No issues found`.
- `git diff --check`
  - passed with no whitespace errors.

Golden baselines were intentionally not updated, per the task brief.

## API and flow

### Progression result

`RunProgressionSystem.addExperience(...)` now returns `ExperienceGainResult`:

- `levelsGained`: exact number of XP thresholds crossed by that call;
- `leveledUp`: compatibility convenience getter derived from `levelsGained > 0`.

The level starts at 1 and the existing `9 + level * 2` requirement curve, multiplier handling, fractional accumulation, and overflow carry are unchanged.

### Choice queue

1. `PixelSurvivorGame.gainExperience` adds every reported level gain to the scalar `pendingLevelChoiceCount` without allocating a choice object for each pending threshold or applying an arbitrary saturation cap.
2. If no choice overlay is open, the game generates the first weapon/augment choice set, records weapon offers, emits the level-up cue, pauses the engine, and opens the overlay.
3. A validated selection applies and records the upgrade, clears the displayed set, decrements exactly one pending count, and removes the current overlay.
4. If counts remain, a fresh set is generated and the overlay is immediately re-added without resuming gameplay. Otherwise the engine resumes.
5. Invalid/stale selections do not consume a pending count. Run completion clears both the displayed choices and the pending count.

## Changed files

- `lib/app/game_hud.dart`
- `lib/game/systems/run_progression_system.dart`
- `lib/game/pixel_survivor_game.dart`
- `test/app/game_hud_test.dart`
- `test/app/responsive_layout_test.dart`
- `test/game/run_progression_system_test.dart`
- `test/game/pixel_survivor_game_loop_test.dart`
- `.superpowers/sdd/combat-vfx-task-7-report.md`

`test/app/accessibility_surfaces_test.dart` was exercised unchanged by the focused suite.

## Self-review

- Stable HUD keys are unique and attached to the visible level text, complete XP track, and fractional fill respectively.
- At 390x844 with a 24 px top inset, the status surface stays below the SafeArea edge, begins beyond the pause button, uses at least 310 px of width, exposes a 16 px XP track over 220 px wide, and renders a one-third fill for 4/12 XP.
- The boss warning remains before the status surface, with notices and streaks following it; all tested surfaces stay inside portrait, landscape, and tablet bounds at 2x system text scale.
- No `GameHudSource` property changed. `PixelSurvivorGame.gainExperience` remains a boolean convenience API for existing callers.
- Multi-threshold, overflow, multiplier, representative five-minute balance, overlay-pending accumulation, sequential consumption, invalid selections, and an oversized 136-threshold accumulation are covered.
- The test-only `NoSplash` themes avoid the Flutter test runner requesting an unavailable Material ink shader; production app theming already uses `NoSplash`.

## Review follow-up evidence

### RED

- `flutter test test/game/pixel_survivor_game_loop_test.dart --plain-name "retains every level choice from oversized experience"`
  - failed for the contract reason: expected `136`, actual `100`.
- `flutter test test/app/game_hud_test.dart --plain-name "large kill value stays above health at text scale two"`
  - failed with a `RenderFlex overflowed by 239 pixels on the right` assertion;
  - visible-bounds assertion expected the kill value's right edge at or before `382.0`, actual `500.75`.

### GREEN

- The two targeted tests passed independently after removing the scalar saturation and placing the kill value in a 64x17 `FittedBox` viewport.
- Covering Task 7 suite:

  `flutter test test/app/game_hud_test.dart test/app/accessibility_surfaces_test.dart test/app/responsive_layout_test.dart test/game/run_progression_system_test.dart test/game/pixel_survivor_game_loop_test.dart`

  - passed, 99/99.
- Changed-file analysis:

  `flutter analyze lib/app/game_hud.dart lib/game/pixel_survivor_game.dart test/app/game_hud_test.dart test/game/pixel_survivor_game_loop_test.dart`

  - passed with `No issues found` for all 4 items.

The 20,000-XP case now reaches player level 137 from level 1, retains all 136 pending choices, and decrements to 135 while immediately presenting the next choice set after one accepted selection. At 2x system text scale, even a 19-digit kill count remains horizontally inside the status panel and vertically above the health meter without a render exception.

## Concerns

- Eligible weapon/augment content remains finite; if every available upgrade is exhausted, the pre-existing empty-choice guard clears the pending state rather than presenting an unusable overlay.
- Existing combat/release golden images will change because the HUD composition changed. They were not updated in this task and should be reviewed in the designated golden-update task.
