# Task 9 verification fix report

Baseline: `5377e7911ed396c3890ebf03b12932e084229744`

## Change

- Replaced `AssetBundle.loadString` for both credits CSV ledgers with
  `AssetBundle.load` and explicit UTF-8 decoding of the returned `ByteData`.
  This avoids `loadString`'s large-asset decode-isolate path for the 65,855-byte
  asset ledger.
- Resolved the four requested analyzer findings with only const/braces changes.
- Strengthened ultra-wide lobby coverage by locating the character art's actual
  `SizedBox` (rather than its full-screen alignment parent) and asserting that
  both stage and deploy controls do not overlap it.

## TDD and verification evidence

- RED: before the production change,
  `flutter test test/app/credits_licenses_screen_test.dart` timed out after
  34 seconds while loading the packaged ledgers.
- GREEN: the same isolated credits test completed with 2 passing tests after
  the ByteData UTF-8 implementation.
- Final focused verification:
  `flutter test test/app/credits_licenses_screen_test.dart test/app/joseon_lobby_mobile_golden_test.dart test/app/lobby_screen_test.dart`
  completed with 20 passing tests.
- `flutter analyze lib/app/credits_ledger.dart lib/app/lobby_battle_stage.dart lib/app/lobby_screen.dart test/app/joseon_lobby_mobile_golden_test.dart`
  reported no issues.

No full suite, web build, or APK build was run.
