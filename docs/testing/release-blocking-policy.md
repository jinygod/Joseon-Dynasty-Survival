# Bug Severity and Release-blocking Policy

## P0 — catastrophic

Production data loss or corruption, exploitable security/privacy failure, store-policy violation, install/launch failure on every supported device, or a crash loop with no recovery. Incident ownership is immediate and the candidate is withdrawn.

Examples: save migration destroys progress; secrets ship in the client; the signed artifact cannot launch.

## P1 — critical player path

A core release promise is unusable for a meaningful supported cohort with no safe workaround: starting or completing a run, saving progression, input, required audio/settings behavior, boss completion, or sustained performance outside the approved population contract. A reproducible crash or hang on a core path is P1 even when reopening the app recovers.

Examples: deploy never enters the game; the result cannot retry or return to menu; a standard population exceeds its coded cap.

## P2 — major degradation

Important behavior is incorrect or substantially degraded, but the core run remains completable and a documented safe workaround exists. A P2 may ship only through the exception process below; otherwise it remains scheduled before release.

Examples: one optional records filter is wrong; a secondary device layout clips nonessential copy while navigation remains available.

## P3 — minor or cosmetic

Small visual, copy, animation, or low-frequency usability defects that do not mislead the player, lose data, break accessibility requirements, or prevent a supported flow. P3 defects remain tracked and prioritized by impact and frequency.

Examples: one-pixel alignment drift; harmless punctuation inconsistency.

## Candidate decision table

- Open P0: BLOCK
- Open P1: BLOCK
- Missing required evidence: BLOCK
- Failed required evidence: BLOCK
- Open P2 without an approved exception: BLOCK
- Open P2 with a named owner, target date, verified workaround, risk statement, and written release owner acceptance: conditionally non-blocking
- Open P3 with an issue owner and target milestone: non-blocking

Required evidence is the candidate commit and branch, application version/build number, clean static analysis, full automated test result, web build result, QA-003 performance result, QA-006 golden result, and the open P0/P1 count. Evidence is stale after any production, dependency, asset, build-configuration, or golden change and must be regenerated.

Severity is based on player impact, affected cohort, recoverability, and data/security risk—not estimated engineering effort. When two levels appear plausible, use the higher level until triage produces evidence for the lower one. The QA owner assigns severity; the release owner resolves disputes and may raise but never waive a P0 or P1 block.

## P2 exception record

Every exception must link the defect and include:

- owner and target date;
- affected versions/devices and occurrence rate;
- exact workaround verified by QA;
- user and operational risk;
- written release owner decision and expiry date.

An exception expires on its target date, when scope or reproduction changes, or when the workaround fails. Expired exceptions return the candidate to BLOCK.

## Blocking and unblock workflow

1. Record a minimal reproduction, expected/actual behavior, environment, first known commit, severity, and owner.
2. Add a failing regression test for code defects when automation is technically possible. For device-only defects, attach a repeatable manual case and capture.
3. Fix the root cause and show the regression test moving RED to GREEN. Never close from code review alone.
4. Re-run the original reproduction on every affected target and record the reviewer who verified it.
5. Run the full release gate on the candidate commit. Any failure keeps the block open.
6. The QA owner marks the block cleared only when reproduction is absent, targeted evidence passes, the full release gate passes, and an independent reviewer signs the record.

A reverted fix, flaky regression test, newly affected cohort, or stale candidate evidence automatically reopens the block. Downgrading severity requires new impact evidence and the release owner decision; schedule pressure is not evidence.

## Aging and reporting

P0 is reported immediately, P1 within the same working session, and P2/P3 by the next triage. The release-candidate report lists counts for every severity and links accepted P2 exceptions. A READY decision is impossible while any mandatory field is absent.
