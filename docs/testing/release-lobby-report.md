# Release Lobby Verification Report

**Verified source:** `ae56a82770231b63e851edcbdfa44e4704801d66` on
`codex/release-lobby`.

## Final gates

| Check | Result | Evidence |
| --- | --- | --- |
| Static analysis | PASS | `flutter analyze` exited 0 with no issues. |
| Full test suite | PASS | `flutter test --reporter compact` exited 0; 1,194 tests passed. |
| Web release build | PASS | `flutter build web --release` exited 0 and produced `build/web`. |
| Android debug APK | PASS | `flutter build apk --debug` exited 0 and produced the artifact recorded below. |

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

The final reviewer findings were closed in one fix wave: the visible stage
plaque now owns its exact hit target, weapon has dedicated notice copy, the
profile uses raster character art instead of a stock Material icon, and the
permanent-account sync target is at least 48x48.

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
- SHA-256: `0785050CB8F65BF9ED8E02F7B1B0ABF6C19224A05E425CC2925E1617A7520D3F`

## Source and branch

The verified source commit is `ae56a82770231b63e851edcbdfa44e4704801d66`.
The branch is `codex/release-lobby`; this report update is documentation-only.
