# Release-candidate Reporting

Release status is derived from command evidence, not operator-written `PASS` text.
`tool/collect_release_candidate_evidence.ps1` runs the fixed analyze, full test,
web build, actual five-minute `PixelSurvivorGame`, and golden commands. For each
gate it records the command exit code, log path, Git blob hash, file mtime, and
completion time in `build/qa/release-candidate-evidence.json`.

```powershell
./tool/collect_release_candidate_evidence.ps1 `
  -OpenP0 0 -OpenP1 0 -OpenP2 0 -OpenP3 0

dart run tool/release_candidate_report.dart `
  --evidence build/qa/release-candidate-evidence.json `
  --output docs/testing/release-candidate-report.md
```

The report tool independently checks the current branch and full HEAD, confirms
the commit object exists, reads the current `pubspec.yaml` version, recomputes
every log hash and mtime, and rejects evidence older than one hour or dated in
the future. A nonzero command exit, changed/missing artifact, stale timestamp,
or repository mismatch blocks the candidate.

Open P2 defects require one record per defect with `owner`, `approvedBy`,
`expiresAt`, `verifiedWorkaround`, and `userOperationalRisk`. The expiry must
be later than both manifest generation and the report's current UTC evaluation
time. Workaround and risk text is trimmed, must contain at least 12 characters,
and cannot be a placeholder. Open P3 defects require one record per defect with
`owner` and `milestone`. Pass JSON arrays with `-P2ExceptionsJson` and
`-P3RecordsJson`; counts and records must agree. P0 and P1 must be zero.

Example P2 exception input:

```json
[
  {
    "owner": "qa-owner",
    "approvedBy": "release-owner",
    "expiresAt": "2026-07-31T00:00:00Z",
    "verifiedWorkaround": "QA verified that reopening the records tab refreshes totals.",
    "userOperationalRisk": "Users may briefly see stale totals; operations receives no bad data."
  }
]
```

The wrapper preserves these keys in `defects.p2Exceptions` in the evidence
manifest. The report repeats accepted P2 details so reviewers can audit the
workaround, risk, approval, and expiry used for the decision.

The generated report describes the source commit in the manifest. Commit the
report afterward. Any production, dependency, asset, build configuration, test,
or golden change invalidates the evidence and requires collection again.
