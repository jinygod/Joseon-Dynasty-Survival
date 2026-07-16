# Release Candidate Report — READY

- Generated: 2026-07-16T16:06:06.703453Z
- Evaluated: 2026-07-16T16:06:15.417841Z
- Branch: `master`
- Commit: `e1015d8b771dc180e94cc8ff6341db11ef2f3252`
- Version: `0.1.0+1`

## Required evidence

| Gate | Status | Command | Artifact |
| --- | --- | --- | --- |
| analyze | PASS | O:\bin\dart.bat analyze | build/qa/release-gates/analyze.log |
| tests | PASS | O:\bin\flutter.bat test -r compact | build/qa/release-gates/tests.log |
| webBuild | PASS | O:\bin\flutter.bat build web | build/qa/release-gates/web-build.log |
| fiveMinuteProfile | PASS | O:\bin\flutter.bat test test/game/five_minute_performance_development_log_test.dart -r compact | build/qa/release-gates/five-minute-profile.log |
| goldens | PASS | O:\bin\flutter.bat test test/app/release_surface_golden_test.dart -r compact | build/qa/release-gates/goldens.log |

## Open defects

| Severity | Count | Required record |
| --- | ---: | --- |
| P0 | 0 | Must be zero |
| P1 | 0 | Must be zero |
| P2 | 0 | Owner, approval, expiry after report time, verified workaround, risk |
| P3 | 0 | Owner, milestone |

## P2 exception records

| Owner | Approved by | Expires | QA-verified workaround | User/operational risk |
| --- | --- | --- | --- | --- |
| None | - | - | - | - |

## Blocking reasons

- None.
