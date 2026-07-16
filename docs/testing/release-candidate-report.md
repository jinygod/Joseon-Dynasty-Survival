# Release Candidate Report — READY

- Generated: 2026-07-16T14:27:45.016416Z
- Branch: `codex/qa-release-candidate`
- Commit: `db22082`
- Version: `0.1.0+1`

## Required evidence

| Gate | Evidence |
| --- | --- |
| analyze | PASS: dart analyze (no issues) |
| tests | PASS: flutter test (444/444) |
| webBuild | PASS: flutter build web (build/web; Wasm dry run passed) |
| performance | PASS: 18000 frames; peaks enemy 92, projectile 128, damageNumber 24, combatEffect 32; proxy 283 |
| goldens | PASS: 6/6 at 1280x720 DPR 1 |

## Open defects

| Severity | Count |
| --- | ---: |
| P0 | 0 |
| P1 | 0 |
| P2 | 0 |
| P3 | 0 |

## Blocking reasons

- None.
