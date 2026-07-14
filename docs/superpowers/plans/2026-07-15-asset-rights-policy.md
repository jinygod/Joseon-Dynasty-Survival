# Asset Rights Policy Plan

**Goal:** Complete `VIS-002` by choosing a release-safe acquisition policy for visual assets and defining evidence required before an asset enters the game.

## Steps

- [x] Define allowed and prohibited acquisition routes.
- [x] Define AI-generation, commissioned, purchased, and self-made evidence requirements.
- [x] Add a versioned asset-rights ledger template and intake checklist.
- [x] Update the art guide and master TODO with the decision.
- [x] Run documentation checks and the full release gate, merge, and clean the worktree.

## Verification

- `dart analyze`: no issues.
- `flutter test -r compact`: 179 tests passed, including 3 policy schema tests.
- `flutter build web`: passed.
- `flutter build apk --debug`: passed.
