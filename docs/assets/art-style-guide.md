# Joseon Combat Slice Art Contract

## Approved visual direction

The combat slice uses clean, readable illustrated characters rather than a
pixel-only style. Human characters use compact **3-4-head proportions**, a
**bold clean outline**, and **2-3-shade cel rendering**. Forms must remain
legible at gameplay scale without depending on fine texture.

Joseon clothing and equipment are the design vocabulary: gat, jeonbok,
durumagi, military coats and headcloths, mudang ritual sleeves and ribbons,
straw rain capes, hwando, matchlocks, talismans, bells, bows, clubs, and
village guardian carvings. Do not use Japanese samurai armor, Chinese wuxia
robes, or copied commercial-game assets.

## Character vocabulary

- `hwandoSwordsman`: layered durumagi and jeonbok, a gat silhouette, and a
  hwando worn at the hip.
- `mudang`: striped ceremonial sleeves, ritual ribbons, bells, and paper
  talismans.
- `musketeer`: Joseon military coat and headcloth with a long matchlock.
- `dokkaebiHunter`: straw rain cape, rope charms, horn trophies, and a
  practical club.

## Ten monster silhouettes

Each family needs a distinct outer contour before color and interior detail:

1. `littleDokkaebi`: small horns, broad grin, oversized club.
2. `jarGhost`: round earthenware jar and leaking spirit plume.
3. `jangseungGhost`: tall carved pole face and splintered arms.
4. `sakkatSpecter`: wide conical hat above a narrow floating robe.
5. `fireDokkaebi`: forked flame crown, compact torso, ember fists.
6. `eggGhost`: smooth egg body, tiny feet, cracked face.
7. `underworldMinion`: ledger tag, hooked staff, hunched official robe.
8. `tigerDemon`: low feline shoulders, striped tail, exaggerated claws.
9. `plagueGhost`: swollen sleeves, bent posture, trailing sickly vapor.
10. `fallenOfficer`: broken Joseon command hat, lamellar coat, long blade.

## Temporary gameplay render sizes

These are current on-screen visual sizes, not source-canvas or pixel-art frame
requirements:

- Player: **108**
- Normal enemy: **54**
- Elite enemy: **81**
- Boss: **126**

## Production rule

Do not bulk-produce final art during the combat slice. Create only the minimum
temporary or representative assets needed to validate silhouette, combat
readability, proportions, and Joseon vocabulary. A reviewed representative
asset must establish the direction before any later production batch.

The machine-testable mirror of this contract is `JoseonArtStyle`. Existing
palette and legacy asset-validation constants remain in place for assets that
the current build still consumes; they do not redefine the new art direction.
