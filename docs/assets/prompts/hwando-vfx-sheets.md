# Hwando VFX Generated Contact Sheets

Generated on 2026-07-23 with OpenAI built-in image generation. Every accepted
source uses a perfectly flat `#00ff00` chroma-key background and was converted
to RGBA with the installed imagegen `remove_chroma_key.py` helper, then split
and normalized into 128 px cells.

Common constraints for every prompt: original project-only illustrated mobile
game VFX; ink-black brush outer edge; antique-gold and warm-ivory energy;
bold dark outline; two-to-three cel-shaded values; consistent upper-left
lighting; no character, hand, weapon hilt, scenery, text, letters, readable
seals, logos, watermark, commercial-game resemblance, or green in the effect.
The backdrop is one uniform `#00ff00` with no shadows, gradients, texture,
floor, reflection, or lighting variation.

## `hwando_slash_trail_128`

Create an original directional Hwando sword slash trail progression in exactly
six equal horizontal animation frames, left to right, with no borders or grid.
Frame 1 is a small initiating slash; frames 2–5 sweep forward in a consistent
diagonal crescent; frame 6 is a fading tapered trail. Keep every frame in its
implied square with generous padding.

## `hwando_slash_impact_128`

Create an original Hwando slash impact progression in exactly five equal
horizontal frames: spark, expanding crescent burst, strongest impact, breaking
sparks, and fade. Keep each frame inside its implied square with generous
padding.

## `hwando_blade_wave_trail_128`

Create a strictly horizontal six-frame contact sheet in one single left-to-right
row, with no borders or grid. Create a directional blade-wave trail: small
narrow wave, longer wave, longer wave, peak longest wave, thinning wave, and
fading wave. Each separate projectile wave is centered in its implied square,
has generous empty padding, and never overlaps a neighboring frame.

## `hwando_blade_wave_impact_128`

Create an original blade-wave impact progression in exactly five equal
horizontal frames: small angular spark, expanding slash burst, peak crescent
explosion, scattered ink-gold fragments, and soft fade.

## `hwando_master_circle_trail_128`

Create an original master circular trail progression in exactly eight equal
horizontal square frames: small arc, quarter ring, half ring, three-quarter
ring, full dynamic circle, reinforced circle, breaking circular fragments, and
fading ring. Keep the central pivot identical in every frame.

## `hwando_master_circle_impact_128`

Create an original master-circle impact progression in exactly six equal
horizontal frames: spark ignition, expanding ring impact, peak bright circular
strike, fractured ring with sparks, scattered fragments, and fade. Keep an
identical central pivot and generous padding in every frame.

## `hwando_master_finisher_trail_128`

Create an original master-finisher trail progression in exactly eight equal
horizontal square frames: tiny ignition, first arc, larger arc, two overlapping
arcs, strongest long crescent, trailing ribbon, breaking sparks, and fade.
Maintain a consistent direction and pivot.

## `hwando_master_finisher_impact_128`

Create an original master-finisher impact progression in exactly six equal
horizontal frames: tiny ignition, sharp cross-crescent burst, peak long
explosive crescent, bright fractured core, scattered sparks, and fading taper.
Keep a consistent pivot and generous padding.

## Rejected generation

The first `hwando_blade_wave_trail` source was rejected because it arranged
the six phases vertically instead of in the required horizontal row. It is
retained at `art_source/generated/hwando/hwando_blade_wave_trail_rejected_vertical_source.png`
for provenance only and is not used by a runtime asset.
