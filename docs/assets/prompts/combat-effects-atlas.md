# Combat Effects Atlas Evidence

- Asset ID: `combat_effects_atlas`
- Generated: 2026-07-15
- Provider/product: OpenAI built-in image generation
- Model identifier: not exposed by the built-in tool
- Input images: none
- Input rights: confirmed; project-owned text and style tokens only
- Source SHA-256: `6CB40B41682EA871042B378878C7E68FBE9CDA522F89728AECDE7D504F809154`
- Alpha intermediate SHA-256: `0EBD1CA5B4CB45CEEC392CA647DE29C02E810A8354C468EEF9AF12C8FD9F0E1E`
- Runtime SHA-256: `8C8C70750F39547D827C3716B5212C76209A3171877778CFA244AF4D03BA4F3E`

## Final prompt

```text
Use case: stylized-concept
Asset type: production game combat feedback atlas
Primary request: create exactly 20 original pixel-art effect frames in a strict 4 columns by 5 rows grid for a Joseon folk-horror mobile survival game. Row 1: four-frame experience pickup progression, a compact jade moon orb that brightens and pulses. Row 2: four-frame normal-hit progression using pale hanji fragments, red seal flecks, and restrained sparks. Row 3: four-frame critical-hit progression, a larger brass-and-spirit-cyan starburst with a strong readable center. Row 4: four-frame enemy-death progression made from dark indigo shadow motes dispersing into smoke, with no anatomy and no gore. Row 5: four-frame danger-warning progression, a red omen ring that grows, intensifies, and prepares to trigger.
Scene/backdrop: perfectly flat solid #ff00ff chroma-key background; no grid lines or cell borders.
Style/medium: crisp limited-palette pixel art, deliberately blocky 16-bit game-effect sprites, hard readable edges, no antialiasing, no gradients, no painterly rendering, no photoreal glow.
Composition/framing: portrait atlas, exactly 4x5 equal cells, one centered effect per cell, generous equal padding, nothing crosses cell boundaries. Every frame must remain readable when normalized into a 64x64 cell.
Color palette: #101820 #263849 #9fb3c8 #f4ead2 #d1495b #8f2d38 #f2cc8f #7bdff2 #3fbf7f #e63946. Do not use magenta in any effect.
Constraints: original project-only design; exact 20 cells; transparent-ready isolated effects only; no characters, body parts, scenery, ground, cast shadows, text, labels, numbers, logos, signature, watermark, blood, gore, or unrelated objects. Background is uniform #ff00ff with no texture, lighting variation, gradient, reflection, or shadow.
```

## Human processing and review

The sampled magenta background was removed with the installed helper using soft matte and despill. Each of the 20 cells was centered and nearest-neighbor normalized into a 64x64 cell, producing a 256x320 RGBA atlas. All rows were reviewed for semantic order, animation progression, cell overlap, stray key color, text, signatures, logos, anatomy, gore, and unrelated objects. Source and alpha intermediate are retained under `source_assets/effects/`.
