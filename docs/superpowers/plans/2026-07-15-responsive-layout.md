# Responsive Layout Verification Plan

**Goal:** Complete `UX-009` by proving every release-critical surface is safe at supported landscape ratios and non-zero system insets.

## Matrix

- 16:9 — 800×450
- 18:9 — 900×450
- 19.5:9 — 975×450
- Tablet 4:3 — 1024×768
- Insets on every size — left/right 24, top/bottom 8 logical pixels

## Surfaces

Main menu, character selection, stage selection, first-run tutorial, gameplay HUD, pause menu, and run summary.

## Steps

- [ ] Add parameterized widget tests that fail on any Flutter exception or overflow.
- [ ] Assert key actions remain inside the safe content rectangle.
- [ ] Apply the smallest responsive fixes exposed by the matrix.
- [ ] Run focused matrix and full web/Android release gate.
- [ ] Mark `UX-009`, update baseline/queue, merge, and clean worktree.

