# Weapon Effects Plan

**Goal:** Complete `VIS-006` with an original 64px four-weapon effect atlas, runtime animation metadata, and visual integration that leaves combat hit logic deterministic.

## Steps

- [x] Define 4×4 atlas regions and write failing asset/metadata tests.
- [x] Generate and normalize original hwando, bow, talisman, and bomb effects.
- [x] Add non-blocking shared effect loading with safe shape fallback.
- [x] Apply frames to melee, projectile, delayed explosion, and area attack rendering.
- [x] Record prompt, hashes, processing, review, and approved ledger row.
- [x] Run the full release gate, update the master TODO, merge, and clean the worktree.

## Verification

- Visual review: 16 original 64px effect frames, distinct weapon silhouettes and progressions, no text, logo, watermark, or cell overlap.
- `dart analyze`: no issues.
- `flutter test -r compact`: 190 tests passed.
- `flutter build web`: passed.
- `flutter build apk --debug`: passed.
