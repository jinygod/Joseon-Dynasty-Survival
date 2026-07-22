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

Every figure uses a **bold clean outline** with a consistent 5-to-7-pixel
source-line weight, one upper-left key light, flat shadow shapes, and no tiny
pixel texture. Feet or the lowest visible spirit edge share one horizontal
baseline. Leave generous space around every silhouette. Show complete bodies,
weapons, hats, sleeves, and clubs without cropping.

## Player lineup prompt — `exorcist_dosa`

```text
Use case: stylized-concept
Asset type: game character concept lineup and future 128x128 animation-atlas reference
Primary request: create one original Joseon folk-fantasy exorcist swordsman,
shown in three consistent full-body neutral design views on one clean review sheet
Scene/backdrop: plain warm hanji-beige review background, no scenery or props
Subject: the exact same friendly 3.5-head-tall young exorcist swordsman in each
view; warm determined face; small black Joseon gat over a visible manggeon;
short vermilion cheollik and deep-navy sleeves; ivory collar; brass waist clasp;
oversized curved Korean hwando in a dark wood scabbard; a clearly visible bundle
of yellow paper talismans with red seals tied at the waist; white beoseon and
simple black shoes
Style/medium: polished original mobile-game character concept; bold clean dark
outline; bright flat colors; two-to-three-step cel shading; crisp opaque shapes
Composition/framing: landscape lineup; three evenly spaced views; complete body
and complete hwando visible; all feet touch the same horizontal baseline;
generous padding; no labels
Lighting/mood: consistent upper-left light; approachable, brave, energetic
Color palette: vermilion, deep navy, warm ivory, brass gold, warm skin, black
Equipment and silhouette lock: small gat-and-manggeon head shape, broad cheollik
sleeves, the large hwando curve, and the waist talisman bundle must remain the
four strongest silhouette cues
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
bright flat colors; two-to-three-step cel shading; crisp opaque shapes; no tiny
detail or painterly texture
Composition/framing: landscape lineup; equal visual spacing; complete bodies and
equipment visible; all feet or lowest spirit edges touch the same horizontal
baseline; generous padding; no overlap
Lighting/mood: one consistent upper-left key light across all four enemies;
playfully spooky and action-readable
Color palette: role-separated muted jade, moonlit blue-grey, purple-black, and
warm orange-brown accents against the warm beige background

plague_rat_swarm silhouette: a low, wide cluster of exactly three small plague
rats moving as one enemy; ragged cloth scraps, dusty dark fur, bright sickly-jade
eyes; a triangular three-head rhythm; no giant single rat, armor, weapons, gore,
or realistic soft fur

vengeful_spirit silhouette: a tall narrow floating Korean spirit with a broken
lower edge; torn moonlit hanbok, long hair and sleeves flowing backward, pale
expressive face; compressed shoulders and folded pose hint at a coming dash; no
legs, feet, weapon, horror-film likeness, gore, or transparent photo effects

sakkat_specter silhouette: a very wide flat Joseon sakkat above a narrow robed
spectral body; one hand gathers a small red-gold talisman flame for a ranged
attack; face mostly shadowed but not faceless; no conical Chinese douli, straw
rain cape, sword, gun, or floating projectile outside its hand

dokkaebi silhouette: a broad low nonhuman Korean dokkaebi with two short uneven
horns, large nose, wide shoulders, short legs, patched Joseon-style vest and
trousers, and one oversized wooden bangmangi club; mischievous readable face;
front-facing guarded stance suggests a 90-degree shield arc without a literal
shield; no oni mask, samurai armor, Chinese guardian armor, western ogre, gore,
or fire aura

Constraints: exactly four enemies and no extra creatures; every silhouette must
remain distinguishable in solid black; project-only original designs; no copied
commercial-game character, UI, effect, mascot, icon, logo, trademark, text,
signature, watermark, frame, border, scenery, background object, cropped body,
cropped hat, or cropped equipment
```

## Review and downstream contract

- `source_assets/representative_set/exorcist_dosa_lineup.png`
  - SHA-256: `09F2535F6C9E4F5255941B8D469C1A67D6EDDFAB7F62B951985893325202411F`
- `source_assets/representative_set/enemy_role_lineup.png`
  - SHA-256: `14EBA5CDB45C35D81A5C2DF57572A4F0A407574F6589273EA47E782A18D48BA1`
- Review at original resolution for silhouette separation, cultural vocabulary,
  complete limbs and equipment, common baseline, consistent outline, and common
  upper-left light.
- The player concept has complete equipment and a consistent three-view identity.
  Its body ratio is taller than the final 3-to-4-head runtime target, so the
  animation-atlas silhouette must be compressed rather than traced directly.
- The enemy roles are strongly separated, but the temporary rat concept contains
  four rats instead of the locked three-rat cluster. The runtime atlas must use
  exactly three rats and retain the low, wide triangular silhouette.
- The lineup images are visual references only. Runtime atlases must still be
  authored as 512x512 transparent RGBA sheets: `4x4` cells, `128x128` each.
- Runtime animation frames 0–3 move, 4–7 attack, 8–9 hit, and 10–15 death.
- Do not trace, repaint, or derive from attached commercial-game screenshots.
