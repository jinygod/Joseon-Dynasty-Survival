# Release Candidate Report — READY

- Generated: 2026-07-16T15:35:11.878612Z
- Branch: `codex/qa-release-candidate`
- Commit: `390b764ce80c8596beaa18f51ee3db06fd322f26`
- Version: `0.1.0+1`

## Required evidence

| Gate | Status | Command | Artifact |
| --- | --- | --- | --- |
| analyze | PASS | A:\bin\dart.bat analyze | build/qa/release-gates/analyze.log |
| tests | PASS | A:\bin\flutter.bat test -r compact | build/qa/release-gates/tests.log |
| webBuild | PASS | A:\bin\flutter.bat build web | build/qa/release-gates/web-build.log |
| fiveMinuteProfile | PASS | A:\bin\flutter.bat test test/game/five_minute_performance_development_log_test.dart -r compact | build/qa/release-gates/five-minute-profile.log |
| goldens | PASS | A:\bin\flutter.bat test test/app/release_surface_golden_test.dart -r compact | build/qa/release-gates/goldens.log |

## Open defects

| Severity | Count | Required record |
| --- | ---: | --- |
| P0 | 0 | Must be zero |
| P1 | 0 | Must be zero |
| P2 | 0 | Owner, approval, future expiry |
| P3 | 0 | Owner, milestone |

## Blocking reasons

- None.
