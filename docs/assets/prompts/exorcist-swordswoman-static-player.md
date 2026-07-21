# Exorcist Swordswoman Static Player Art

- Generation path: OpenAI built-in image generation
- Approved setting-sheet SHA-256: `908C38F863EF6B36B02309B020FDAA0F1D52DE33DE37DED1EC868A87674A82A3`
- Final chroma source SHA-256: `8C39A9FD847EA9373FF0F24FD8ABDC376AE2D33ABDE7F5A4CA41E172CF59EF68`
- Alpha intermediate SHA-256: `45D1D96C2181BD76325986C6A06BDBC5C4DF487BDE2EB6541EDB53CC8946D869`
- Runtime PNG SHA-256: `A3878148F05B966A2B18F004826B5B506872C5D5FDA11B2EC96D8C4D3F9AD80E`

## Final generation prompt

Use case: identity-preserve. Asset type: static player character chroma-key source for a Flutter + Flame mobile game. Image 1 is the approved character reference. Preserve the exact same late-Joseon female exorcist swordswoman, face, stern expression, red talisman below her anatomical left eye, black center-parted high bun, hairpin, red ribbons, four-head proportions, deep-navy cheollik, ivory collar, layered crimson sash, white beoseon, black shoes, and approved Saingeom. Keep a strict front-facing neutral pose. Hold the same Saingeom diagonally downward close to the body, fully visible, with restrained crimson flame. Use thick dark outlines and flat two-to-three-step cel shading. Render exactly one centered full-body character on a perfectly uniform `#00ff00` background with no shadow, gradient, texture, floor, text, logo, watermark, pixel art, sprite sheet, or animation frames.

## Post-processing

The sampled green background was removed with the installed imagegen chroma-key helper using border auto-keying, soft matte, and despill. The visible subject was proportionally fitted into a bottom-centered 64×64 RGBA canvas with Lanczos sampling. The runtime image retains transparent corners and is rendered at 36×36 Flame world units over the unchanged 24×24 gameplay component size.
