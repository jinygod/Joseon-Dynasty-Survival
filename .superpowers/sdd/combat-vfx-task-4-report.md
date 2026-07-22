# Combat VFX Task 4 report

## RED

Command:

```text
flutter test test/game/weapon_visual_theme_test.dart test/game/attack_effect_component_test.dart test/game/weapon_system_test.dart
```

Output (exit 1, representative failures):

```text
Error: Undefined name 'WeaponVfxFamily'.
Error: Method not found: 'combatVfxTierForLevel'.
Error: Method not found: 'combatVfxTierForPresentation'.
Error: The getter 'family' isn't defined for the type 'WeaponVisualTheme'.
Error: No named parameter with the name 'tier'.
Error: The getter 'visualTier' isn't defined for AttackEffectComponent,
       MeleeArcComponent, ProjectileComponent, and AreaAttackComponent.
00:00 +0 -3: Some tests failed.
```

The tests failed because the authored family/tier contracts and component routes did not exist. Test setup itself compiled as far as the deliberately missing production APIs.

## GREEN

Required focused command:

```text
flutter test test/game/weapon_visual_theme_test.dart test/game/attack_effect_component_test.dart test/game/weapon_system_test.dart test/game/pixel_survivor_game_loop_test.dart
```

Output (exit 0):

```text
00:02 +99: All tests passed!
```

Scoped static analysis (exit 0):

```text
flutter analyze lib/game/content/weapon_visual_theme.dart lib/game/components/attack_effect_component.dart lib/game/components/melee_arc_component.dart lib/game/components/projectile_component.dart lib/game/components/area_attack_component.dart lib/game/components/talisman_presentation_component.dart lib/game/components/ward_aura_component.dart lib/game/components/five_color_ward_component.dart lib/game/systems/weapon_system.dart lib/game/pixel_survivor_game.dart test/game/weapon_visual_theme_test.dart test/game/attack_effect_component_test.dart test/game/weapon_system_test.dart
Analyzing 13 items...
No issues found!
```

`git diff --check` also exits cleanly.

Additional renderer/performance regression coverage (exit 0):

```text
flutter test test/game/combat_visual_theme_test.dart test/game/hwando_executor_test.dart test/game/five_color_ward_component_test.dart test/game/talisman_presentation_component_test.dart test/game/game_performance_budget_test.dart
00:01 +29: All tests passed!
```

The broader `flutter test` run completed 824 passing tests and 13 failures. Most failures are the existing test-runtime inability to load `shaders/ink_sparkle.frag`; the late-combat golden also reports an expected 7.17% visual diff after this authored VFX replacement. The required scoped suite is fully green.

## Family mapping

| Weapon | `WeaponVfxFamily` | Authored presentation |
| --- | --- | --- |
| Hwando slash | `hwandoBlade` | filled blade ribbons, bright core, bounded tip sparks |
| Gakgung shot | `gakgungArrow` | tapered segmented trail, faceted arrow head and shaft core |
| Talisman throw | `talismanSeal` | paper seal, rune ring, transfer ribbon, burst fragments |
| Thunder crash bomb | `thunderBomb` | charge footprint, runes, radial burst, smoke and shock rings |
| Jangseung ward | `jangseungGuardian` | nested rune wards and fixed guardian marks |
| Singijeon volley | `singijeonRocket` | rocket silhouette, segmented trail and smoke puffs |
| Frost flask | `frostCrystal` | existing Task 3 tiered crystal/sigil route, now in the shared family map |
| Wind-thunder fan | `windThunderGale` | broad layered wind ribbons, core and tip sparks |
| Matchlock cannon | `matchlockShot` | shot silhouette, hot core, smoke trail and blast rings |
| Shaman bells | `shamanBell` | concentric pulse ribbons and rune marks |
| Dokkaebi chain | `dokkaebiChain` | blade sweep, fixed chain links and impact sparks |
| Hawk summon | `hawkFlight` | winged silhouette and layered flight trail |

Levels 1-3 map to `normal`, 4-5 to `strong`, and 6 to `master`. Immutable `AttackPresentation` values map through the same tier contract. Master styling increases only presentation scale, trail count, contrast, and bounded decorations.

## Gameplay and warning preservation

- The component constructors add presentation-only `tier` values that default to normal. Damage, knockback, collision size, range, radius, angle, direction, duration, cooldown, and hit timing are unchanged.
- `WeaponSystem` only threads tier metadata into its existing results; the prior frost tier switch was replaced by an exactly equivalent shared helper.
- `AttackEffectComponent` still freezes the exact immutable attack geometry and tests compare normal/master instances with identical range, width, and angle.
- Boss telegraphs retain `AttackPresentationPriority.warning` (120), still return immediately through their warning-atlas route, and keep a dedicated fallback warning route. Player weapon layers do not alter warning components or priority.

## Performance bounds

- Shared primitives cap trails at 3, bursts at 24, runes at 12, smoke puffs at 10, chevrons at 8, and crystal facets at 8.
- Local authored loops are also fixed: at most 8 chain links, 8 guardian marks, 4 bell rings, 3 shock rings, and 5 O-bang fragments.
- Rendering is deterministic: no random sampling, timers, allocations that grow with enemy count, blur filters, screen flashes, or camera shake were added.
- Atlas sprites remain optional accents; every affected player presentation renders authored Canvas layers whether or not the atlas is loaded.

## Changed files

- `lib/game/components/attack_effect_component.dart`
- `lib/game/components/melee_arc_component.dart`
- `lib/game/components/projectile_component.dart`
- `lib/game/components/area_attack_component.dart`
- `lib/game/components/talisman_presentation_component.dart`
- `lib/game/components/ward_aura_component.dart`
- `lib/game/components/five_color_ward_component.dart`
- `lib/game/content/weapon_visual_theme.dart`
- `lib/game/systems/weapon_system.dart`
- `lib/game/pixel_survivor_game.dart`
- `test/game/attack_effect_component_test.dart`
- `test/game/weapon_system_test.dart`
- `test/game/weapon_visual_theme_test.dart`
- `.superpowers/sdd/combat-vfx-task-4-report.md`

## Self-review

- All twelve definition IDs have distinct, non-neutral family routes and master scales above 1.
- Tier defaults preserve direct callers and tests prove tier metadata does not mutate representative damage or footprint geometry.
- Rendering loops and shared primitive calls are bounded and deterministic.
- Enemy warnings/hazards, XP gems, and HUD rendering were not edited.
- Visual inspection of the generated late-combat golden test image shows enemy warning rings remain visible above the denser player effects.

## Concerns

- The late-combat golden baseline intentionally was not updated because other parallel art tasks will also change the shared scene; it requires one consolidated golden review/update after integration.
- The broad suite's missing `ink_sparkle.frag` failures are outside Task 4. The required Task 4 suite and scoped analyzer are green.

## Review fix

The task review found no Critical or Important issues. It identified one Minor layout defect: normal Jangseung wards used four guardian marks with a fixed pi/4 step, which covered only half the aura.

Regression RED:

```text
flutter test test/game/attack_effect_component_test.dart
Error: The getter 'guardianAngles' isn't defined for WardAuraComponent.
00:00 +0 -1: Some tests failed.
```

GREEN after making the renderer consume a bounded, evenly spaced 4/8-angle list:

```text
flutter test test/game/attack_effect_component_test.dart
00:00 +3: All tests passed!
```
