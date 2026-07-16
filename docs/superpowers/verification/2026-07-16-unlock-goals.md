# Unlock Goals Verification

## Scope verified

- Exactly 15 unique goals, each with one reward.
- Exact reward coverage: two locked characters, six locked weapons, six locked augments, and `plague_market`.
- Run and cumulative evaluation for survival, kills, levels, elites, bosses, low-health wins, victories, and unlocked weapon count.
- Idempotent completed-goal and reward sets, plus `ProgressionUnlocks` diffs.
- UI-ready ordered progress projection with current value, threshold, clamped fraction, completion state, and typed reward.
- Schema v3 migration/round trip and damaged content/counter sanitization.
- Locked character/stage selections normalize to safe starting selections when deserialized.

## Commands and evidence

All Flutter commands ran with the Flutter SDK and repository mapped to dedicated ASCII `SUBST` drives (`M:` and `N:`). No shared mapping was removed.

| Command | Result |
| --- | --- |
| Focused catalog/save/progression/service tests | PASS, 32/32 |
| `flutter test test/app/lobby_controller_test.dart test/game/run_summary_progression_test.dart` | PASS, 16/16 |
| `flutter test -r compact` | PASS, 354/354 |
| `dart analyze` after mapped `flutter pub get` | PASS, no issues |
| `flutter build web` | PASS, `build/web` produced; Wasm dry run succeeded |
| `git diff --check` | PASS |

The first unmapped baseline test crashed in Flutter's shader compiler on the Korean path. A mapped run interrupted by a local 60-second command limit left `build/unit_test_assets` incomplete, producing missing `ink_sparkle.frag` errors. `flutter clean`, mapped `flutter pub get`, and a fresh mapped run removed those environmental failures before the successful 354-test result above.

## Remaining integration risk

The current stage-selection UI predates stage locks and still lists both stages. This slice deliberately does not modify UI; `SaveState.unlockedStageIds` and the service progress API provide the state needed for the stage-selection owner to enforce/display the lock. Direct `PlaytestRoster.resolveUnlocked` also remains a development helper, while lobby character availability now uses the persisted save set.
