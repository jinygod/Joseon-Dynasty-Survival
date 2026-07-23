# Missing Eight Enemy Sprite Sheets

Produce eight separate 512x512 RGBA PNG actor sheets at the runtime paths
`assets/images/enemies/<id>_128.png`. Each sheet is a 4-column by 4-row grid
of 128x128 cells with a transparent background; transparency must be genuine,
not a checkerboard or painted backdrop. These are pixel-compatible,
16-bit-inspired Joseon sprites, continuous in rendering language with the five
existing enemy sheets but not copied from them. The larger 128px cells need
enough internal resolution for clean silhouettes.

Every cell presents the same three-quarter-right identity, consistent scale,
and one stable foot/hover anchor. Frames 0-3: move. Frames 4-7: attack.
Frames 8-9: hit. Frames 10-15: death. Keep the actor readable in every pose;
death ends at the same anchor or rises directly from it for a hovering actor.
Actor sheets must not bake persistent hazards, telegraphs, shockwaves, or
scream zones into frames. Do not add text, labels, logos, scenery, cross-cell
trails, duplicated anatomy/weapons, commercial-character imitation, Japanese
samurai motifs, or Chinese wuxia motifs.

## sakkat_specter

Wide battered sakkat and a narrow indigo suspended robe define a cold-cyan,
prayer-bead-charm specter. Its attack is a rightward talisman cast; death is an
upward unravel into a small contained wisp. Keep it distinctly not vengeful spirit:
no long hair, mourning dress, or generic revenge-ghost silhouette.

## plague_crow

Make a low, angular, asymmetrical black bird with a single jade eye and jade
feet. The attack is a rightward dive-peck and death is a feathered crumple at
the foot anchor. It is not rat/humanoid: retain a bird-only body plan, beak,
wings, and short avian legs.

## spear_bandit

Use a tall, narrow spear triangle, straw rain hood, and umber/vermilion cloth.
The intact spear makes a rightward thrust; death is a knee buckle while the
spear remains coherent. It is not knife bandit: no short-blade silhouette or
generic bandit replacement.

## rotten_herbalist

This bent gatherer has a swollen satchel, moss/olive clothes, and a cracked
gourd. It tosses a small contained gourd charge to the right, then dies through
a contained leak at its own anchor. Use no baked poison pool; the actor sheet
must not depict a persistent ground hazard.

## grave_ember

Draw a compact floating charcoal censer/urn with ember-orange and cool-cyan
light. Its attack is a contained pulse toward the right and death is an
extinguished cinder collapse at the hover anchor. It is not dokkaebi/humanoid:
no goblin face, limbs, or person-shaped body.

## black_hat_assassin

Give this tall figure a gat, split scarf, near-black/navy/crimson palette, and
twin hooked blades. The attack has two contained rightward dash cuts; death is
a hat-off collapse. It is not bandit/general: avoid a broad soldier outline,
armor, command pose, or ordinary bandit weapon read.

## broken_jangseung_spirit

Build a vertical cracked cedar guardian post with a splinter arm, paper charm,
and teal cracks. Its attack is a contained rightward stamp; death is a topple
that preserves the base anchor until the fall. Use no full shockwave baked in;
any area effect is a separate runtime visual.

## sorrowful_maiden_ghost

Use a bell mourning skirt, veil, broad sleeves, ivory/ink palette, and teal
tears. Her attack is a contained rightward scream pose; death is an inward
dissolve at the hover anchor. She is not vengeful-spirit hair/sakkat: do not
reuse the long-haired revenge-ghost profile or the sakkat specter's hat.
