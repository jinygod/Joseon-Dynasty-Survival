# Task 7 Report: Landscape Lobby Integration

## Delivered

- Composed `LobbyScene`, `LobbyStatusBar`, side-menu rails, deployment stage,
  quick actions, and primary navigation in `LobbyScreen`.
- Preserved the existing character, stage, settings, compendium, training,
  records, premium-shop, and guarded deploy flows.
- Routed unavailable actions through the approved `LobbyFeature` notices.
- Replaced the lobby premium `ActionChip` with a semantic gesture target.
- Removed the obsolete top command bar and navigation dock files.

## TDD evidence

The new integration test first failed against the legacy composition because
the release scene character key was absent. It now covers 640x360, 780x360,
and 800x360 layouts, stock-Material exclusions, implemented destinations,
feature notices, and persisted deploy selection.

## Verification

```powershell
$env:PUB_CACHE='D:\FlutterPubCache'
& 'D:\FlutterSDK\bin\flutter.bat' test test/app/lobby_screen_test.dart test/app/lobby_release_layout_test.dart test/app/lobby_feature_notice_test.dart
```

Result: 14 passing app-focused tests; 15 passing tests when including the
expanded visual-branch contract.

The expanded focused contract test also replaces the deleted navigation-dock
path with the release `LobbyScreen` and `LobbyPrimaryNavigation` composition.

## Review round 1

- Restored permanent-account email visibility and a `sync-now` entry directly
  in the raster lobby composition without reintroducing stock Material lobby
  surfaces. Existing backend flow coverage verifies the production account,
  wallet, shop, and retry paths.
- Added the 640x360 compact-horizontal-rail regression: all six side commands
  remain in bounds and no vertical rail is composed at that width.

## Review round 2

- Restored saved-training delivery, settings reset/stage persistence and
  SnackBar round-trip coverage through the integrated release lobby.
- Added a 390x844 2x-text reachability regression and scales the stage
  composition down from its wide layout when constrained, avoiding plaque
  overflow without changing stage behavior.
- Added primary-combat routing and table-driven unavailable-feature notice
  coverage.

## Review round 3

- Added an integrated primary-shop regression using `lobby-primary-shop` and
  asserting navigation to `PremiumShopScreen`; it does not substitute the
  status-bar premium entry.
