# Combat Art, Facing, and Spawn Design

## Scope

This slice replaces the most visible placeholder presentation without changing
combat balance: hwando attacks receive a dedicated raster trail, the stage uses
a reusable illustrated courtyard tile, enemies face their horizontal movement
direction, and regular enemies enter from the full perimeter instead of four
cardinal points.

## Rendering

- The attack hit geometry remains the single source of truth.
- `AttackEffectComponent` derives image rotation and destination size from the
  frozen `AttackVisualGeometry`; image loading cannot change damage timing.
- A transparent original hwando crescent is reused with rotation, scale, alpha,
  and afterimages for levels 1–5. Master circle attacks layer the same visual
  around a full ring so they remain recognizably related but substantially
  larger.
- `StageBackdropComponent` repeats a seamless original Joseon courtyard ground
  tile. Existing deterministic low-cost details remain as a fallback when
  visual assets are disabled or unavailable.

## Movement and spawning

- Enemy atlases are authored facing right. Rendering mirrors the complete
  sprite when `facingDirection.x < 0`; simulation coordinates and directional
  shields are unchanged.
- Regular spawn points use a uniformly sampled angle in `[0, 2π)` and intersect
  the ray with the rectangular off-screen spawn perimeter. This produces all
  angles while keeping every spawn outside the visible field.
- Boss placement remains deliberately authored and is not randomized.

## Constraints and verification

- User references are mood and quality references only; no commercial UI,
  character, or exact effect is copied.
- Effects remain bounded by existing population and feedback budgets.
- Tests cover left/right facing state, non-cardinal spawn geometry, off-screen
  placement, asset registration, analysis, full Flutter tests, web release, and
  Android debug builds.

