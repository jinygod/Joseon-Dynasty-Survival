# Unified Joseon UI Task 11 Report

## Implemented contracts

- Character selection presents truthful Korean unlock conditions: rookie is
  `기본 해금`, exorcist requires one boss defeat, and mountain hunter requires
  three boss defeats. The presentation goal IDs are contract-tested against
  configured unlock goals.
- Weapon history retains only recorded usage, kills, and damage; each row now
  explicitly says `최고 등급 미집계` because historical weapon levels are absent.
- Stage cards explicitly say `최고 기록 미집계` and `클리어 상태 미집계`.
  Moonlit Office advertises `역병 장터 해금`; Plague Market uses
  `주요 보상 준비 중` rather than a fabricated reward.
- The compact HUD remains core-weapon-only. Tests cover 375x667, 390x844, and
  430x932 with multiple weapon labels, readable mastery, no extra slots, and
  unchanged joystick size.

## Files changed

- `lib/game/content/character_definitions.dart`
- `lib/app/character_select_screen.dart`
- `lib/game/content/stage_definitions.dart`
- `lib/app/stage_select_screen.dart`
- `lib/app/records_screen.dart`
- Focused tests under `test/app` and `test/game`.

## Verification

`flutter test test/app/character_select_screen_test.dart test/game/character_unlock_presentation_contract_test.dart test/app/records_screen_test.dart test/app/stage_select_screen_test.dart test/game/stage_presentation_contract_test.dart test/app/game_hud_test.dart`

Result: all 40 focused tests passed.

`flutter test test/app/joseon_mobile_surfaces_golden_test.dart`

Result: all 18 mobile golden tests passed after visually inspecting and
updating only the three stage-select baselines and the records baseline.

## Risks / follow-up

- The save schema deliberately remains unchanged. Weapon levels and per-stage
  best/clear records cannot be truthfully recovered from historical telemetry.
- The approved design document now records this data-flow exception: no
  persisted per-weapon mastery or per-stage best/clear fields, no migration,
  and explicit `미집계` presentation.
