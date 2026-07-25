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
