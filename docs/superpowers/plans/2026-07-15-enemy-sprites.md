# Enemy Sprite Plan

**Goal:** Complete `VIS-004` with original move, attack, hit, and death sprite sheets for the four implemented normal enemies, runtime states, and provenance evidence.

## Steps

- [x] Define the shared 16-frame enemy animation contract and state tests.
- [x] Generate four original chroma-key sheets with distinct silhouettes.
- [x] Remove keys, normalize every frame to approved 24/32px cells, and inspect.
- [x] Integrate movement, attack/dash, hit, and death states with non-blocking loading.
- [x] Record prompts, hashes, human processing, and four approved ledger rows.
- [x] Run the full release gate, update the master TODO, merge, and clean the worktree.

## Verification

- Visual review: 64 original frames, transparent backgrounds, distinct swarm/chaser/tank/spirit silhouettes, no text, logo, watermark, or cell overlap.
- `dart analyze`: no issues.
- `flutter test -r compact`: 185 tests passed.
- `flutter build web`: passed.
- `flutter build apk --debug`: passed.
