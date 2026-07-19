# Actor Render Sizing Design

## Goal

Increase the on-screen readability of the player, normal enemies, elite enemies, and bosses without changing collision geometry, movement, combat balance, spawning, AI, camera zoom, source artwork, or animation timing.

## Current State

| Actor | Visual size | Collision/component size | Source frame | Anchor |
|---|---:|---:|---:|---|
| Player | 36 x 36 | 24 x 24 | 64 x 64 | center |
| Normal enemy | 18 x 18 | 18 x 18 | 24 x 24 or 32 x 32 | center |
| Elite enemy | 40 x 40 | 40 x 40 | sprite or fallback shape | center |
| Boss | 42 x 42 | 42 x 42 | 64 x 64 or fallback shape | center |

`PlayerComponent` already separates its 36-pixel visual from its 24-pixel component. `EnemyComponent` and `BossComponent` currently render directly into their component sizes, and `EnemyComponent.overlapsPlayer` uses those sizes for contact detection. Changing enemy component sizes would therefore alter combat behavior.

## Approved Target Sizes

| Actor | New visual size | Scale from current | Preserved collision/component size |
|---|---:|---:|---:|
| Player | 54 x 54 | 1.5x | 24 x 24 |
| Normal enemy | 27 x 27 | 1.5x | 18 x 18 |
| Elite enemy | 40.5 x 40.5 | 1.0125x; 1.5x normal visual | 40 x 40 |
| Boss | 63 x 63 | 1.5x; 2.33x normal visual | 42 x 42 |

The elite grows only slightly because its current 40-pixel component was already 2.22 times the normal enemy. The approved 40.5-pixel visual corrects the hierarchy to exactly 1.5 times the enlarged normal enemy.

## Architecture

Create one focused sizing policy in `lib/game/content/actor_render_sizes.dart`. It owns the four collision/component sizes and four visual sizes, and maps `EnemyRank` to the appropriate enemy collision and visual values. Components consume this policy instead of repeating numeric literals.

Keep `PlayerComponent`, `EnemyComponent`, and `BossComponent` anchors at `Anchor.center`, because their world positions and camera targeting depend on that coordinate. Render artwork around a bottom-center pivot inside the component so the enlarged image grows upward and sideways while the feet remain aligned with the component bottom edge.

For the player, draw the 54-pixel sprite at `x = (24 - 54) / 2` and `y = 24 - 54`. For enemies, wrap only the body sprite or fallback body in a canvas transform around `(size.x / 2, size.y)`. Do not scale attack telegraphs or warning geometry. Select the transform from `EnemyRank`, giving normal, elite, and boss bodies their approved visual sizes while preserving component sizes.

Set sprite paint filtering to nearest-neighbor/no filtering so integer-aligned source pixels remain crisp. Preserve aspect ratio by applying one uniform scale in both axes. Do not edit or regenerate any PNG.

## Collision and Overlap

Contact calculations, boundary clamping, projectile overlap, separation behavior, and boss targeting continue to read the unchanged component sizes: player 24, normal 18, elite 40, boss 42. The larger art can overlap visually before collision occurs. This is intentional for the first pass and must be reported in QA if dense normal waves become difficult to read.

The maximum new visual overhang per side is 4.5 pixels for normal enemies, 0.25 pixels for elites, 10.5 pixels for bosses, and 15 pixels for the player's 54-pixel canvas. The player PNG contains substantial transparent padding, so its opaque silhouette remains materially closer to the collision footprint than the 54-pixel canvas suggests.

## Testing

Use TDD to add tests before production changes:

- sizing-policy tests assert all approved visual and collision values and the elite/normal and boss/normal ratios;
- player tests assert a 54-pixel visual with a preserved 24-pixel component;
- enemy tests assert 18/40/42 component sizes remain unchanged while visual sizes resolve to 27/40.5/63;
- overlap tests retain their existing contact thresholds, proving collision behavior did not change;
- animation frame and timing tests remain unchanged.

After focused tests pass, run `flutter analyze`, the full Flutter test suite, `flutter build web`, and `flutter build apk --debug`. Because Flutter 3.44.4 crashes on Korean paths in the analyzer LSP and shader compiler, verification may use temporary ASCII junctions for the Flutter SDK and project; remove them afterward.

## Manual QA

Run the web build at a mobile viewport and inspect:

- player, normal, elite, and boss silhouettes are readable;
- feet remain on the same world baseline during movement;
- sprites keep their aspect ratios and crisp edges;
- dense normal waves do not become visually indecipherable;
- elite and boss hierarchy is immediately apparent;
- no new console errors occur;
- camera zoom remains unchanged.

The existing lobby-header RenderFlex overflow is outside this change and should be reported separately if it reappears.
