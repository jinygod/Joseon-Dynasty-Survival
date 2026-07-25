# Release Lobby Verification Report

**Verified source:** `a52ffe8f8045be8a40a13e17eae415e1139725df` on
`codex/release-lobby`.

## Final gates

| Check | Result | Evidence |
| --- | --- | --- |
| Static analysis | PASS | `flutter analyze` exited 0 in 20.682 s with no issues. |
| Full test suite | PASS | `flutter test --reporter expanded` exited 0 in 70.671 s; 1,189 tests passed. Log: `.superpowers/sdd/2026-07-25-landscape-release-lobby/final-full-test-after-key-fix.log`. |
| Web release build | PASS | `flutter build web --release` exited 0 in 62.779 s and produced `build/web`. |
| Android debug APK | PASS | The production APK was built at `b5e1df7`; the only later source change is a test-key correction, so the previously verified APK remains applicable to the final production source. |

## Runtime visual review

The approved runtime captures were inspected at their native landscape viewports:

| Viewport | Capture | Review result |
| --- | --- | --- |
| 1280x720 (16:9) | `art_source/review/lobby/lobby_16_9.png` | PASS |
| 1170x540 (19.5:9) | `art_source/review/lobby/lobby_19_5_9.png` | PASS |
| 1280x720 (16:9, notice overlay) | `art_source/review/lobby/lobby_feature_notice.png` | PASS |

The review confirms readable status and rail labels, balanced landscape rails,
and a prominent deploy action, raster-based framing/icons, and an in-world
ornate unavailable-feature notice.

## Route and notice coverage

Focused integration coverage verifies the release lobby's character, stage,
deploy/combat, results/retry, premium-shop, settings, training, compendium, and
records routes. The release-flow test was corrected to use the integrated
`lobby-primary-character` target and passes. Table-driven coverage and the
runtime notice capture verify unavailable commands present the approved
`LobbyFeature` notice rather than dead-ending.

## Remaining non-lobby UI gaps

The lobby itself is the approved release composition. Outside the lobby, the
existing UI-art audit still identifies asset work for stage and character cards,
HUD/readouts, level-up choices, pause/settings, tutorial, and some combat/reward
notices. These are tracked visual-asset follow-ups; they do not change the
verified lobby release result.

## APK artifact

- Path: `D:\CodexWorktrees\release-lobby\build\app\outputs\flutter-apk\app-debug.apk`
- Size: `223017745` bytes
- SHA-256: `2BA0073966C0D3BD900B556F763274C16C09BF61EA13F8AA86174C487554B79E`

## Source and branch

The verified source commit is `a52ffe8f8045be8a40a13e17eae415e1139725df`.
The branch is `codex/release-lobby`; its HEAD was verified to equal that commit
before this documentation commit.
