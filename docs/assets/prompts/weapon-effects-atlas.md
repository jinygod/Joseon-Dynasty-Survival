# Weapon Effects Atlas Evidence

- Asset ID: `weapon_effects_atlas`
- Generated: 2026-07-15
- Provider/product: OpenAI built-in image generation
- Model identifier: not exposed by the built-in tool
- Input images: none
- Input rights: confirmed; project-owned text and style tokens only
- Source SHA-256: `4B94ACD48A9D2215875635F93CA6EEBB7D68DBF7395FDA6F535BAE46E260E53E`
- Runtime SHA-256: `F7FB6D0122B8A90CF3CC4C50999E5D8AFBCEE2D3F190B78CFFC5381B9E009680`

## Final prompt

```text
Use case: stylized-concept
Asset type: production game weapon effect atlas
Primary request: create exactly 16 original pixel-art effect frames in a strict 4 columns by 4 rows grid for a Joseon folk-horror mobile survival game. Row 1: four-frame hwando crescent slash progression from narrow windup glint to broad pale-blue arc to impact sparks to fading trail. Row 2: four-frame gakgung arrow projectile flight with compact arrow, increasingly readable brass-and-moon-blue speed trail, all facing right. Row 3: four-frame paper talisman projectile flight with red seal marks and controlled spirit-cyan ink sparks, all facing right. Row 4: four-frame thunder-crash black-powder bomb sequence: lit fuse warning, bright ignition, circular lightning explosion, fading smoke-and-spark ring.
Scene/backdrop: perfectly flat solid #ff00ff chroma-key background; no grid lines or cell borders.
Style/medium: crisp limited-palette pixel art, deliberately blocky 16-bit game effect sprites, hard readable edges, no antialiasing, no gradients, no painterly smoke, no photoreal glow.
Composition/framing: square canvas, exactly 4x4 equal cells, one centered effect per cell, generous equal padding, nothing crosses cell boundaries. Every frame must remain readable when normalized into a 64x64 cell.
Color palette: #101820 #9fb3c8 #f4ead2 #d1495b #8f2d38 #f2cc8f #7bdff2 #f08a5d #e63946. Do not use magenta in any effect.
Constraints: original project-only design; exact 16 cells; transparent-ready isolated effects only; no hands, characters, scenery, ground, cast shadows, text, labels, numbers, logos, signature, watermark, gore, extra weapons, or duplicated unrelated parts. Background is uniform #ff00ff with no texture, lighting variation, gradient, reflection, or shadow.
```

## Human processing and review

The sampled magenta background was removed with the installed helper using soft matte and despill. Each of the 16 cells was centered and nearest-neighbor normalized into a 64×64 cell, producing a 256×256 RGBA atlas. Every frame was reviewed for weapon identity, progression order, cell overlap, stray key color, text, signatures, logos, and unrelated objects. Source and alpha intermediate are retained under `source_assets/weapons/`.
