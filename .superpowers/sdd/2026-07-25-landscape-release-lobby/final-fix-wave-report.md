# Final lobby fix wave

Base HEAD: `4541fd51606f767ca846ebd5a4cb276ddf10576a`

## Implemented reviewer fixes

1. `LobbyBattleStage` now receives `onStageSelect`; the visible stage plaque
   itself owns `Key('lobby-stage')` and the tap callback. The redundant
   positioned listener was removed from `LobbyScreen`.
2. Added `LobbyFeature.weapon` with the Korean notice copy `무기고` / `전투에 쓸
   무기를 정비하고 있습니다.` and mapped the weapon quick action to it.
3. Replaced the profile `Icons.person_outline` with the approved
   `AssetCatalog.lobbyIcons['character']` raster asset.
4. Increased the permanent-account `sync-now` positioned control and child to
   an actual minimum 48 by 48 logical-pixel bound.

## Tests and checks

- TDD RED: the new feature/interface tests initially failed because
  `LobbyFeature.weapon` and `LobbyBattleStage.onStageSelect` did not exist;
  the three viewport tests also demonstrated the prior detached stage hit
  target's rect differed from the plaque.
- GREEN verification:
  `flutter test test/app/lobby_screen_test.dart test/app/lobby_release_layout_test.dart test/app/lobby_feature_notice_test.dart test/app/joseon_lobby_mobile_golden_test.dart`
  — 30 passed.
- `flutter analyze` — no issues found.

## Golden comparison

Replacing the stock profile glyph changed only the profile-icon pixels:

- `lobby_1280x720.png`: 1,442 pixels (0.16%)
- `lobby_1170x540.png`: 1,441 pixels (0.23%)
- `lobby_feature_notice.png`: 1,430 pixels (0.16%)

Those three lobby goldens were updated with
`flutter test --update-goldens test/app/joseon_lobby_mobile_golden_test.dart`
and then re-run successfully.
