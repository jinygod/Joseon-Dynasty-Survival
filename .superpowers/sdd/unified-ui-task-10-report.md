# Unified UI Task 10 report

## Scope

Added deterministic portrait golden coverage for lobby, character select,
stage select, locked compendium, records, pause, and run summary at 390x844,
375x667, and 430x932. Updated player and stage asset contracts for the
current catalog and the intentional stage-presentation `ASSET MISSING` state.

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
Run-summary level 6 is text-only and shows no erroneous sixth star.

The original lobby icon check treated the solid portions of a valid
`military_tech_outlined` medal as a missing glyph. The test-only check now
requires thin dense edge bands on all four sides, and includes synthetic tofu
and medal-mask evidence. No production UI code was changed.

## Risks

Stage presentation artwork remains intentionally unavailable; the visible
`ASSET MISSING` placeholder is now covered by both goldens and asset contract.
The mobile character card still displays the approved sprite sheet rather
than newly invented artwork.

## Commit

`test: cover unified joseon mobile surfaces`
