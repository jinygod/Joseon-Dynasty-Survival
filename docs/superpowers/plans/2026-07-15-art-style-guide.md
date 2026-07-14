# Art Style Guide Plan

**Goal:** Complete `VIS-001` with a production-readable Joseon folk-horror pixel-art guide and testable palette/scale/silhouette tokens.

## Steps

- [x] Write RED tests for native sprite sizes, palette integrity, asset suffixes, and silhouette rules.
- [x] Add shared art-style tokens and asset-catalog validation helpers.
- [x] Write the full palette, resolution, outline, lighting, silhouette, animation, and review guide.
- [x] Run focused tests and the full release gate.
- [x] Mark `VIS-001`, update baseline/queue, merge, and clean the worktree.

## Verification

- `dart analyze`: no issues.
- `flutter test -r compact`: 176 tests passed.
- `flutter build web`: passed.
- `flutter build apk --debug`: passed.
