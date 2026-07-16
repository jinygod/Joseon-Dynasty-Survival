# Content Integrity Verification

## Scope

- CNT-015 aggregate content validation for 3 characters, 8 weapons and 40 levels, 16 augments, 8 normal enemies, 3 elites, 2 stages, 3 bosses, and 15 unlock goals.
- Unique IDs, starting-weapon and level-table references, unlock coverage, stage wave and boss reachability, existing specialist validators, image assets, and audio cue/channel contracts.
- CNT-016 automated viability for frontline-control, ranged-focus, and area-attrition builds through the production progression, level-up choice, and weapon upgrade rules.
- No changes to app, settings, QA, or `docs/master-development-todo.md` files.

## TDD Evidence

The first focused run failed with exit code 1 because `content_integrity.dart`, `ContentIntegrityReport`, `ContentRosterCounts`, and `validateContentIntegrity` did not exist. After the minimum validator and asset coverage were implemented, the aggregate suite passed 14/14.

The build viability test was then added before the build catalog. Its RED run failed with exit code 1 because `MinimumViableBuild`, `CombatBuildRole`, and `minimumViableBuilds` did not exist. Adding the three content blueprints made the combined focused suite pass 16/16.

## Rule-Driven Build Evidence

Each test starts at `SaveState.defaults()`, supplies deterministic achieved metrics, and calls `ProgressionSystem.evaluate`. It verifies that each blueprint's character, stage, weapons, and augments are actually unlocked. A fixed-seed `LevelUpSystem` repeatedly produces the normal three choices; the builder applies a target level only when that exact choice is offered. Weapon choices additionally pass through `WeaponSystem.upgrade`, proving unlock and level-cap enforcement.

Role signatures are computed from the selected level-five definitions rather than blueprint names:

- frontline control has greater combined knockback than ranged focus;
- ranged focus has the greatest reach;
- area attrition has both persistent duration and chain coverage;
- all three signatures differ across reach, control, projectile count, chain count, duration, and elements.

## Environment

Windows Flutter shader compilation initially crashed from the Korean checkout path. The SDK and worktree were mapped to `A:` and `B:`, with `TEMP`, `TMP`, and `PUB_CACHE` set to ASCII-only directories. `flutter clean` removed the stale bundle before the final verification. The trailing `The network path was not found` messages are emitted while temporary mapped paths are released; all recorded commands returned exit code 0.

## Final Verification

Run from `B:\` with Flutter SDK `A:\bin`:

| Command | Result |
| --- | --- |
| `dart format` on all owned Dart files | exit 0, 0 files changed |
| `dart analyze` | exit 0, `No issues found!` |
| `flutter test -r compact test/game/content_definitions_test.dart test/game/content_integrity_test.dart test/game/content_build_viability_test.dart` | exit 0, 16/16 passed |
| `flutter test -r compact` | exit 0, 401/401 passed |
| `flutter build web` | exit 0, `Built B:\build\web`; Wasm dry run succeeded |
| `git diff --check` | exit 0 |

The image catalog now maps every roster ID to an existing bundled sprite or replaceable atlas. Bespoke art remains a presentation follow-up, but no validated content key points to a missing file.

## Review Notes

The validator performs no file I/O and is not called by game boot. Filesystem existence is supplied by tests as a normalized set, keeping the production report deterministic and reusable in development diagnostics. A dedicated reviewer-agent request could not start because the active agent thread limit was reached; the branch is intentionally left isolated and includes this exact verification record for parent or peer cross-review.
