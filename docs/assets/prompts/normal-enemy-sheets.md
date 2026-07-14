# Normal Enemy Sprite Sheet Evidence

Generated 2026-07-15 with OpenAI built-in image generation. The built-in tool did not expose a model identifier. No input images were used; inputs were project-owned text and palette tokens only.

## Common production prompt

Each request specified a production enemy animation sheet with exactly 16 frames in a strict 4×4 grid: movement 1–4, attack 1–4, hit 1–2, then death 1–6. Every request required the same subject identity, proportions, palette, facing, anchor, and scale across cells; original project-only 16-bit-style pixel art; hard outlines and upper-left moonlight; a perfectly uniform `#ff00ff` chroma-key background; and no text, labels, logos, signatures, watermark, scenery, shadow, extra characters, detached duplicate parts, or gore.

### `plague_rat_swarm`

```text
The exact same low wide cluster of three small plague rats in every cell, read as a swarm rather than one giant rat, ragged dark fur, sickly jade eyes, dusty paws, no clothing. Movement scurries with alternating bodies. Attack compresses then lunges. Hit recoils as one cluster without blood. Death scatters and settles into still small silhouettes. Palette: #101820 #263849 #9fb3c8 #f4ead2 #8f2d38 #3fbf7f. No soft fur.
```

- Source SHA-256: `E9B09D66F762D62CF3F8AF0B785A728D4BD582C015434DEAA071D6558B6744AD`
- Runtime SHA-256: `45ACE858C760117F85FFC786B375F363114E92C4BA5A4C6542C114479F0276D4`

### `bandit`

```text
The exact same lean Joseon mountain bandit in every cell, rough hemp clothes, seal-red cloth headband, chipped short knife, hunched forward chaser stance, simple straw shoes. Movement is a quick stalking run. Attack draws back then slashes once. Hit recoils without blood. Death progresses from stagger to collapse and stillness. Palette: #101820 #263849 #9fb3c8 #f4ead2 #d1495b #8f2d38 #f2cc8f.
```

- Source SHA-256: `870846BFB6D76D6ED89B9D3563404E541475941B823B5868130743F23DFBCD83`
- Runtime SHA-256: `B2650CDAD76962CCE5994167A1F93BA4440E02D0BE258E2B63DDF46B99046871`

### `dokkaebi`

```text
The exact same chunky nonhuman folklore dokkaebi in every cell, broad shoulders, low center of gravity, two short uneven horns, patched dark vest, thick trousers, wooden club, ember eyes, mischievous but threatening spirit face. Movement is a heavy stomp. Attack lifts and swings the club once. Hit braces and recoils without blood. Death loses balance, drops the club, collapses, and ends still. Palette: #101820 #263849 #9fb3c8 #f4ead2 #8f2d38 #f2cc8f #f08a5d. No generic fantasy franchise styling.
```

- Source SHA-256: `BC928B37D56C644FFB7DA340B7AE93E7B8FC72FBBE8BA140A7633F5B091BAD79`
- Runtime SHA-256: `5118328DE5EBC665D5F1B42418FAF1F5DE0F8C5B60C3BD17CA336D4026F6E665`

### `vengeful_spirit`

```text
The exact same nonhuman vengeful spirit in every cell, narrow pale upper body, torn moonlit hanbok fragments, dark hair mass that does not resemble a film character, cold cyan eyes, clearly broken floating lower silhouette with blocky spirit wisps. Movement drifts. Attack compresses then dashes with a short cyan afterimage contained inside the cell. Hit recoils without blood. Death breaks into a few blocky cyan fragments and fades to still remnants. Palette: #101820 #263849 #9fb3c8 #f4ead2 #7bdff2 #8f2d38. No photoreal transparency or horror-film imitation.
```

- Source SHA-256: `BE4D5EC34D94569C118711A87913CFD2D67B5B2584EED20585FE11039E146472`
- Runtime SHA-256: `F0D91CCD8461DBA3090E33F3D004EC1F73CCED8E31B2DB9D8B04CDC11ADF0246`

## Human processing and review

For each sheet, the sampled magenta background was removed with the installed chroma-key helper using soft matte and despill. The 4×4 cells were split and each opaque frame was normalized with nearest-neighbor sampling into a centered 24×24 rat cell or 32×32 standard cell. All 64 frames were visually reviewed for action order, silhouette, cell overlap, stray key color, text, signatures, logos, and unintended named-character similarity. Sources and alpha intermediates are retained under `source_assets/enemies/`.
