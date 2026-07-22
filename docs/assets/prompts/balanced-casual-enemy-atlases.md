# Balanced Casual Representative Enemy Atlases

- Project: original Joseon folk-fantasy mobile survival action game
- Generation path: four separate OpenAI built-in image generation calls
- Identity reference: `source_assets/representative_set/enemy_role_lineup.png`
- Generated: 2026-07-22
- Runtime processing: flat-green chroma-key removal with the installed helper,
  proportional per-cell normalization to a transparent 512x512 RGBA atlas,
  and one-pixel transparent cell gutters

The four calls below used the approved lineup only as an identity and style
reference. They do not derive from a commercial game asset.

## `plague_rat_swarm`

```text
Use case: stylized-concept
Asset type: production 4x4 game sprite atlas source for plague_rat_swarm
Input image: reference image; preserve only the leftmost plague rat swarm identity, proportions, face, charcoal-black fur, coral ears/tails, mint eyes, bold black outline, and clean cel shading.
Primary request: Create one exact square 4 by 4 animation sprite sheet of the same three-rat swarm as a single gameplay unit, with sixteen distinct sequential poses, read left-to-right then top-to-bottom.
Sequence contract:
row 1 frames 0-3: seamless looping scurry/walk cycle, three rats bunch and bob with alternating paws and tails, frame 3 flows into frame 0.
row 2 frames 4-7: swarm attack sequence: huddle low, rear up, then all three lunge and snap forward, finally recoil.
row 3 frames 8-9: two clear hit-reaction frames, brief squash and stagger; frames 10-11 must be fully empty background only.
row 4 frames 12-15 plus row 3 frames 10-11 together form six death frames in chronological order: rats tumble, flatten into charcoal wisps, and fully vanish by frame 15. IMPORTANT: because runtime numbering is continuous, put death frames at cell positions 10,11,12,13,14,15, filling the last two cells of row 3 and all four cells of row 4.
Composition: exact 4 equal columns x 4 equal rows, centered orthographic three-quarter/front game view, same apparent scale and same ground contact anchor in every occupied cell, generous internal padding, no part crosses a cell boundary. Keep all three rats recognizable as one compact swarm.
Style: cute friendly 3-head mobile casual Joseon folk-fantasy enemy, large readable silhouette, thick clean dark outline, simple bright cel shading, no pixel art, no realism.
Scene/backdrop: perfectly flat uniform solid #00FF00 chroma-key covering every background pixel.
Constraints: background one uniform color only; no shadows, gradients, texture, reflections, floor plane, lighting variation, grid lines, separators, labels, numbers, text, watermark, frame, or border. Do not use #00FF00 in the rats. Crisp opaque edges. Weapon/face orientation remains consistent. Sixteen cells must be unambiguous and complete.
```

## `vengeful_spirit`

```text
Use case: stylized-concept
Asset type: production 4x4 game sprite atlas source for vengeful_spirit
Input image: reference image; preserve only the second enemy identity: pale masklike face, sharp blue eyes, long black hair, torn deep-blue Joseon robe with white collar, tapered smoky ghost tail, bold clean outline and cel shading.
Primary request: Create one exact square 4 by 4 animation sprite sheet of this same female vengeful spirit, with sixteen distinct sequential poses read left-to-right then top-to-bottom.
Sequence contract:
row 1 frames 0-3: seamless floating movement loop, robe and hair rise/fall with subtle side drift, frame 3 flows into frame 0.
row 2 frames 4-7: role-accurate dash sequence. Frame 4 is a highly readable warning/ready pose: spirit pauses, coils smoky tail, leans toward the consistent attack direction. Frames 5-6 burst forward as an aggressive horizontal ghost dash with compressed hair/robe and cyan speed wisps contained in the cell. Frame 7 brakes/recoils. Keep face and orientation consistent.
row 3 frames 8-9: two clear hit reaction frames, white-blue recoil and hair snap; frames 10-11 begin the death sequence.
row 4 frames 12-15 continue the death sequence, for six death frames total at cells 10-15: body unravels into dark-blue/cyan spirit ribbons and fully disappears by frame 15.
Composition: exact 4 equal columns x 4 equal rows, centered orthographic three-quarter/front game view, same scale and same ground/tail anchor in every occupied cell, generous internal padding, no body part crosses a cell boundary.
Style: cute eerie 3-head mobile casual Joseon folk-fantasy enemy; large readable silhouette; thick clean dark outline; simple bright cel shading; no pixel art; not realistic; scary but approachable.
Scene/backdrop: perfectly flat uniform solid #00FF00 chroma-key covering every background pixel.
Constraints: background one uniform color only; no shadows, gradients, texture, reflection, floor plane, lighting variation, grid lines, separators, labels, numbers, text, watermark, frame, or border. Do not use #00FF00 in the character. Crisp opaque edges. No weapon. Sixteen cells must be unambiguous and complete.
```

## `sakkat_specter`

```text
Use case: stylized-concept
Asset type: production 4x4 game sprite atlas source for sakkat_specter
Input image: reference image; preserve only the third enemy identity: huge black Joseon satgat silhouette, small dark-purple masked face, glowing lavender eyes, ragged purple robe, tapered ghost tail, yellow-red paper talisman held consistently in the character's right hand (viewer left), bold clean outline and cel shading.
Primary request: Create one exact square 4 by 4 animation sprite sheet of this same sakkat specter, with sixteen distinct sequential poses read left-to-right then top-to-bottom.
Sequence contract:
row 1 frames 0-3: seamless hovering movement loop, satgat and sleeves bob, ghost tail sways; frame 3 flows into frame 0.
row 2 frames 4-7: role-accurate ranged talisman cast. Frame 4 is a strong readable warning/aim pose held still: satgat tips, glowing eyes lock forward, talisman arm draws back on the same side. Frame 5 raises the talisman, frame 6 thrusts/releases one small red-gold spirit bolt toward viewer-right but keeps every effect inside the cell, frame 7 follow-through/recoil. The talisman hand never swaps sides.
row 3 frames 8-9: two clear hit reaction frames, satgat jolts and robe compresses; frames 10-11 begin death.
row 4 frames 12-15 continue death, six death frames total at cells 10-15: satgat tilts/falls, robe and tail dissolve into purple wisps, fully vanished by frame 15.
Composition: exact 4 equal columns x 4 equal rows, centered orthographic three-quarter/front game view, same scale and same tail/ground anchor in every occupied cell, generous internal padding, no element crosses a cell boundary.
Style: cute mysterious 3-head mobile casual Joseon folk-fantasy enemy, large readable silhouette, thick clean dark outline, simple bright cel shading, no pixel art, no realism.
Scene/backdrop: perfectly flat uniform solid #00FF00 chroma-key covering every background pixel.
Constraints: background one uniform color only; no shadows, gradients, texture, reflection, floor plane, lighting variation, grid lines, separators, labels, numbers, legible writing, text, watermark, frame, or border. Do not use #00FF00 in the character. Crisp opaque edges. Keep satgat, face, talisman hand and attack direction consistent. Sixteen cells must be unambiguous and complete.
```

## `dokkaebi`

```text
Use case: stylized-concept
Asset type: production 4x4 game sprite atlas source for dokkaebi
Input image: reference image; preserve only the rightmost dokkaebi identity: round orange face and body, two tan horns, huge black eyebrows, friendly confident grin, red bulb nose, navy sleeveless Joseon vest, ivory trousers, red-yellow-blue sash, straw sandals, large wooden club held consistently in the character's right hand (viewer right), bold clean outline and cel shading.
Primary request: Create one exact square 4 by 4 animation sprite sheet of this same stocky defensive dokkaebi, with sixteen distinct sequential poses read left-to-right then top-to-bottom.
Sequence contract:
row 1 frames 0-3: seamless heavy walk loop, weight shifts and feet alternate while club stays on viewer-right; frame 3 flows into frame 0.
row 2 frames 4-7: role-accurate defensive attack sequence. Frame 4 is a strong readable frontal block/warning pose held still: plant feet, lower shoulders, raise club diagonally on viewer-right as a guard. Frame 5 winds the club back on the same side, frame 6 makes one broad forward club swing with a short orange-gold arc entirely inside the cell, frame 7 returns to guarded stance. Weapon hand never swaps sides.
row 3 frames 8-9: two clear hit reaction frames, body squashes and staggers but retains club; frames 10-11 begin death.
row 4 frames 12-15 continue death, six death frames total at cells 10-15: knees buckle, dokkaebi topples backward, breaks into warm orange/gold folk-spirit motes, and fully disappears by frame 15.
Composition: exact 4 equal columns x 4 equal rows, centered orthographic three-quarter/front game view, same apparent scale and same foot ground anchor in every occupied cell, generous internal padding, no body part or club crosses a cell boundary.
Style: cute friendly 3-head mobile casual Joseon folk-fantasy enemy; strong shield/tank silhouette; thick clean dark outline; simple bright cel shading; no pixel art; no realism; never samurai or wuxia.
Scene/backdrop: perfectly flat uniform solid #00FF00 chroma-key covering every background pixel.
Constraints: background one uniform color only; no shadows, gradients, texture, reflection, floor plane, lighting variation, grid lines, separators, labels, numbers, text, watermark, frame, or border. Do not use #00FF00 in the character. Crisp opaque edges. Keep face, sash, club hand, weapon side and attack direction consistent. Sixteen cells must be unambiguous and complete.
```
