# Unified UI Task 10 report

## Scope

Added deterministic portrait golden coverage for lobby, character select,
stage select, locked compendium, records, pause, and run summary at 390x844,
375x667, and 430x932. Updated player and stage asset contracts for the
current catalog and the intentional stage-presentation `ASSET MISSING` state.
Review follow-up adds distinct logical P0 character portrait paths without
altering `AssetCatalog.player`, uses them only in character select, unlocked
compendium cards, and records, and renders level 6 weapon results with the
shared mastery star rating.

## RED / GREEN

- RED: `D:\FlutterSdk\bin\flutter.bat test test/app/joseon_mobile_surfaces_golden_test.dart`
  failed because each new golden baseline was absent.
- GREEN (generation): `D:\FlutterSdk\bin\flutter.bat test --update-goldens test/app/joseon_mobile_surfaces_golden_test.dart`
  and `... test --update-goldens test/app/joseon_lobby_mobile_golden_test.dart` passed.
- GREEN (verification):
  `D:\FlutterSdk\bin\flutter.bat test test/app/joseon_mobile_surfaces_golden_test.dart test/app/joseon_lobby_mobile_golden_test.dart`
  passed (22 tests).
- GREEN (asset contracts):
  `D:\FlutterSdk\bin\flutter.bat test test/game/player_visual_asset_contract_test.dart test/game/stage_visual_asset_contract_test.dart`
  passed (12 tests).
- GREEN (review follow-up): focused character select, compendium, records,
  and run-summary tests passed (22 tests); the complete Task 10 goldens and
  lobby evidence passed (22 tests); player/stage asset contracts passed
  (13 tests).

## Generated and inspected images

- `character_select_375x667.png`, `character_select_390x844.png`,
  `character_select_430x932.png`
- `stage_select_375x667.png`, `stage_select_390x844.png`,
  `stage_select_430x932.png`
- `compendium_locked_375x667.png`, `compendium_locked_390x844.png`,
  `compendium_locked_430x932.png`
- `records_375x667.png`, `records_390x844.png`, `records_430x932.png`
- `pause_375x667.png`, `pause_390x844.png`, `pause_430x932.png`
- `run_summary_375x667.png`, `run_summary_390x844.png`,
  `run_summary_430x932.png`
- `lobby_mobile_375x667.png`, `lobby_mobile_390x844.png`,
  `lobby_mobile_430x932.png`

## Visual findings

All 21 images were individually inspected. Korean names, integer stats,
and bottom actions are readable and unclipped; no browser-bottom overlap was
observed. The locked compendium has silhouettes and no original art. Stage
selection intentionally exposes a clear `ASSET MISSING` contract state.
The nine impacted character-select, records, and run-summary images were
regenerated and inspected. Character select and records visibly identify the
missing logical portrait path rather than reusing battle art; records expands
its debug-only placeholder so the full key remains readable. Run-summary
level 6 shows exactly five teal stars plus `통달`, with damage and kills on a
separate readable line and no sixth star.

The original lobby icon check treated the solid portions of a valid
`military_tech_outlined` medal as a missing glyph. The test-only check now
captures the actual medal and an unsupported Material icon through the raw
pixel path, requires thin dense edge bands on all four sides, and falls back
to a realistic raw-pixel thin tofu mask if the platform leaves unsupported
glyphs blank.

## Risks

Stage presentation artwork remains intentionally unavailable; the visible
`ASSET MISSING` placeholder is now covered by both goldens and asset contract.
The P0 portrait PNGs remain intentionally absent. Debug UI exposes the full
logical asset key; release builds retain the approved neutral placeholder.

## Commit

`test: cover unified joseon mobile surfaces`

Review follow-up commit: `fix: use logical character portrait placeholders`.

## Release golden font gate

- RED: after loading the Joseon display/body fonts and MaterialIcons, the
  existing release baselines differed as expected: lobby 12.63%, character
  select 6.18%, stage select 3.58%, HUD 0.55%, pause 13.04%, and run summary
  99.99%.
- GREEN: `D:\FlutterSdk\bin\flutter.bat test --update-goldens test/app/release_surface_golden_test.dart`
  passed, followed by the same command without `--update-goldens` (6 tests
  passed).
- Updated and individually inspected: `lobby_16_9.png`,
  `character_select_16_9.png`, `stage_select_16_9.png`,
  `game_hud_16_9.png`, `pause_menu_16_9.png`, and `run_summary_16_9.png`.
- Korean text and Material icons render as glyphs, not tofu; character and
  stage logical missing-art states are visible; HUD and result mastery show
  five teal stars; pause actions and result actions fit without overflow.
- The release fixture now includes a level-6 weapon result so the result
  golden visibly covers five stars, `통달`, damage, and kills.
