# Balanced Casual Bandit Atlas

- Project: original Joseon folk-fantasy mobile survival action game
- Generated: 2026-07-22
- Generation path: one OpenAI built-in image generation call
- Input images: `assets/images/player/exorcist_dosa_128.png` and
  `assets/images/monsters/dokkaebi_128.png`, used only as style and atlas-layout
  references
- Source: `source_assets/representative_set/enemy_atlases/bandit_atlas_source.png`
- Runtime target: `assets/images/monsters/bandit_128.png`, transparent RGBA
  `512x512` atlas with `4x4` `128x128` frames

The reference images informed only the compact chibi proportions, bold dark
outlines, flat cel shading, and atlas readability. The bandit is an original
project-only Joseon mountain-bandit design; it does not copy a commercial
character, asset, UI, effect, or pose.

## Final built-in generation prompt

```text
Use case: stylized-concept
Asset type: production 4x4 game sprite atlas source for an original Joseon bandit enemy
Input images: Image 1 is a style reference for compact chibi proportions, bold dark outline, flat cel shading, and atlas layout only. Image 2 is a style reference for enemy-scale readability, clean outline, and 4x4 pose-sheet layout only. Do not copy either character, clothing, pose, palette, or design.
Primary request: Create one exact square 4 by 4 animation sprite sheet of the same original Korean/Joseon mountain bandit, with sixteen distinct sequential poses read left-to-right then top-to-bottom.
Subject: an original compact, lean, friendly-menacing Joseon mountain bandit. He has a large readable face, short dark topknot wrapped in a seal-red cloth headband, rough charcoal hemp jeogori with muted indigo patches, loose warm-tan baji trousers, straw shoes, and a chipped short Korean hwando held consistently in his right hand (viewer left). He has no armor, no logo, no recognizable commercial-game likeness. Strong clear silhouette, grounded chaser stance, weapon and face orientation remain consistent.
Sequence contract: Row 1 frames 0-3 are a seamless stalking run cycle with alternating feet and a bobbing knife hand, frame 3 flows into frame 0. Row 2 frames 4-7 are one melee attack: a readable warning/ready pose, wind-up, one forward slash with a short muted gold motion arc fully contained inside its cell, then recoil. Row 3 frames 8-9 are two clear non-gory hit reactions: squash/stagger and recover; cells 10-11 start the death sequence. Row 4 cells 12-15 continue the six total death frames at cells 10-15: stagger, kneel, fall, lie still, then fade to a few non-gory warm folk-spirit motes by frame 15. All sixteen cells must contain some visible art, including the final motes.
Composition/framing: exact 4 equal columns x 4 equal rows, centered orthographic three-quarter/front mobile-game view. Same apparent character scale and same foot ground anchor in every occupied cell. Each pose stays fully inside its own cell with generous internal padding and no part crosses cell boundaries.
Style/medium: polished original cute 3-to-4-head mobile casual Joseon folk-fantasy game art; bold clean near-black outline; two-to-three large flat cel-shaded color planes; crisp opaque edges; readable at 32-56px. No pixel art and no realism.
Scene/backdrop: perfectly flat uniform solid #00FF00 chroma-key covering every background pixel.
Constraints: the background must be exactly one uniform color with no shadows, gradients, texture, reflections, floor plane, lighting variation, grid lines, separators, labels, numbers, text, watermark, frame, or border. Do not use #00FF00 in the character or effects. No Japanese samurai armor, katana, kabuto, hakama, or Chinese wuxia robe; no modern clothing; no gore; no copied commercial character, UI, or effect. No cropped body, feet, headband, or weapon.
```

## Runtime processing and review

The built-in source was generated on a flat chroma-key background and processed
with the installed `remove_chroma_key.py` helper using border auto-key sampling,
soft matte, thresholds `12/220`, and despill. Its four source cells per axis
were cropped independently, proportionally resized into `126x126` safe regions,
and composited at one-pixel offsets in each runtime cell. This keeps every
cell boundary transparent and prevents neighboring-frame leakage.

Review at original resolution confirmed the clear Joseon bandit silhouette,
consistent headband and weapon side, readable movement/attack/hit/death order,
and non-gory final folk-spirit motes. PNG validation confirms RGBA color type,
exact `512x512` dimensions, transparent corners, transparent cell gutters, and
visible content in all 16 frames.
