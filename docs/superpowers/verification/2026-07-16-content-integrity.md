# Content Integrity Verification

## Scope

- CNT-015 aggregate content validation for 3 characters, 8 weapons and 40 levels, 16 augments, 8 normal enemies, 3 elites, 2 stages, 3 bosses, and 15 unlock goals.
- Unique IDs, starting-weapon and level-table references, unlock coverage, stage wave and boss reachability, existing specialist validators, image assets, and audio cue/channel contracts.
- CNT-016 automated viability for frontline-control, ranged-focus, and area-attrition builds through the production progression, level-up choice, and weapon upgrade rules.
- No changes to app, settings, QA, or `docs/master-development-todo.md` files.

## TDD Evidence

The first focused run failed with exit code 1 because `content_integrity.dart`, `ContentIntegrityReport`, `ContentRosterCounts`, and `validateContentIntegrity` did not exist. After the minimum validator and asset coverage were implemented, the aggregate suite passed 14/14.

The build viability test was then added before the build catalog. Its RED run failed with exit code 1 because `MinimumViableBuild`, `CombatBuildRole`, and `minimumViableBuilds` did not exist. Adding the three content blueprints made the combined focused suite pass 16/16.

Review remediation added four independent RED regressions. Injected malformed enemy/wave/boss catalogs were ignored by the aggregate validator, count-preserving ID substitutions passed, malformed reward cardinality asserted before validation, and orphan asset keys passed. The build helper also failed a new starting-weapon assertion with 16 applied choices instead of the legal 15 minimum for the first build. After the fixes, the expanded content-focused suite passed 38/38. A first full-suite run then caught the removed default unlock constructor invariant; restoring the assert and adding an explicit raw-input constructor made the unlock-focused suite and the final full suite green.

## Rule-Driven Build Evidence

Each test starts at `SaveState.defaults()`, supplies deterministic achieved metrics, and calls `ProgressionSystem.evaluate`. It verifies that each blueprint's character, stage, weapons, and augments are actually unlocked. The selected character's production starting weapon is equipped at level one through `WeaponSystem.upgrade`. A fixed-seed `LevelUpSystem` is called exactly once per level-up and must return three choices. The builder applies exactly one of those choices every round: a still-needed target when offered, otherwise the first offered legal fallback. There is no skipped offer, free reroll, or free continuation; the applied-choice count must equal the offered-round count.

Role signatures are computed from the selected level-five definitions rather than blueprint names:

- frontline control has greater combined knockback than ranged focus;
- ranged focus has the greatest reach;
- area attrition has both persistent duration and chain coverage;
- frontline augments provide the greatest survivability signature;
- ranged augments provide attack speed and critical chance;
- area augments provide weapon size and experience gain;
- all three signatures differ across weapon and augment role dimensions.

## Validator Review Evidence

- Enemy, wave, and boss specialist validators accept injected definitions; the aggregate report never falls back to production globals for those catalogs.
- Stage waves must continuously cover both `bossArrivalSeconds` and `targetSeconds`.
- `ContentRosterContract` owns the exact approved IDs and stage-to-boss reachability sets, so equal-count substitutions fail.
- Unlock expectations are derived from the actual `SaveState.defaults()` ID sets. The validator reads all four nullable reward fields directly, reports zero/multiple reward cardinality, and accumulates issues without using throwing getters.
- Asset maps report orphan keys; the unused legacy stage-tile key was removed.

## Environment

Windows Flutter shader compilation initially crashed from the Korean checkout path. The SDK and worktree were mapped to `A:` and `B:`, with `TEMP`, `TMP`, and `PUB_CACHE` set to ASCII-only directories. `flutter clean` removed the stale bundle before the final verification. The trailing `The network path was not found` messages are emitted while temporary mapped paths are released; all recorded commands returned exit code 0.

## Final Verification

Fresh review-fix verification ran from `B:\` with Flutter SDK `A:\bin`:

| Command | Result |
| --- | --- |
| `dart format` on changed Dart files | exit 0, 0 files changed |
| `dart analyze` | exit 0, `No issues found!` |
| `flutter test -r compact test/game/content_integrity_test.dart test/game/content_build_viability_test.dart test/game/unlock_definitions_test.dart` | exit 0, 12/12 passed |
| `flutter test -r compact --concurrency=1` | exit 0, 405/405 passed |
| `flutter build web --release` | exit 0, `Built B:\build\web`; Wasm dry run succeeded |
| `git diff --check` | exit 0 |

The image catalog now maps every roster ID to an existing bundled sprite or replaceable atlas. Bespoke art remains a presentation follow-up, but no validated content key points to a missing file.

## Review Notes

The validator performs no file I/O and is not called by game boot. Filesystem existence is supplied by tests as a normalized set, keeping the production report deterministic and reusable in development diagnostics. A dedicated reviewer-agent request could not start because the active agent thread limit was reached; the branch is intentionally left isolated and includes this exact verification record for parent or peer cross-review.
