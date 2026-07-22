# Combat VFX, Enemy Art, and Progress HUD Design

## Goal

Replace every visible placeholder rectangle and primitive-only combat effect in the current playable slice with a readable, high-impact Joseon folk-fantasy presentation. The result must make weapon growth visually obvious on a phone while preserving the existing attack geometry, save IDs, balance, and enemy warning readability.

## Approved approach

Use a hybrid pipeline:

- Character art uses reviewed 4-by-4 raster atlases with 128-pixel frames, bold outlines, compact 3–4-head proportions, and clear Joseon clothing silhouettes.
- Fast combat effects use deterministic code-native rendering derived from the same attack data as damage resolution. This avoids waiting for a full effect-art production batch and guarantees that direction, radius, and timing remain aligned with gameplay.
- Existing compatible effect atlases remain optional accents. Missing or delayed assets must never fall back to a plain rectangle, line, or single flat circle.

This approach is preferred over enlarging legacy pixels, which preserves the visual mismatch, and over producing a complete new atlas library before the combat feel is validated.

## Enemy presentation

`EnemySpriteSheet.specs` becomes a total mapping for every enemy ID that can appear in either implemented stage. The new bandit atlas uses the same 512-by-512 RGBA, 4-by-4 frame contract as the representative player and monsters:

- frames 0–3: movement
- frames 4–7: attack
- frames 8–9: hit
- frames 10–15: death

Bandit-family enemies use the new high-resolution bandit atlas for this slice. Other missing IDs map to the closest authored 128-pixel folk-fantasy family until their dedicated art is produced. The fallback renderer changes from a full-body rectangle to a compact, outlined folk-spirit silhouette so a transient asset-load failure cannot create another orange box.

## Shared combat VFX language

Every player attack uses a bounded combination of these layers:

1. a low-alpha footprint matching the exact hit geometry;
2. a saturated colored edge;
3. a bright narrow core that shows direction;
4. two to four short afterimages or motion ribbons;
5. a capped set of sparks, shards, smoke puffs, rune marks, or impact fragments;
6. a brief expanding impact ring for strong and master attacks.

No effect may cover the full screen with white, shake continuously, or erase enemy warnings. Particle counts are deterministic and capped per component; rendering avoids full-screen save layers and expensive unbounded blur.

### Weapon identities

- Hwando: cyan-white crescent ribbons, gold impact sparks, fast afterimages, and a layered circular master storm.
- Talisman: vermilion paper seals, gold ink marks, five-color fragments, rotating ward glyphs, and linked detonation pulses.
- Bow and singijeon: visible arrowheads, long tapered gold/red trails, ember flecks, and fan-shaped master lanes.
- Bomb and cannon: orange-white fire cores, dark smoke lobes, radial sparks, recoil streaks, and concentric shock rings.
- Frost flask: fractured ice floor, rotating snowflake sigil, crystalline perimeter, cold mist, and timed shard pulses. Master fields receive a stronger white-blue core and a connecting frost-wave treatment.
- Wind-thunder fan: violet/cyan curved gust ribbons and branching lightning.
- Jangseung ward and shaman bells: carved-seal rings, jade/gold motes, and rhythmic wave bands.
- Dokkaebi chain: linked green-gold segments with impact flares instead of a plain stroke.
- Hawk summon: a readable blue-gold bird silhouette with feather streaks.

Enemy telegraphs remain warnings rather than player spectacle: dash/thrust uses a translucent lane with chevrons and bright borders, ranged uses a target reticle, shield uses a filled directional guard arc, and hazards use authored poison, shockwave, or scream patterns instead of flat circles.

## Frost-field implementation

`FrostFieldComponent` retains its existing position, radius, duration, tick cadence, slow, and damage rules. Rendering adds:

- a layered icy footprint with a soft center and darker outer rim;
- six-way snowflake geometry rotating slowly with time;
- deterministic radial cracks tied to the field radius;
- eight perimeter crystals that pulse on damage ticks;
- drifting specks and a short tick ring;
- a stronger presentation tier supplied by weapon level/master state.

The visual radius is always calculated from the same `radius` used by `containsEnemy`.

## Experience and level HUD

Experience gems grow from 10 pixels to a 20-pixel default without changing the 28-pixel pickup radius. Their value affects visual scale and halo intensity, so merged gems are visibly more valuable while the population cap remains unchanged.

The top HUD gains a prominent full-width experience header inside `SafeArea`:

- a high-contrast `레벨 N` badge;
- a 14–18 pixel blue-to-cyan progress track with numeric current/required XP;
- time, kills, health, and weapon slots compressed below it;
- keys and semantic labels preserved or expanded for tests and accessibility.

The run still starts at level 1. Crossing an XP threshold increments the displayed player level. If one collection crosses multiple thresholds, the game queues one weapon/augment choice for each level gained rather than dropping extra choices.

## Background readability

Decorative stage strokes are reduced in contrast and changed away from attack colors so they cannot be mistaken for projectiles or targeting lanes. Player effects render above the backdrop; enemy warnings render above low-alpha player footprints and below bright attack cores where the existing priority model permits.

## Asset policy

The new bandit is original Joseon folk-fantasy artwork. It must not copy a commercial character, UI, or effect. The project records its prompt, source path, runtime path, dimensions, frame contract, and review status in the existing asset documentation and rights ledger.

## Verification

Automated coverage must prove:

- every stage-spawnable enemy ID has a runtime sprite specification;
- the bandit uses a 128-pixel frame contract and filtered downsampling;
- the authored fallback contains no full-body rectangle;
- frost normal and master presentations expose distinct visual tiers while retaining the same hit radius;
- every weapon family resolves to a non-primitive presentation route;
- experience gems default to at least 20 pixels and visually scale with stored value without changing pickup radius;
- the HUD displays `레벨 1`, a prominent XP bar, correct progress, and responsive safe-area bounds;
- multiple level gains queue the matching number of choices;
- updated 390-by-844 combat goldens contain bandit, frost, ranged, hazard, and late-density examples;
- `flutter analyze`, the complete test suite, web release build, and Android debug build succeed.

Physical play remains required to judge whether the spectacle feels satisfying, important enemy attacks remain readable, and late combat remains smooth.

## Out of scope

- Dedicated final atlases for all thirteen enemies.
- A complete replacement atlas for every effect before the new visual language is playtested.
- Balance changes to damage, enemy health, pickup distance, weapon unlock rules, or saved IDs.
- New monetization or meta-progression systems.
