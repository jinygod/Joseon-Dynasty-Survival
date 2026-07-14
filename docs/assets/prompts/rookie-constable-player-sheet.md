# Rookie Constable Player Sheet Evidence

- Asset ID: `rookie_constable_player_animation`
- Generated: 2026-07-15
- Provider/product: OpenAI built-in image generation
- Model identifier: not exposed by the built-in tool
- Source output SHA-256: `596CF60C55ACBAF6D8E20BE360335964D7750B915897A0DC31CBC7158AD3A02B`
- Runtime output SHA-256: `191F755810DC416C99667D6C980E7A4B196131543C7D014298A55DE335CFDD1B`
- Input images: none
- Input rights: confirmed; text prompt and project-owned style tokens only

## Final prompt

```text
Use case: stylized-concept
Asset type: production game character animation sprite sheet
Primary request: create one original Joseon-era rookie constable character sprite sheet for a mobile survival roguelite, exactly 16 frames arranged in a strict 4 columns by 4 rows grid. Row 1: walk cycle frames 1-4. Row 2: walk cycle frames 5-6, then hit reaction frames 1-2. Row 3: death animation frames 1-4. Row 4: death animation frames 5-8.
Scene/backdrop: perfectly flat solid #ff00ff chroma-key background for local background removal; no grid lines and no cell borders.
Subject: the exact same compact rookie constable in every cell, full body, small black gat-inspired hat, simple blue-gray Joseon uniform, short hwando at waist, dark boots, determined neutral face. Preserve identical proportions, outfit, colors, facing three-quarter right, anchor position, and scale across all 16 cells. Walk frames show readable alternating legs and restrained arm/coat movement. Hit frames recoil backward with a pale impact accent but no blood or gore. Death frames progress clearly from stagger to kneel to fall and end fully still.
Style/medium: crisp limited-palette pixel art, deliberately blocky 16-bit game sprite aesthetic, hard 1-pixel-equivalent dark outlines, upper-left moonlight, no antialiasing, no gradients, no painterly texture.
Composition/framing: square canvas; exactly 4x4 equal cells; one centered character per cell; generous equal padding; nothing crosses cell boundaries.
Color palette: ink-night #101820, moon-slate #263849, moon-mist #9fb3c8, hanji #f4ead2, seal-red #d1495b, deep-seal #8f2d38, brass #f2cc8f, spirit-cyan #7bdff2, ember #f08a5d. Do not use the chroma-key magenta in the character.
Constraints: original design made only for this project; no text, labels, numbers, logos, signatures, watermark, shadows, floor plane, scenery, extra props, detached duplicate body parts, or gore. Background must be perfectly uniform #ff00ff with no texture, lighting variation, gradient, reflection, or shadow. Exact 16 characters only.
```

## Human processing and review

1. Removed the sampled flat magenta background with the installed chroma-key helper using soft matte and despill.
2. Split the 4×4 source cells and normalized each opaque frame into a bottom-centered 32×32 cell with nearest-neighbor sampling.
3. Combined the cells into the 128×128 RGBA runtime sheet without adding or redrawing content.
4. Visually reviewed all 16 frames for consistent character identity, required actions, stray key color, text, signatures, logos, and cell overlap.
5. Confirmed the design does not intentionally reference a named game, artist, character, trademark, or real person.

The generated source and alpha intermediate are retained under `source_assets/player/`. The runtime PNG is `assets/images/player/rookie_constable_player_32.png`.
