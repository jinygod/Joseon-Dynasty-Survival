# Fallen General Boss Sheet Evidence

- Asset ID: `fallen_general_animation`
- Generated: 2026-07-15
- Provider/product: OpenAI built-in image generation
- Model identifier: not exposed by the built-in tool
- Input images: none
- Input rights: confirmed; project-owned text and style tokens only
- Source SHA-256: `0AD26860047A09DD0E769E4FE88F03129D0F9C88D9547301581E8D340DE6A3E4`
- Runtime SHA-256: `237680964DAAD4DCDABCB52A56CE10CC2736F80FC835698CF98FEEA1CA50A76F`

## Final prompt

```text
Use case: stylized-concept. Asset type: production 16-frame pixel-art boss sprite sheet. Create one original fallen Joseon guard commander for a mobile folk-horror survival game, exactly a 4x4 grid on a perfectly uniform solid #ff00ff chroma-key background with no grid lines. Row 1: four slow armored movement frames. Row 2: four pattern frames—command-sword windup, forward charge, wide cone slash, spirit-summon command. Row 3: two hit reactions then death frames 1-2. Row 4: death frames 3-6 ending still. Same character, proportions, armor, facing three-quarter right, ground anchor, scale, and palette in every cell. Large silhouette at least twice a normal enemy: broken dark Joseon lamellar armor, cracked helmet, damaged command sword, close cold-cyan aura, asymmetric broken left shoulder plate. Crisp blocky limited-palette 16-bit game art, hard dark outlines, upper-left moonlight, no antialiasing or gradients. Colors #101820 #263849 #9fb3c8 #f4ead2 #d1495b #8f2d38 #f2cc8f #7bdff2 #f08a5d; no magenta in subject. Exact 16 cells, one centered boss per cell, generous padding, nothing crosses cells. Original project-only design; no text, labels, logos, signature, watermark, scenery, shadow, floor, extra characters, detached anatomy, gore, photorealism, or imitation of any named game character.
```

## Human processing and review

The sampled magenta background was removed with the installed helper using soft matte and despill. Each of the 16 cells was bottom-centered and nearest-neighbor normalized into a 64×64 cell, producing a 256×256 RGBA runtime sheet. All frames were reviewed for pattern readability, large asymmetric silhouette, cell overlap, stray key color, text, signatures, logos, and named-character similarity. Source and alpha intermediate are retained under `source_assets/bosses/`.
