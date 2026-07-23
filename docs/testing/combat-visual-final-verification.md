# Combat Visual Overhaul Final Verification

## Scope

- Branch: `codex/combat-visual-overhaul`
- Integrated implementation range: `97c7341..ed93cf0`
- Final reviewer range: `97c7341..8ca23c8`
- Review policy: one read-only integrated review on `gpt-5.6-terra`;
  findings were resolved centrally and the reviewer was not dispatched again.
- Main orchestrator remained `gpt-5.6-sol`. Every subagent invocation named
  `gpt-5.6-terra` explicitly; no subagent inherited Sol.

## Reviewer result and resolution

The reviewer found one P1 integration defect: the debug VFX gallery
`IconButton` was mounted in the app's home `Stack` without a `Material`
ancestor when the Material 2 theme was active. The failure was reproduced in
`backend_game_flow_test.dart` as `No Material widget found`.

Resolution in `ed93cf0`:

- wrapped the debug entry in a transparent `Material`;
- strengthened the gallery navigation test under `useMaterial3: false`;
- verified the app composition and gallery navigation paths independently.

The final focused run also exposed an off-by-one test timing issue in the enemy
warning phase-identity assertion. The test had advanced one tick beyond the
second warning into the active phase. It now stops at the warning re-entry
boundary and passes without changing runtime behavior.

## Command evidence

| Command | Exit | Evidence |
| --- | ---: | --- |
| `dart format --output=none --set-exit-if-changed lib test` | 1 | On this Windows checkout, Dart repeatedly reported six line-ending normalizations that produced no Git diff. A scoped confirmation over all four final changed Dart files exited 0 with `0 changed`. |
| `git diff --check` | 0 | No whitespace errors. |
| `flutter analyze` | 0 | Initial run found one const-lint in a new test; after central correction, the full rerun reported `No issues found`. |
| `flutter test -r compact` | 1 | 848 tests passed and 26 failed after Flutter could not load `shaders/ink_sparkle.frag`; subsequent UI failures were cascade effects. This is not reported as a full-suite pass. |
| Focused combat-visual group with `--no-pub --no-test-assets` | 0 | 241 tests passed across gallery, registry, factories, asset contracts, Hwando, player/enemy/stage VFX, population lifecycle, game loop, five-minute simulation, and performance reporting. |
| Debug app composition regression test | 0 | `production composition initializes account sync and purchases` passed after the transparent `Material` fix. |
| `flutter build web --release` | 1 | Dart compilation and the Wasm dry run succeeded, then Flutter's `impellerc` crashed with SIGSEGV compiling `ink_sparkle.frag` (exit code 3). No verified release artifact is claimed. |

The full-suite and web-build failures occur in the Flutter SDK shader compiler
before a usable application artifact is produced. They match the previously
recorded environment failure and are kept separate from application
regressions.

## Completion evidence

- Normal Hwando attacks use `HwandoVfxComponent` with registered authored
  trail and impact sheets. Tests assert that the normal Hwando path creates no
  legacy `MeleeArcComponent` or geometric `AttackEffectComponent`.
- Player, enemy, stage, and missing-enemy art paths are bound through catalog,
  atlas, preload, rights-ledger, and SHA-256 contract tests.
- Static stage visuals use deterministic sprite batches and do not alter the
  gameplay RNG sequence.
- Combat population and retained-owner lifecycle accounting is indexed and
  covered through removal, bulk removal, disposal, expiry, and five-minute
  simulation tests.
- The seed-3107 host simulation passed its enemy, projectile, damage-number,
  combat-effect, and memory-proxy budgets. Logical FPS is not presented as
  actual render FPS; Chrome frame profiling remains explicitly not measured.
- No source art or material runtime atlas was deleted. Cleanup removed only two
  stale catalog keys whose target files were already absent:
  `healing_item_16.png` and `hwando_slash_effect_64.png`.
- The generated sheets were reviewed during their individual milestones.
  Automated gallery coverage verifies the production factory, all registry
  effects, eight directions, replacement lifecycle, resizing, narrow layout,
  and debug-only routing. A new final live-browser manual capture was not
  claimed because the Flutter shader environment remained blocked.

## Remaining intentional geometry and deferred art

Normal Hwando is no longer a geometric slash. Remaining Canvas rendering is
either documented fallback/diagnostic geometry or a deferred art gap:

- P0: lobby background/navigation, stage and character cards, HUD surfaces,
  and level-up choices;
- P1: spirit jade pickup art and boss post-impact area;
- retained fallbacks: unknown attack IDs, failed non-Hwando asset loads, enemy
  readability warnings, accessibility outlines, virtual joystick, and debug
  gallery guides.

See
[`docs/assets/ui-art-gap-audit.md`](../assets/ui-art-gap-audit.md),
[`docs/assets/combat-visual-cleanup-audit.csv`](../assets/combat-visual-cleanup-audit.csv),
and
[`docs/testing/combat-visual-performance-report.md`](combat-visual-performance-report.md)
for the detailed inventories and measurements.

## Deferred environment work

- Repair or update the local Flutter shader compiler/runtime so
  `ink_sparkle.frag` can be loaded and compiled without SIGSEGV.
- Re-run the full suite and web release build only after that environment is
  repaired; do not reinterpret the current failures as passes.
- Perform a live bright/dark, eight-direction, overlap, edge, and mastery-stage
  gallery capture in the repaired browser environment.
