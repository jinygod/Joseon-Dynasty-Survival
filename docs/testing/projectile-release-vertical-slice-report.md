# Release Projectile Vertical Slice Report

Date: 2026-07-25  
Branch: `codex/release-projectile-combat`  
Seed: `3107`

## Outcome

The four moving player weapons now use weapon-specific PNG animation sheets
and one shared authored contact sheet. Release execution has no geometric
projectile fallback. Rendering, visible body, 10%-inset hit body, swept
collision, and contact feedback share one immutable presentation contract.

## Before

- Singijeon used a PNG with an opaque rectangular cell border, producing the
  reported brick/card silhouette.
- Matchlock and hawk projectiles had no dedicated release PNG and could render
  through the generic oval presentation path.
- Moving projectile contact used only the current position and a broad
  center-distance circle:
  `(projectile size + enemy size) / 2`.
- Fast shots could tunnel through an enemy between updates.
- Contact feedback was mounted at the enemy center rather than the calculated
  intersection.

## After

| Weapon | Render size | Authored visible body | Hit body (10% inset) |
| --- | ---: | ---: | ---: |
| Gakgung | 28x28 | 24x6 | 21.6x5.4 |
| Singijeon | 30x24 | 25x9 | 22.5x8.1 |
| Matchlock | 22x18 | 15x10 | 13.5x9 |
| Hawk | 34x24 | 28x16 | 25.2x14.4 |

- Previous and current world positions form an allocation-light swept capsule.
- Enemy contact uses `EnemyComponent.hurtRadius`.
- Piercing contacts are sorted by travel fraction and applied nearest first.
- A target can be registered only once per projectile.
- Pause synchronization resets the previous position, preventing an old sweep
  from being replayed.
- A six-frame, image-only impact plays for 0.14 seconds at the calculated
  contact point.
- Missing projectile or impact art fails during combat preloading; firing never
  starts an image load.
- Debug builds can display visible body, hit body, sweep, hurtbox, contact
  normal, and weapon ID. These overlays are absent from release rendering.

## Assets

- `assets/images/projectiles/player/singijeon_128.png`
- `assets/images/projectiles/player/matchlock_shot_128.png`
- `assets/images/projectiles/player/hawk_flight_128.png`
- `assets/images/vfx/player/projectile_contact_128.png`
- Source and transparent intermediates:
  `art_source/generated/projectiles/`
- Prompt record:
  `docs/assets/prompts/release-projectiles.md`
- Provenance and accepted SHA-256 values:
  `docs/assets/asset-rights-ledger.csv`

Each projectile sheet is 512x128 with four 128px cells. The contact sheet is
768x128 with six 128px cells. Contract tests verify transparent corners,
non-empty silhouettes, accepted atlas status, and removal of the former
Singijeon frame edge.

## Fixed-seed five-minute performance

The deterministic development harness runs 18,000 frames over 300 seconds.
The stricter visual-aligned hit bodies leave slightly more enemies alive than
the former broad circular contact, but all population and memory budgets pass.

| Metric | Before | After |
| --- | ---: | ---: |
| Average active enemies | 28.36 | 29.41 |
| Maximum active enemies | 84 | 92 |
| Late average active enemies | 53.93 | 55.67 |
| Late maximum active enemies | 84 | 92 |
| Peak mounted components | 365 | 382 |
| Peak memory proxy components | 391 | 405 |
| Peak enemy/projectile/damage/VFX | 84/23/22/25 | 92/22/24/22 |
| Population budget violations | 0 | 0 |
| Memory proxy violations | 0 | 0 |
| Fixed-dt logical FPS | 60.00 | 60.00 |

Current peak host update lifecycle wall time was 12.113ms. Browser review at
960x540 and 1170x540 showed no visible firing hitch and no console errors or
warnings. A device profiler is still required for thermal and GPU frame-time
p95 evidence.

## Visual review

- Landscape golden:
  `test/app/goldens/projectile_release_landscape_16_9.png`
- Browser runtime evidence:
  `art_source/review/projectiles/projectile_gallery_dark.png`
  `art_source/review/projectiles/projectile_gallery_light.png`
  `art_source/review/projectiles/projectile_debug_contact.png`
  `art_source/review/projectiles/projectile_combat_16_9.png`
  `art_source/review/projectiles/projectile_combat_19_5_9.png`

The web debug run used `MOBILE_PREVIEW=false`; otherwise the debug-only
390x844 device frame intentionally masks the real landscape viewport.
Matchlock was selected and visual bounds, hitbox, hurtbox, and contact were
enabled together. The 960x540 and 1170x540 captures showed no opaque cell
border or geometric release fallback.

## Verification

- `flutter analyze`: PASS, no issues.
- `flutter test`: PASS, 1,179 tests.
- Android debug APK: PASS.
- APK:
  `build/app/outputs/flutter-apk/app-debug.apk`
- APK size: 180,670,434 bytes.
- APK SHA-256:
  `4402659ABBCA009B504E375567D16FC273270401C6D34E7D0FFA5A0BBCF7C42C`
- iOS build: not run, per request.

## Physical device checks remaining

- Confirm each projectile silhouette at normal play zoom on a 6-7 inch phone.
- Confirm the 0.14-second impact remains readable under dense enemy overlap.
- Profile GPU/raster frame-time p95 during mastery-level projectile density.
- Confirm speaker/headphone balance when several contacts occur in one frame.
- Recheck touch controls and safe areas in native landscape orientation.
