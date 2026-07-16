# QA Release Candidate Verification

## Scope delivered

- `QA-003`: a production `WaveDirector` and shared runtime `GamePerformanceBudget.admitCount` harness streams 18,000 fixed 1/60-step observations across a five-minute worst-pressure window. It reports population peaks, measured harness update cost, and a mounted-component memory proxy; physical-memory limits use the documented profile-device procedure.
- `QA-006`: six deterministic 1280x720, DPR 1 surface goldens cover lobby, character selection, stage selection, game HUD, pause menu, and run summary.
- `QA-010`: the tested policy defines P0-P3, mandatory P0/P1/evidence blocks, controlled P2 exceptions, and objective unblock/reopen rules.
- `QA-012`: a pure Dart CLI validates supplied Git, version, gate, performance, golden, and blocker evidence and generates READY or BLOCKED Markdown with meaningful exit codes.

## TDD evidence

- Performance collector RED: imports and collector/reporter types were absent. GREEN: peak, violation, JSON, and Markdown tests passed.
- Five-minute artifact RED: artifact bundling and the deterministic production-admission harness were absent. The initial mounted-asset experiment also proved unsuitable because 18,000 asynchronous sprite lifecycle waits exceeded the regression-test timeout; the final harness keeps production wave/admission behavior while avoiding renderer/asset timing. GREEN: 18,000/18,000 samples with peaks 92 enemies, 128 projectiles, 24 damage numbers, 32 effects, proxy 283, and zero budget-violation samples.
- Golden RED: all six PNG baselines were absent. GREEN: generated baselines compared 6/6 in a normal non-update run.
- Policy RED: the policy document was absent. GREEN: the document-contract test passed.
- Report RED: the tool and public types were absent. GREEN: READY, BLOCKED, and malformed/missing-input cases passed 3/3.

## Fresh release gate

Source evidence commit: `db22082` on `codex/qa-release-candidate`, application version `0.1.0+1`.

| Command | Result |
| --- | --- |
| `A:\bin\dart.bat format --output=none --set-exit-if-changed lib test tool` | PASS; 205 files checked. Seven CRLF-normalized paths were reported as changed, with no Git content diff. |
| `A:\bin\dart.bat analyze` | PASS, no issues. |
| `A:\bin\flutter.bat test -r compact` | PASS, 444/444. |
| `A:\bin\flutter.bat build web` | PASS, `R:\build\web`; Wasm dry run succeeded. |
| RC generator with the evidence above | READY, exit 0. |

The initial direct Korean-path baseline crashed before test loading in `impellerc` while compiling `ink_sparkle.frag`. The requested worktree was mapped to ASCII drive `R:` and the Flutter SDK to `A:`; the unchanged baseline then passed 431/431 before implementation.

## Scope audit

- `docs/master-development-todo.md` is unchanged.
- Android configuration and accessibility behavior are unchanged.
- No production app screen required golden-only injection.
- Runtime production changes are limited to sharing enemy admission math through the tested performance-budget contract.
