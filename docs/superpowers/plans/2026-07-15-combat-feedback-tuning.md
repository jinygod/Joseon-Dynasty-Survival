# Combat Feedback Tuning Plan

**Goal:** Complete `BAL-006` by centralizing and testing player hit immunity, enemy knockback, screen shake, and damage-number limits.

## Steps

- [x] Write RED tests for multi-enemy immunity, expiry, knockback cap, and feedback constants.
- [x] Add shared tuning constants and apply them to combat, enemies, boss damage, shake, and damage numbers.
- [x] Document the tuning baseline and rationale.
- [x] Run focused tests and the full release gate.
- [x] Mark `BAL-006`, update baseline/queue, merge, and clean the worktree.

## Verification

- Focused combat feedback suite: 32 tests passed.
- Full release gate: analyzer clean, 168 tests passed, web build passed, Android debug APK built.
