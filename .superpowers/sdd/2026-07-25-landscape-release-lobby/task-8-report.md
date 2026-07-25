# Task 8 Runtime Review Report

## Runtime harness

- Used Flutter golden rendering at 1280x720 (16:9) and 1170x540 (19.5:9).
- The capture root now wraps the `MaterialApp` navigator so the
  `showGeneralDialog` overlay is included. The initial root only wrapped
  `home`, which excluded the feature notice despite the widget test finding it.

## Captures inspected

- `art_source/review/lobby/lobby_16_9.png`
- `art_source/review/lobby/lobby_19_5_9.png`
- `art_source/review/lobby/lobby_feature_notice.png`

## Acceptance review

| Criterion | Result | Evidence |
| --- | --- | --- |
| Character reads before scene art | Pass | The 19.5:9 stage block moves to the right-side scene margin. |
| Deploy is the strongest action | Pass | The bright raster center is preserved; the ivory 20px label is prominent. |
| Side rails are balanced and clear | Pass | Both landscape captures retain symmetric rails outside the center scene. |
| Frame/icon materials align | Pass | Brass, lantern light, and dark-navy framing are consistent. |
| Values readable at native size | Pass | Status values and rail labels remain legible. |
| Notice belongs to the game | Pass | The overlay capture includes its ornate frame, opaque parchment, and framed confirm action. |
| No stock surfaces/icons | Pass | The reviewed lobby uses raster frames/icons, including the confirm action. |

## Targeted refinements

The first focused golden failure established that the deploy command needed to
sit beneath the stage plaque. The approved second pass adds a short-landscape
branch: at 19.5:9 the 276x78 plaque and 168x64 deploy action occupy the right
scene margin, with the stage-picker hit target anchored to the same plaque.

The shared `LobbyAssetButton` now uses a shallow lower shadow rather than a
full dark underlay, preserving transparent raster-frame centers. The deploy
label uses ivory 20px bold text with a dark shadow. The feature notice fills
its parchment interior and reuses the approved deploy raster for confirmation.
`최고 기록` replaced the actual mojibake label. No raster asset was regenerated.

## Verification performed

```powershell
$env:PUB_CACHE='D:\FlutterPubCache'
& 'D:\FlutterSDK\bin\flutter.bat' test test/app/release_surface_golden_test.dart --plain-name 'lobby 16:9 golden' --update-goldens
# PASS: 1 test

& 'D:\FlutterSDK\bin\flutter.bat' test test/app/joseon_lobby_mobile_golden_test.dart --update-goldens
# PASS: 4 tests

& 'D:\FlutterSDK\bin\flutter.bat' test test/app/joseon_lobby_mobile_golden_test.dart --plain-name 'lobby feature notice 16:9 golden' --update-goldens
# PASS: 1 test

& 'D:\FlutterSDK\bin\flutter.bat' test test/app/lobby_release_layout_test.dart test/app/lobby_screen_test.dart test/app/lobby_feature_notice_test.dart test/app/joseon_lobby_mobile_golden_test.dart test/app/release_surface_golden_test.dart
# PASS: 31 tests
```

## Status

Approved visual baseline. All three final captures were inspected directly.
