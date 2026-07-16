# Release-candidate Reporting

`tool/release_candidate_report.dart` turns already-completed gate evidence into one auditable READY or BLOCKED Markdown report. It does not run commands or infer success from files; callers must supply the exact candidate branch, source commit, version, and fresh results.

## Required invocation

```powershell
dart run tool/release_candidate_report.dart `
  --branch codex/qa-release-candidate `
  --commit 0123456789abcdef0123456789abcdef01234567 `
  --version 0.1.0+1 `
  --generated-at 2026-07-16T12:00:00Z `
  --analyze "PASS: dart analyze (no issues)" `
  --tests "PASS: flutter test (447/447)" `
  --web-build "PASS: flutter build web (build/web)" `
  --performance "PASS: 18000 frames; peaks 92/128/24/32" `
  --goldens "PASS: 6/6 at 1280x720 DPR 1" `
  --open-p0 0 --open-p1 0 --open-p2 0 --open-p3 0 `
  --output docs/testing/release-candidate-report.md
```

Every gate value must begin with `PASS:` or `FAIL:` and contain a concise result. Commit accepts 7–40 hexadecimal characters; version requires `major.minor.patch+build`; defect counts must be non-negative. Invalid or missing input exits 64 without a report. Valid blocking evidence writes a BLOCKED report and exits 2. READY exits 0.

The generated report is evidence for the supplied source commit. If it is committed afterward, the report commit differs by design; any later production, dependency, asset, build-configuration, or golden change requires all gates and the report to be regenerated.
