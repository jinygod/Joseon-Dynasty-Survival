# QA Hardening Verification

## Scope

- `QA-002`: one runtime contract caps enemies at 96, projectiles at 128, damage numbers at 24, and combat effects at 32.
- `QA-002`: `PixelSurvivorGame` applies the contract at wave/minion, projectile, damage-number, and combat-effect admission points. Rejections are counted in immutable snapshots and sent to an exception-isolated diagnostic callback.
- `QA-005`: a widget integration regression traverses Lobby → character selection → stage selection → real Flame game → level-up choice → settlement result → retry.
- `QA-007`: a deterministic accelerated test traverses the real `GameScreen`/Flame/settlement/result/retry lifecycle 20 times and checks active-game replacement, population budgets, settings-listener teardown, audio handles/disposal, widget exceptions, and HUD periodic-timer cleanup.

## TDD evidence

- Budget RED: focused compilation failed because `game_performance_budget.dart`, `GamePerformanceBudget`, the snapshot/diagnostic types, and the `PixelSurvivorGame` injection points did not exist.
- Budget GREEN: the focused budget and combat-feedback suite passed 7/7 after implementing the contract and local guards.
- Integration stabilization: the test exposed asynchronous settlement/route-transition timing. It now waits for the result event with a bounded pump loop and verifies a distinct retry game after the real route replacement.
- Lifecycle stabilization: the first draft incorrectly treated a retained test reference's Flame root `isMounted` flag as an application leak. The final test observes the actual widget owner boundary, one active `GameWidget` after each replacement, fresh per-run budget state, final listener/audio cleanup, and absence of pending timer failures.

## Fresh release gate

All successful Flutter commands used the requested worktree mapped to ASCII drive `Q:` and the Flutter SDK mapped to `Z:`.

| Command | Result |
| --- | --- |
| Focused QA + existing game loop tests | PASS, 38/38 |
| `Z:\bin\dart.bat analyze` | PASS, no issues |
| `Z:\bin\flutter.bat test -r compact` | PASS, 401/401 |
| `Z:\bin\flutter.bat build web` | PASS, `Q:\build\web`; Wasm dry run succeeded |
| Targeted `dart format --output=none --set-exit-if-changed` | PASS, no changes |

The initial direct Korean-path baseline failed before loading tests because Flutter's shader compiler crashed while processing `ink_sparkle.frag` (exit 3). `flutter clean`, `flutter pub get`, and all verification through the ASCII mappings removed that environmental path failure; the unchanged baseline then passed 395/395 before implementation.

## Scope audit

- No collection/content-definition/settings-screen files changed.
- `docs/master-development-todo.md` is unchanged.
- Production changes are limited to the new budget contract, `PixelSurvivorGame` admission/diagnostic points, and removal of duplicated feedback-cap constants.
