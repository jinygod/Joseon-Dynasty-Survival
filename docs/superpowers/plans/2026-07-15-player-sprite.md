# Player Sprite Plan

**Goal:** Complete `VIS-003` with an original rookie constable walk, hit, and death pixel-art sprite set, provenance evidence, runtime animation states, and fallback-safe tests.

## Steps

- [x] Define animation frame contract and write failing state/asset tests.
- [x] Generate an original chroma-key character sheet with the built-in image tool.
- [x] Remove the key, normalize to the approved palette/size, and inspect every frame.
- [x] Integrate walk, hit, and death animations without breaking headless tests.
- [x] Record prompt, source hash, human edits, review, and ledger approval.
- [x] Run the full release gate, update the master TODO, merge, and clean the worktree.

## Verification

- Visual review: 16 original frames, transparent background, no text, logo, watermark, or cell overlap.
- `dart analyze`: no issues.
- `flutter test -r compact`: 182 tests passed.
- `flutter build web`: passed.
- `flutter build apk --debug`: passed.
