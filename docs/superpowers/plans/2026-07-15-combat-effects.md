# Combat Effects Plan

**Goal:** Complete `VIS-007` with original experience, hit, critical, death, and danger-warning effects while preserving feedback caps and deterministic combat.

## Steps

- [x] Define a 4×5 combat-effect atlas and write failing metadata/asset tests.
- [x] Generate and normalize five four-frame effect sequences.
- [x] Add capped, non-blocking combat effect components with shape fallback.
- [x] Integrate experience, hit, critical, enemy death, and boss warning events.
- [x] Ensure enemy death animations remain visible before cleanup and rewards.
- [x] Record provenance, run the full gate, update the master TODO, merge, and clean.

## Verification

- Visual review: 20 original 64px frames with distinct experience, hit, critical, death, and warning progressions; no text, logo, watermark, anatomy, gore, or cell overlap.
- `dart analyze`: no issues.
- `flutter test -r compact`: 194 tests passed.
- `flutter build web`: passed.
- `flutter build apk --debug`: passed.
