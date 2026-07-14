# Boss Sprite Plan

**Goal:** Complete `VIS-005` with an original 64px fallen-general move, pattern, hit, and death sheet integrated with boss attacks and provenance evidence.

## Steps

- [x] Define the boss 16-frame animation contract and attack-state tests.
- [x] Generate one original chroma-key boss sheet with a unique large silhouette.
- [x] Remove the key, normalize to 64px cells, and inspect every frame.
- [x] Integrate charge, cone, summon, hit, and death state transitions.
- [x] Record prompt, hashes, processing, review, and approved ledger row.
- [x] Run the full release gate, update the master TODO, merge, and clean the worktree.

## Verification

- Visual review: 16 original 64px frames, large asymmetric silhouette, readable pattern poses, no text, logo, watermark, or cell overlap.
- `dart analyze`: no issues.
- `flutter test -r compact`: 187 tests passed.
- `flutter build web`: passed.
- `flutter build apk --debug`: passed.
