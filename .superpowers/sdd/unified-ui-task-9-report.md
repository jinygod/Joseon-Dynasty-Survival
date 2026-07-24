# Task 9 combat UI report

## RED

Added the HUD contract for a keyed kill indicator, an integer kill total, and
level-six mastery. The original HUD failed because `kill-count-icon` was absent.

## GREEN

- HUD retains its 64px, screen-fixed status surface and joystick behavior.
- Kill count uses a compact `Icons.gps_fixed` indicator and integer label.
- Weapon HUD and level-up choices use `WeaponStarRating`; level 6 displays five
  stars and `통달`, never a sixth star.
- Level-up, pause, and run-summary surfaces use shared Joseon panels/buttons.
- Existing pause/resume, choice, navigation, persistence, and sync callbacks
  remain wired through their original handlers.

## Test runner diagnosis

The first focused multi-file test left a Flutter child runner after timeout.
The new pause test also awaited `SharedPreferences.getInstance()` before a test
binding/mock store had been initialized, which produced no test progress.
`game_screen_pause_test.dart` now initializes `TestWidgetsFlutterBinding` and
sets mock preferences in `setUp`, matching `pause_menu_overlay_test.dart`.

## Root QA follow-up

Root's complete pause-screen run found one real failure in
`game screen loads persisted audio settings`: `SwitchListTile` required a
nearest `Material` below the shared `JoseonPanel` decoration. The settings
toggle is now wrapped in a transparent `Material`, and the unreachable legacy
pause-menu implementation was removed.

## Final results

- PASS: `test/app/game_hud_test.dart`
- PASS: `test/app/level_up_overlay_test.dart`
- PASS: `test/app/run_summary_screen_test.dart`
- PASS: `test/app/game_screen_pause_test.dart` (11 tests)
- PASS: all four Task 9 focused files, run sequentially to avoid concurrent
  Flutter runner contention.

## Review follow-up

- Level-up choice copy now uses navy/ink foregrounds on the ivory shared panel.
- HUD now shows only the first (core) weapon mark with an unscaled compact
  `WeaponStarRating`; the 22px mark and rating remain within the fixed 64px
  HUD on the narrow portrait test.
- PASS: the four Task 9 focused files and
  `test/game/run_summary_progression_test.dart`.
- The targeted HUD golden contract assertions pass before image comparison, but
  `game HUD 16:9 golden` differs by 0.29% (2651 pixels), as expected after the
  approved HUD visual redesign. Golden files were intentionally not regenerated.

## Commits

- `ac9a877 feat: unify combat hud and overlays`
- `2b693ae test: initialize pause overlay preferences`
- `fix: restore pause settings material context`

## Files

- `lib/app/game_hud.dart`
- `lib/app/level_up_overlay.dart`
- `lib/app/pause_menu_overlay.dart`
- `lib/app/run_summary_screen.dart`
- `test/app/game_hud_test.dart`
- `test/app/level_up_overlay_test.dart`
- `test/app/game_screen_pause_test.dart`
- `test/app/run_summary_screen_test.dart`

## Risks

The Flame pause-screen test runner may require a clean, non-concurrent Flutter
test process in this Windows environment. No gameplay, balance, save model, or
unrelated UI files were modified.
