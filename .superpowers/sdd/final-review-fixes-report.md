# Final Review Fixes Report

Date: 2026-07-23
Starting HEAD: `f9008f690719709839a3d0677074df3314206e3b`

## Findings and fixes

1. **Loaded boss warning art could replace gameplay geometry.** `AreaAttackComponent.render` now constructs the authoritative radial or sector `Path` from the attack radius, direction, and angle in every atlas state. Loaded atlas art is clipped to that path as an accent, while the exact path outline is always drawn. Pixel regressions cover loaded and missing atlas radial and cone warnings and reject pixels outside the gameplay shape.
2. **Fabricated or stale level-up choices could be applied.** `PixelSurvivorGame.applyLevelUpChoice` now requires membership in the current pending offer and validates weapon and augment current/next/max-level state before any mutation. Tests cover stale duplicate/requeued choices, non-offered choices with otherwise plausible levels, and maxed augments; rejected choices do not mutate progression, append records, consume a pending level, or dismiss the current overlay.
3. **Asset ledger lifecycle values were outside policy.** All `temporary` rows were normalized to `review`, including the bandit atlas. The policy test now validates every ledger row against `AssetRightsPolicy.statuses`; bandit remains non-shippable until exact provenance and approval evidence exists. No physical-device approval is claimed.
4. **Frost runes lacked the requested slow deterministic motion contract.** Rune rotation is now derived from elapsed simulation time at `0.15` radians per second. Tests prove time-partition invariance, slow cadence, and the unchanged exact 30-pixel field radius / 60-pixel component size.
5. **The XP header panel stopped short of the SafeArea width.** The status panel now spans the full SafeArea while its content owns the pause-button clearance. Existing HUD keys and metrics remain intact. Widget, accessibility, responsive, and directly affected golden tests were updated and reviewed.

## TDD evidence

The targeted tests were observed failing before their production fixes:

- Loaded cone rendering produced 1,097 pixels outside the authoritative sector.
- A stale augment choice advanced the augment from level 1 to 2; a maxed augment appended a progression record; and a fabricated same-level choice was accepted.
- Rights-policy tests reported the invalid `temporary` lifecycle and non-normalized representative rows.
- The frost contract initially failed to compile because the deterministic rotation getter did not exist.
- The 390x844 HUD test reported the status panel at x=64 instead of x=0, and the affected goldens differed until the intended full-width panel was accepted.

After implementation, the focused regression matrix passed:

```text
flutter test test/game/area_attack_component_render_test.dart test/game/boss_component_patterns_test.dart test/game/attack_effect_component_test.dart test/game/level_up_system_test.dart test/game/progression_system_test.dart test/game/run_progression_system_test.dart test/game/pixel_survivor_game_loop_test.dart test/app/level_up_overlay_test.dart test/app/release_flow_integration_test.dart test/game/asset_rights_policy_test.dart test/game/content_integrity_test.dart test/app/credits_licenses_screen_test.dart test/game/frost_field_component_test.dart test/game/weapon_system_test.dart test/app/game_hud_test.dart test/app/accessibility_surfaces_test.dart test/app/responsive_layout_test.dart test/app/balanced_casual_combat_golden_test.dart test/app/release_surface_golden_test.dart -r compact
202/202 passed
```

## Final verification

The Windows shader toolchain requires an ASCII Flutter SDK and cache paths. After stopping the external processes that held `build/web`, the generated build directory was fully removed and rebuilt with the previously proven environment:

```text
TEMP=D:\CodexTemp\balanced-casual-art-overhaul
TMP=D:\CodexTemp\balanced-casual-art-overhaul
PUB_CACHE=D:\codex-pub-cache
F:\bin\flutter.bat clean
F:\bin\flutter.bat pub get
F:\bin\flutter.bat test --reporter compact
861/861 passed; exit 0

F:\bin\flutter.bat analyze
No issues found; exit 0

git diff --check
exit 0
```

The earlier `ink_sparkle.frag` missing-asset failures were traced to an incomplete shader bundle created after `impellerc` crashed when invoked from the non-ASCII SDK path. They are superseded by the clean, full 861-test pass above using the project-proven ASCII SDK.

## Changed files

- Boss geometry and pixel regressions: `lib/game/components/area_attack_component.dart`, `test/game/area_attack_component_render_test.dart`
- Choice validation and progression regressions: `lib/game/pixel_survivor_game.dart`, `test/game/pixel_survivor_game_loop_test.dart`
- Rights lifecycle and policy coverage: `docs/assets/asset-rights-ledger.csv`, `test/game/asset_rights_policy_test.dart`
- Frost presentation contract: `lib/game/components/frost_field_component.dart`, `test/game/frost_field_component_test.dart`
- Full-width SafeArea XP panel: `lib/app/game_hud.dart`, HUD/accessibility tests, and three directly affected golden files
- Test harness stabilization: `test/app/level_up_overlay_test.dart` uses `NoSplash` so the overlay behavior test does not depend on a Material ink shader

## Self-review and remaining physical QA

- Warning atlas pixels cannot escape the authoritative gameplay path; gameplay damage geometry was not changed.
- Choice rejection checks occur before every mutation, record append, pending-level decrement, and overlay transition.
- Ledger entries without exact approval/provenance remain `review` and non-shippable.
- Frost rotation affects presentation only; radius and component footprint are unchanged.
- The full-width header keeps pause clearance inside its content and preserves the existing semantic/test hooks.

Physical-device validation remains intentionally outstanding:

- [ ] Confirm radial and cone readability during live boss encounters on a 390x844-class Android device.
- [ ] Confirm frost cadence and HUD SafeArea/cutout behavior on physical hardware.
- [ ] Record exact mobile approval and provenance evidence before promoting any `review` atlas to `approved`.
