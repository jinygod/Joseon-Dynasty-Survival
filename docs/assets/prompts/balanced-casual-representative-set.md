# Balanced Casual Representative Set

- Project: original Joseon folk-fantasy mobile survival action game
- Generation path: OpenAI built-in image generation
- Generated: 2026-07-22
- Review status: temporary concept lineup; not a runtime sprite atlas
- Runtime target: transparent RGBA `4x4` atlas, `128x128` per frame

These concept lineups lock the visual identity for `exorcist_dosa`,
`plague_rat_swarm`, `vengeful_spirit`, `sakkat_specter`, and `dokkaebi` before
their animation atlases are produced. They are original project-only designs,
not references to or copies of any commercial-game character, asset, UI, or
effect.

## Shared style lock

```text
Original mobile action-game character lineup for a Joseon folk-fantasy project.
Friendly 3-to-4-head proportions, bold clean dark outline, two-to-three-step
cel shading, bright flat colors, readable facial expression, centered neutral
pose, consistent upper-left light, transparent or plain review background.
No samurai armor, no wuxia robes, no copied commercial-game character, no UI.
```

Every figure uses a **bold clean outline** with a consistent 7-to-9-pixel
source-line weight, one upper-left key light, two large flat shade shapes per
material, and no tiny pixel texture, grain, crosshatching, seam noise, or small
ornament. The design must remain readable when reduced to 32–56px. Feet or the
lowest visible spirit edge share one horizontal baseline. Leave generous space
around every silhouette. Show complete bodies, weapons, hats, sleeves, and clubs
without cropping.

## Player lineup prompt — `exorcist_dosa`

```text
Use case: stylized-concept
Asset type: game character concept lineup and future 128x128 animation-atlas reference
Primary request: create one original Joseon folk-fantasy exorcist swordsman,
shown in three consistent full-body neutral design views on one clean review sheet
Scene/backdrop: plain warm hanji-beige review background, no scenery or props
Subject: the exact same unmistakably chibi 3.5-head-tall young exorcist swordsman
in each view; the chin-to-crown head height is exactly about 28.5 percent of the
full body height excluding the gat, never adult or heroic proportions; very
large friendly face and readable eyes, oversized hands; warm determined face;
small black Joseon gat over a visible manggeon;
short vermilion cheollik and deep-navy sleeves; ivory collar; brass waist clasp;
an oversized curved Korean hwando whose blade-and-scabbard length is about the
character's full body height and whose guard is clearly readable; a clearly
visible bundle of three large yellow paper talismans with red seals tied at the
waist; short chunky legs, white beoseon and simple black shoes
Style/medium: polished original mobile-game character concept; bold clean dark
outline; bright flat colors; two-to-three-step cel shading built from large
simple color planes; crisp opaque shapes; no fabric grain, fine folds, hatching,
tiny embroidery, realistic anatomy, or small decorative lines; readable at 56px
Composition/framing: landscape lineup; three evenly spaced views; complete body
and complete hwando visible; all feet touch the same horizontal baseline;
generous padding; no labels
Lighting/mood: consistent upper-left light; approachable, brave, energetic
Color palette: vermilion, deep navy, warm ivory, brass gold, warm skin, black
Equipment and silhouette lock: oversized round face, small gat-and-manggeon head
shape, broad cheollik sleeves, huge hwando curve, large hands, and the waist
talisman bundle must remain the strongest silhouette cues; the character must
visibly measure only three and one-half heads tall in all three views
Constraints: historically grounded Joseon clothing vocabulary; original
project-only design; no Japanese armor, kabuto, katana, hakama, topknot, or
torii; no Chinese wuxia robe, queue, tassel sword, or martial-sect styling; no
generic European fantasy armor; no modern clothing; no extra people; no cropped
body or equipment; no text, logo, signature, watermark, border, UI, or background
objects
```

## Enemy lineup prompt — four role silhouettes

```text
Use case: stylized-concept
Asset type: four-enemy game character lineup and future 128x128 4x4 animation-atlas reference
Primary request: create four original, clearly distinct Joseon folk-fantasy
enemies in one polished mobile-game lineup
Scene/backdrop: plain warm hanji-beige review background, no scenery or props
Subject: exactly four separated full-body enemy designs, ordered only by the
descriptions below and without written labels; each is friendly-creepy rather
than gory and readable at small mobile size
Style/medium: original mobile-game character concept; bold clean dark outline;
bright flat colors; two-to-three-step cel shading with very large simple color
planes; crisp opaque shapes; optimize every subject for clear 32–56px gameplay
readability; no tiny detail, fabric grain, fur strands, scratches, necklaces,
surface pattern, painterly texture, crosshatching, or decorative line clutter
Composition/framing: landscape lineup; equal visual spacing; complete bodies and
equipment visible; all feet or lowest spirit edges touch the same horizontal
baseline; generous padding; no overlap
Lighting/mood: one consistent upper-left key light across all four enemies;
playfully spooky and action-readable
Color palette: role-separated muted jade, moonlit blue-grey, purple-black, and
warm orange-brown accents against the warm beige background

plague_rat_swarm silhouette: one compact low-wide game unit containing exactly
three rats total, never four; two rats in front and one centered behind form an
obvious triangle with exactly three heads, three bodies, and three pairs of
glowing sickly-jade eyes; simplified dusty dark-fur shapes and one large ragged
cloth patch per rat; no hidden fourth rat, giant single rat, armor, weapons,
gore, individual fur strands, or realistic soft fur

vengeful_spirit silhouette: a tall narrow floating Korean spirit with a broken
lower edge; torn moonlit hanbok, long hair and sleeves flowing backward, pale
expressive face; compressed shoulders and folded pose hint at a coming dash; no
legs, feet, weapon, horror-film likeness, gore, or transparent photo effects

sakkat_specter silhouette: a very wide flat Joseon sakkat above a narrow robed
spectral body; one hand gathers a small red-gold talisman flame for a ranged
attack; face mostly shadowed but not faceless; no conical Chinese douli, straw
rain cape, sword, gun, or floating projectile outside its hand

dokkaebi silhouette: a broad low specifically Korean folk-tale dokkaebi, not a
generic fantasy ogre; warm persimmon-orange skin, humanlike rounded ears, two
short uneven blunt horn nubs, one large round red nose, thick curved eyebrows,
wide mischievous smile without tusks, round belly and short chunky legs; simple
indigo Joseon jeogori-style vest, roomy ivory baji trousers, straw sandals and a
bold saekdong waist sash; one oversized plain wooden bangmangi club with a round
knot at the end; front-facing guarded stance suggests a 90-degree shield arc
without a literal shield; no green or grey ogre skin, pointy elf ears, tusks,
mohawk, bodybuilder muscles, fur armor, wrist wraps, oni mask, samurai armor,
Chinese guardian armor, western troll/ogre styling, gore, or fire aura

Constraints: exactly four enemies and no extra creatures; every silhouette must
remain distinguishable in solid black; project-only original designs; no copied
commercial-game character, UI, effect, mascot, icon, logo, trademark, text,
signature, watermark, frame, border, scenery, background object, cropped body,
cropped hat, or cropped equipment
```

## Review and downstream contract

- `source_assets/representative_set/exorcist_dosa_lineup.png`
  - SHA-256: `43A0B3C01976E6534B735CC7C2426C25CD16C6358BC23C10EA3B5D8F017732F0`
- `source_assets/representative_set/enemy_role_lineup.png`
  - SHA-256: `07BD98186EFCC355E2230DEE785BDD6EB314585517ED9440342590D0506381F0`
- Review at original resolution for silhouette separation, cultural vocabulary,
  complete limbs and equipment, common baseline, consistent outline, and common
  upper-left light.
- The player must visibly measure 3.5 heads tall with a large face, hands and
  hwando before it may be used as the runtime-atlas identity reference.
- The rat unit must visibly contain exactly three rats in a low, wide triangular
  arrangement. A fourth head or body is a rejection condition.
- The dokkaebi must read as Korean folk/Joseon through its warm face, round nose,
  jeogori-style vest, baji, saekdong sash and bangmangi rather than generic ogre
  anatomy or fantasy armor.
- The reviewed player replacement visibly uses a short 3.5-head chibi body,
  oversized face and hands, a body-length hwando, and large flat cel-shaded color
  planes suitable for the 56px display target.
- The reviewed enemy replacement contains exactly three countable rats, removes
  fine surface clutter, and gives the dokkaebi the locked Korean/Joseon clothing
  and color cues without generic ogre armor.
- The lineup images are visual references only. Runtime atlases must still be
  authored as 512x512 transparent RGBA sheets: `4x4` cells, `128x128` each.
- Runtime animation frames 0–3 move, 4–7 attack, 8–9 hit, and 10–15 death.
- Do not trace, repaint, or derive from attached commercial-game screenshots.
