# Static Exorcist Player Art Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Temporarily replace the current player visual with the approved female exorcist swordswoman as one static transparent image while preserving gameplay behavior and all original art.

**Architecture:** Keep `PlayerComponent` as a `SpriteAnimationGroupComponent` so movement, hit, and death state transitions remain untouched. Replace the 4x4 atlas definitions with four single-frame animations that all read the same 64x64 RGBA image; Flame continues rendering the component at its existing 24x24 world size, so collision radii and movement bounds remain unchanged.

**Tech Stack:** Flutter 3.44.4, Dart 3.12.2, Flame 1.18.x, Flutter test, OpenAI built-in image generation, local chroma-key removal.

## Global Constraints

- Preserve the approved concept sheet and the existing `rookie_constable` source/runtime images.
- Create a separate transparent-background PNG for runtime use.
- Replace only temporary player-art references.
- Do not change collision, movement speed, attack behavior, or the default `PlayerComponent` size of `Vector2.all(24)`.
- Do not create walking, attack, hit, or death artwork; all visual states use the same static frame.
- Register the runtime asset in `pubspec.yaml`.
- Run `flutter analyze` and the complete Flutter test suite.

---

### Task 1: Lock the static-player contract with failing tests

**Files:**
- Modify: `test/game/player_component_test.dart`
- Modify: `test/game/art_style_guide_test.dart`
- Modify: `test/game/sprite_atlas_contract_test.dart`
- Modify: `test/app/credits_licenses_screen_test.dart`

**Interfaces:**
- Consumes: existing `PlayerSpriteSheet`, `ReplaceableArtCatalog`, and packaged rights ledger.
- Produces: executable expectations for the new asset key, 64x64 RGBA geometry, one-frame visual mapping, catalog registration, and ledger path.

- [ ] **Step 1: Replace the animation-atlas expectation in `player_component_test.dart`**

```dart
test('static player art uses one 64px frame for every visual state', () {
  expect(
    PlayerSpriteSheet.assetKey,
    'player/exorcist_swordswoman_static_64.png',
  );
  expect(PlayerSpriteSheet.frameSize, Vector2.all(64));
  expect(PlayerSpriteSheet.frameCount, 1);
});
```

- [ ] **Step 2: Update PNG and catalog expectations**

Expect `assets/images/player/exorcist_swordswoman_static_64.png` to exist, be 64x64, use PNG color type 6 (RGBA), and be represented by a 1x1 `SpriteAtlasContract` named `exorcist_swordswoman_player`.

- [ ] **Step 3: Update the packaged-ledger expectation**

Expect the first asset entry to reference `assets/images/player/exorcist_swordswoman_static_64.png`.

- [ ] **Step 4: Run focused tests and verify RED**

Run:

```powershell
flutter test test/game/player_component_test.dart test/game/art_style_guide_test.dart test/game/sprite_atlas_contract_test.dart test/app/credits_licenses_screen_test.dart
```

Expected: FAIL because the new asset key, frame count, contract ID, PNG, and ledger row do not exist yet.

### Task 2: Generate and validate the static transparent player art

**Files:**
- Create: `source_assets/player/exorcist_swordswoman_character_sheet.png`
- Create: `source_assets/player/exorcist_swordswoman_static_source.png`
- Create: `source_assets/player/exorcist_swordswoman_static_alpha.png`
- Create: `assets/images/player/exorcist_swordswoman_static_64.png`
- Create: `docs/assets/prompts/exorcist-swordswoman-static-player.md`

**Interfaces:**
- Consumes: the approved character setting sheet from the conversation.
- Produces: a centered, front-facing, full-body 64x64 RGBA runtime sprite with transparent corners and a preserved high-resolution source.

- [ ] **Step 1: Preserve the approved concept sheet**

Copy the generated setting sheet into `source_assets/player/exorcist_swordswoman_character_sheet.png` without modifying the generated original.

- [ ] **Step 2: Generate a chroma-key source**

Use the approved sheet as an identity reference. Generate exactly one front-facing character in the approved navy cheollik, red sash, white beoseon, red under-left-eye talisman, and red-flame Saingeom on a perfectly flat `#00ff00` background.

- [ ] **Step 3: Remove the chroma key**

Run the installed imagegen helper with border auto-keying, soft matte, and despill to create `source_assets/player/exorcist_swordswoman_static_alpha.png`.

- [ ] **Step 4: Normalize for mobile rendering**

Trim transparent padding proportionally, fit the complete silhouette into a 64x64 canvas with centered horizontal alignment and bottom alignment, and save as RGBA PNG at `assets/images/player/exorcist_swordswoman_static_64.png`.

- [ ] **Step 5: Validate the image**

Verify 64x64 dimensions, RGBA color type 6, transparent corners, non-empty foreground coverage, and visually inspect the result for identity, silhouette, and chroma fringe.

### Task 3: Switch only the player visual to the static asset

**Files:**
- Modify: `lib/game/components/player_component.dart`
- Modify: `lib/game/content/asset_catalog.dart`
- Modify: `lib/game/content/sprite_atlas_contract.dart`
- Modify: `pubspec.yaml`
- Modify: `docs/assets/asset-rights-ledger.csv`

**Interfaces:**
- Consumes: `assets/images/player/exorcist_swordswoman_static_64.png`.
- Produces: the same `PlayerAnimationState` API backed by a single repeated static frame.

- [ ] **Step 1: Implement the minimal one-frame visual mapping**

Set `PlayerSpriteSheet.assetKey` to `player/exorcist_swordswoman_static_64.png`, `frameSize` to `Vector2.all(64)`, and `frameCount` to `1`. Build one-frame `SpriteAnimation.fromFrameData` values for idle, walking, hit, and death without changing state-transition code.

- [ ] **Step 2: Update catalog and contract references**

Point temporary character/player catalog entries to the new runtime PNG. Replace the player 4x4 contract with a 1x1, 64px `exorcist_swordswoman_player` contract while leaving all enemy/effect contracts unchanged.

- [ ] **Step 3: Register the asset explicitly**

Replace the player-directory entry in `pubspec.yaml` with explicit entries for both the preserved old runtime image and the new static image.

- [ ] **Step 4: Record provenance**

Add the new runtime image as the first row in `docs/assets/asset-rights-ledger.csv`, referencing the prompt record and source hash. Keep the old row intact.

- [ ] **Step 5: Run focused tests and verify GREEN**

Run the same focused test command from Task 1. Expected: all focused tests PASS.

### Task 4: Full verification and scope audit

**Files:**
- Verify only; no additional production files unless a directly related failure requires correction.

**Interfaces:**
- Consumes: completed static player-art integration.
- Produces: analyzer/test evidence and a bounded diff.

- [ ] **Step 1: Format Dart files**

```powershell
dart format lib/game/components/player_component.dart lib/game/content/asset_catalog.dart lib/game/content/sprite_atlas_contract.dart test/game/player_component_test.dart test/game/art_style_guide_test.dart test/game/sprite_atlas_contract_test.dart test/app/credits_licenses_screen_test.dart
```

- [ ] **Step 2: Run static analysis**

```powershell
flutter analyze
```

Expected: exit code 0 with no issues.

- [ ] **Step 3: Run the complete test suite**

```powershell
flutter test
```

Expected: exit code 0 with all tests passing.

- [ ] **Step 4: Audit the diff**

Confirm the original `rookie_constable` files still exist, the new PNG is RGBA 64x64, `PlayerComponent` still defaults to 24x24, and no movement, collision, attack, or animation artwork was changed.
