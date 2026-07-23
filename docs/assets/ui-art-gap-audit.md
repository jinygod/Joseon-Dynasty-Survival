# UI and Remaining Geometry Art Gap Audit

## Executive finding

The current normal Hwando route is image-backed. `HwandoVfxComponent` renders
the registered trail and impact sprite frames, and the generic geometric
`AttackEffectComponent` asserts that registered Hwando effects must not use
it. The stale `hwando_slash_effect_64.png` catalog entry points to a file that
does not exist; current Hwando art lives under `assets/images/vfx/hwando_*`.

The largest remaining art gap is the Flutter UI, not Hwando. The declared
`assets/images/ui/` directory contains only `.gitkeep`, while most lobby,
selection, HUD, pause, tutorial, and level-up surfaces are Material icons,
flat cards, borders, and buttons.

## Prioritized surfaces

| Surface | Classification | Evidence | Current rendering | Priority | Implementable Joseon folk-fantasy asset/layer |
| --- | --- | --- | --- | --- | --- |
| Lobby hub/background | temporary-image | `lib/app/lobby_screen.dart:_GovernmentOfficeScene` | Repeats the combat-effects atlas at low opacity over a flat fallback | P0 | 16:9 magistrate-office interior; paper-window/wall base, wood-beam mid layer, moonlight and desk/lantern foreground |
| Lobby navigation/deploy buttons | primary-geometry | `lib/app/lobby_screen.dart:_LobbyMenuButton`, `_GovernmentOfficeScene` | `FilledButton` and Material map/person/book/trophy/building/fire glyphs | P0 | Three-state wood/hanji nine-slice plus 24–32 px district, constable, record-book, seal, office, and brazier icon sheet |
| UI asset pipeline | image-unconnected | `assets/images/ui/.gitkeep`, `pubspec.yaml` | Directory is declared but empty; app has one `Image.asset` use | P0 | Add `ui_frame_atlas.png`, `ui_icons_24.png`, lobby background layers, and screen portraits under the existing manifest directory |
| Stage cards | primary-geometry | `lib/app/stage_select_screen.dart:_StageCard`, `_InfoRow` | Flat card and moon/virus/lock/warning Material icons | P0 | Two 16:9 thumbnails, locked cinnabar seal, difficulty omen strip, reusable paper card frame |
| Character cards | primary-geometry | `lib/app/character_select_screen.dart:_CharacterCard`, `_iconForCharacter` | Material silhouettes and flat selected/locked overlays | P0 | Three 256 px portrait busts, normal/selected frame, vermilion selection stamp, locked talisman overlay |
| HUD readouts and weapon list | primary-geometry | `lib/app/game_hud.dart:_StatusBar`, `_WeaponList`, `_HudValue` | Translucent rectangles and text | P0 | Slim hanji/ink frame strips and 16–24 px HP, EXP, kill, level, and weapon pictograms; retain text values |
| Level-up choices | primary-geometry | `lib/app/level_up_overlay.dart:_LevelUpChoiceButton` | Scrim and flat filled buttons with no choice art | P0 | Ritual divination panel, 64 px weapon/augment sigils, normal/hover/selected paper cards, rarity seal |
| Lobby resource/header controls | primary-geometry | `lib/app/lobby_screen.dart:_ResourceBadge`, `_LobbyHeader` | Rounded boxes and paid/diamond/settings icons | P1 | Brass/cinnabar badge frame and yeopje, jade, settings-seal icons |
| Combat/reward notices | primary-geometry | `lib/app/game_hud.dart:_CombatNotice`, `_RewardCollectionNotice` | Flat bordered text boxes | P1 | Folded talisman-strip panel with cinnabar glyph and two-frame pulse |
| Pause/settings | primary-geometry | `lib/app/pause_menu_overlay.dart:_PauseMenuOverlayState` | Dark scrim, Card, Material buttons/sliders/switch | P1 | Hanji dialog, carved wood frame/buttons; keep accessible Slider/Switch geometry and skin track/thumb |
| First-run tutorial | primary-geometry | `lib/app/first_run_tutorial_overlay.dart` | Card and five Material icons | P1 | Ink pictograms for joystick drum, weapon arc, jade, ascension scroll, and monster omen |
| Spirit jade pickup | temporary-image | `lib/game/components/spirit_jade_component.dart:render` | Reuses experience art and draws a diamond outline every frame | P1 | Dedicated 4-frame violet jade sheet with internal glow; retain only a subtle accessibility outline |
| Boss post-impact area | primary-geometry | `lib/game/components/area_attack_component.dart:render` | Warning is atlas-backed, but triggered boss circle/sector is a gold Canvas fill | P1 | Radial and cone impact sheets sized to a 128 px base with scalable center/rim layers |
| Boss health bar | auxiliary-geometry-allowed | `lib/app/game_hud.dart:BossHealthBar` | `LinearProgressIndicator` | P2 | Keep dynamic fill; add ceremonial banner frame, crest, and brush-stroke texture |
| Virtual joystick | auxiliary-geometry-allowed | `lib/app/virtual_joystick.dart:render` | Two translucent circles | P2 | Keep geometry/hit target; overlay compass/taegeuk ring and jade thumb cap |
| Enemy warnings/status | complete | `lib/game/components/enemy_combat_overlay_component.dart`, registry enemy VFX | Registry sprites in normal play; geometry only if art is absent | P2 | No urgent replacement; fallback lines/circles preserve danger readability |
| Hwando slashes | complete | `lib/game/components/hwando_vfx_component.dart`, `attack_visual_registry.dart` | Authored trail/impact frames; no Canvas slash renderer | P3 | Palette/shape review only |
| Non-Hwando melee/projectiles/zones | complete with fallback | `MeleeArcComponent`, projectile, hazard, frost, ward, talisman components | Atlas/registry sprites in normal play; simple geometry when loading fails | P3 | Keep low-cost fallbacks unless a supported fail-closed asset policy replaces them |
| Generic attack fallback | fallback-only geometry | `pixel_survivor_game.dart:_spawnAttackEffect`, `AttackEffectComponent.render` | Sector/circle/line only for an unknown registry ID | P3 | Retain for missing-content diagnosis; it is not the current Hwando path |
| VFX gallery guide | auxiliary-geometry-allowed | `lib/game/vfx_gallery_game.dart:_GalleryGuideComponent` | Bounds circle, rectangle, and crosshair | P3 | Debug guide by design; do not replace |

## Empty declared art directories

- `assets/images/ui/` — urgent UI inventory gap.
- `assets/images/weapons/` — no standalone weapon icon inventory.
- `assets/images/characters/` — no selection portrait inventory.
- `assets/images/stages/` — stage thumbnails are absent even though runtime
  tile/prop atlases exist elsewhere.

## Safe cleanup and deferral

- Safe candidate: remove the stale `AssetCatalog` entry for the missing
  `assets/images/effects/hwando_slash_effect_64.png`; there is no file to
  delete.
- Keep both 64 px effect atlases. They remain connected to combat, pickup,
  warning, and temporary lobby paths.
- Defer deletion of generic Canvas fallbacks. Most are not primary production
  art, but they provide missing-asset safety and accessibility-readable danger
  shapes.
- Defer the duplicated `fallen_general_64.png` mapping for plague magistrate
  and masked executioner until unique boss sheets exist.
