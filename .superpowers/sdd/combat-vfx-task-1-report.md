# Combat VFX Task 1 Report — Enemy Art Routing and Bandit Atlas

## Delivered

- Added the original `assets/images/monsters/bandit_128.png` production atlas:
  4-by-4 cells, 128px per cell, transparent RGBA 512px runtime PNG.
- Routed every current enemy family through authored reviewed 128px art:
  bandits use the new bandit atlas; plague enemies use the rat-swarm atlas;
  spirits use the vengeful-spirit atlas; anomalies use the dokkaebi atlas.
  Boss-family fallback routes are explicit as well.
- Made `EnemySpriteSheet.specs` total for the complete `enemyDefinitions`
  roster, including all stage wave/elite IDs; all routed sprites use filtered
  128px downsampling.
- Retired low-resolution atlas contracts that are no longer runtime routes and
  registered the new bandit as a temporary representative 128px atlas.
- Replaced the generic rectangular no-asset fallback with outlined, path-drawn
  circular head and body folk-spirit shapes.
- Recorded prompt, processing, hashes, provenance, review state, and the
  Task 10 approval hold in the rights ledger.

## Changed files

- `assets/images/monsters/bandit_128.png`
- `source_assets/representative_set/enemy_atlases/bandit_atlas_source.png`
- `docs/assets/prompts/bandit-balanced-casual-atlas.md`
- `docs/assets/asset-rights-ledger.csv`
- `lib/game/components/enemy_component.dart`
- `lib/game/content/actor_visual_spec.dart`
- `lib/game/content/asset_catalog.dart`
- `lib/game/content/sprite_atlas_contract.dart`
- `test/game/enemy_component_test.dart`
- `test/game/content_integrity_test.dart`
- `test/game/sprite_atlas_contract_test.dart`

## TDD evidence

### RED

Command:

```text
flutter test test/game/enemy_component_test.dart test/game/content_integrity_test.dart
```

Result: expected failure. `EnemySpriteSheet.specs` contained only six routes;
the total roster assertion exposed the seven missing definition IDs
(`plague_crow`, `spear_bandit`, `rotten_herbalist`, `grave_ember`,
`black_hat_assassin`, `broken_jangseung_spirit`, and
`sorrowful_maiden_ghost`). The old bandit remained 32px, and the new atlas did
not yet exist. The command reported three failing tests (two mapping assertions
and the absent PNG contract).

### GREEN

Required focused command:

```text
flutter test test/game/enemy_component_test.dart test/game/content_integrity_test.dart
```

Result: PASS, 39 tests.

Additional focused checks:

```text
flutter test test/game/actor_visual_spec_test.dart
```

Result: PASS, 3 tests.

```text
flutter test test/game/sprite_atlas_contract_test.dart
```

Result: PASS, 6 tests.

```text
flutter test test/game/asset_rights_policy_test.dart
```

Result: PASS, 4 tests.

```text
flutter analyze
```

Result: PASS, no issues.

## Asset generation

- Method: OpenAI built-in image generation, not CLI fallback.
- Inputs: the existing `exorcist_dosa_128.png` and `dokkaebi_128.png` were
  included only as original-project style/layout references; no commercial
  source or copied design was used.
- Exact final prompt: `docs/assets/prompts/bandit-balanced-casual-atlas.md`.
- Chroma source:
  `source_assets/representative_set/enemy_atlases/bandit_atlas_source.png`.
- Transparency processing: the installed `remove_chroma_key.py` helper with
  `--auto-key border --soft-matte --transparent-threshold 12
  --opaque-threshold 220 --despill`; sampled key `#04f807`.
- Source output: 1,086,012 fully transparent and 25,802 partially transparent
  pixels before atlas normalization.
- Normalization: each of the 1254px-square source cells was independently
  cropped, proportionally resized to 126px, and composited one pixel inset in
  each 128px runtime cell to preserve fully transparent gutters.

## Asset validation

- Runtime atlas: RGBA, exactly 512 by 512 pixels.
- All four corners are alpha zero.
- Rows/columns `0/127/128/255/256/383/384/511` are fully transparent.
- All sixteen cells contain alpha-positive artwork; occupied-alpha counts are
  `[5659, 5571, 5365, 5412, 5950, 5948, 7117, 5919, 6236, 5765, 5696,
  5589, 5869, 5323, 5022, 2631]`.
- Original-resolution review confirmed the same readable Joseon-bandit
  silhouette, red headband, consistent knife hand, and the required 4-4-2-6
  movement/attack/hit/death chronology.
- SHA-256 source:
  `CBEC869AC1275FE03D3C687BB00720F4ABE2C9C58A67C4B7F36965509363BA90`.
- SHA-256 runtime:
  `65135EA9120C054426E818ED2B3BBEB8EFA1C629287D601742B846CD19030ECE`.

## Self-review

- Stage-wave enemy IDs and the full authored definition roster have explicit
  routes; boss-family IDs are also explicitly covered.
- New bandit-family routes point only to `monsters/bandit_128.png` and use
  `FilterQuality.medium`.
- Visual hitboxes, health, movement, damage, enemy IDs, and animation frame
  indices were not changed.
- The fallback has no `canvas.drawRect` path remaining.
- The temporary rights status correctly reserves release approval for Task 10.

## Concern

Flutter's external `impellerc` shader compiler intermittently crashed while
assembling a larger multi-file test bundle, before any Dart test executed. The
required two-file focused command, each supplemental focused suite, and
`flutter analyze` all completed successfully afterward. This is an environment
tooling instability, not a task-source failure; it should be monitored if a
single large test invocation is required later.
