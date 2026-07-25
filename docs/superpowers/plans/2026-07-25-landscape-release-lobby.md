# Landscape Release Lobby Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a release-quality landscape Joseon folk-fantasy lobby with a full-scene composition, real PNG UI assets, clear deployment hierarchy, and contextual notices for unavailable features.

**Architecture:** Keep `LobbyScreen` responsible for state and navigation while moving presentation into focused scene, status, side-menu, deployment, quick-action, primary-navigation, and feature-notice widgets. Use Flutter text over modular raster frames so the interface remains responsive and localizable; keep every destination behind callbacks so existing controllers and routes remain unchanged.

**Tech Stack:** Flutter 3.x, Dart 3.12, Material rendering primitives without stock Material surfaces, PNG raster assets, Flutter widget tests and golden tests, built-in image generation with local chroma-key removal when transparency is needed.

## Global Constraints

- The primary play orientation is landscape; verify 16:9, 19.5:9, and 20:9 landscape layouts.
- Do not use stock Material `Card`, `ListTile`, `AppBar`, or `ActionChip` as final lobby surfaces.
- Do not ship circles, rectangles, or flat-color shapes as final characters, menu icons, frames, or effects.
- Do not bake Korean labels, values, or menu names into raster assets.
- Every generated project asset must have a runtime file, a source file, and an entry in `docs/assets/asset-rights-ledger.csv`.
- Preserve existing `LobbyController`, save data, purchase state, stage selection, character selection, and combat launch behavior.
- Preserve minimum 48×48 logical-pixel tap targets and Korean semantic labels.
- Missing feature routes open the approved in-world notice copy; they must not fail silently.
- Keep the user-owned untracked `.codex/` directory outside every commit.
- Use `D:\FlutterSDK\bin\flutter.bat` and `$env:PUB_CACHE='D:\FlutterPubCache'` for Flutter commands.
- Run related tests during tasks; run `flutter analyze`, the full test suite, web build, and Android debug build only at the final verification task.

---

## File Map

### New presentation files

- `lib/app/lobby_feature_notice.dart`: unavailable-feature identifiers, approved copy, and the custom notice overlay.
- `lib/app/lobby_status_bar.dart`: profile, training rank, resources, premium entry, and settings.
- `lib/app/lobby_side_menu.dart`: compact left and right command rails.
- `lib/app/lobby_scene.dart`: backdrop, selected-character artwork, shadow, and scene grading.
- `lib/app/lobby_quick_actions.dart`: growth, weapon, relic, companion, and crafting actions.
- `lib/app/lobby_primary_navigation.dart`: lobby, character, combat, challenge, and shop navigation.
- `lib/app/lobby_asset_frame.dart`: reusable raster-backed pressable frame with pressed-depth feedback and semantics.
- `test/app/lobby_feature_notice_test.dart`: notice copy, dismissal, and semantics.
- `test/app/lobby_release_layout_test.dart`: landscape responsiveness, navigation callbacks, and stock-Material exclusions.
- `test/game/lobby_visual_asset_contract_test.dart`: asset presence, PNG dimensions, catalog ownership, and rights rows.

### Modified files

- `lib/app/lobby_screen.dart`: compose the new presentation and retain route ownership.
- `lib/app/lobby_battle_stage.dart`: reduce to stage/deployment information without a duplicate background card.
- `lib/app/lobby_top_command_bar.dart`: remove after callers and tests move to `LobbyStatusBar`.
- `lib/app/lobby_navigation_dock.dart`: remove after callers and tests move to the two new navigation widgets.
- `lib/app/premium_wallet_badge.dart`: expose display data to the new status bar without returning `ActionChip`.
- `lib/game/content/asset_catalog.dart`: add explicit lobby scene, frame, icon, and character presentation paths.
- `docs/assets/asset-rights-ledger.csv`: record generated source and runtime files.
- `pubspec.yaml`: continue using the existing directory asset declarations; no dependency change.
- `test/app/lobby_screen_test.dart`: update stable keys and preserve route and state regressions.
- `test/app/joseon_lobby_mobile_golden_test.dart`: replace portrait-first lobby cases with landscape lobby cases.
- `test/app/release_surface_golden_test.dart`: register the approved landscape lobby golden.

### New asset directories

- `art_source/generated/lobby/`: untrimmed generated originals and prompt manifests.
- `assets/images/ui/lobby/`: runtime frames and menu icons.
- `assets/images/characters/lobby/`: runtime character presentation cutouts.
- `art_source/review/lobby/`: reference-size runtime captures used for visual approval.

### Exact runtime asset paths

- Scene: `assets/images/stages/joseon_night_palace_landscape.png`
- Shadow: `assets/images/ui/lobby/character_shadow.png`
- Characters: `assets/images/characters/lobby/rookie_constable.png`,
  `assets/images/characters/lobby/exorcist_dosa.png`,
  `assets/images/characters/lobby/mountain_hunter.png`
- Frames: `assets/images/ui/lobby/frame_profile.png`,
  `assets/images/ui/lobby/frame_resource.png`,
  `assets/images/ui/lobby/frame_side_command.png`,
  `assets/images/ui/lobby/frame_stage_plaque.png`,
  `assets/images/ui/lobby/frame_deploy.png`,
  `assets/images/ui/lobby/frame_quick_action.png`,
  `assets/images/ui/lobby/frame_primary_navigation.png`,
  `assets/images/ui/lobby/frame_feature_notice.png`
- Icons: `assets/images/ui/lobby/icon_coin.png`,
  `assets/images/ui/lobby/icon_spirit_jade.png`,
  `assets/images/ui/lobby/icon_settings.png`,
  `assets/images/ui/lobby/icon_shop.png`,
  `assets/images/ui/lobby/icon_mission.png`,
  `assets/images/ui/lobby/icon_pass.png`,
  `assets/images/ui/lobby/icon_package.png`,
  `assets/images/ui/lobby/icon_mail.png`,
  `assets/images/ui/lobby/icon_compendium.png`,
  `assets/images/ui/lobby/icon_records.png`,
  `assets/images/ui/lobby/icon_character.png`,
  `assets/images/ui/lobby/icon_combat.png`,
  `assets/images/ui/lobby/icon_challenge.png`,
  `assets/images/ui/lobby/icon_growth.png`,
  `assets/images/ui/lobby/icon_weapon.png`,
  `assets/images/ui/lobby/icon_relic.png`,
  `assets/images/ui/lobby/icon_companion.png`,
  `assets/images/ui/lobby/icon_crafting.png`

Every generated source uses the same basename with `_source` before `.png` under
`art_source/generated/lobby/`.

---

### Task 1: Lock the Lobby Asset Contract

**Files:**
- Create: `test/game/lobby_visual_asset_contract_test.dart`
- Modify: `lib/game/content/asset_catalog.dart`
- Modify: `docs/assets/asset-rights-ledger.csv`

**Interfaces:**
- Produces: `AssetCatalog.lobbyScene`, `AssetCatalog.lobbyFrames`, `AssetCatalog.lobbyIcons`, and `AssetCatalog.lobbyCharacters`, each typed `Map<String, String>`.
- Produces: runtime paths consumed by every later lobby widget.

- [ ] **Step 1: Write the failing catalog contract**

```dart
test('release lobby catalog owns every required raster asset', () {
  expect(AssetCatalog.lobbyScene.keys, {
    'night_palace_landscape',
    'character_shadow',
  });
  expect(AssetCatalog.lobbyCharacters.keys, {
    'rookie_constable',
    'exorcist_dosa',
    'mountain_hunter',
  });
  expect(AssetCatalog.lobbyFrames.keys, containsAll({
    'profile',
    'resource',
    'side_command',
    'stage_plaque',
    'deploy',
    'quick_action',
    'primary_navigation',
    'feature_notice',
  }));
  expect(AssetCatalog.lobbyIcons.keys, containsAll({
    'coin',
    'spirit_jade',
    'settings',
    'shop',
    'mission',
    'pass',
    'package',
    'mail',
    'compendium',
    'records',
    'character',
    'combat',
    'challenge',
    'growth',
    'weapon',
    'relic',
    'companion',
    'crafting',
  }));
});
```

- [ ] **Step 2: Run the contract and verify it fails**

Run:

```powershell
$env:PUB_CACHE='D:\FlutterPubCache'
& 'D:\FlutterSDK\bin\flutter.bat' test test/game/lobby_visual_asset_contract_test.dart
```

Expected: FAIL because the four lobby-specific catalog maps do not exist.

- [ ] **Step 3: Add exact catalog paths**

Add the four maps to `AssetCatalog`, use descriptive paths under the new runtime directories, and include their values in `allPaths`. Do not point a character presentation key at a 32px combat sprite.

- [ ] **Step 4: Add file and rights assertions**

Extend the test to assert that each path exists, starts with `assets/images/`, is a PNG, has nonzero width and height, and has one exact `runtime_path` match in `docs/assets/asset-rights-ledger.csv`.

- [ ] **Step 5: Re-run and retain the expected asset-missing failure**

Expected: FAIL listing the first missing runtime PNG. This failure is the gate for Task 2.

- [ ] **Step 6: Commit the contract**

```powershell
git add lib/game/content/asset_catalog.dart test/game/lobby_visual_asset_contract_test.dart
git commit -m "test: define release lobby asset contract"
```

---

### Task 2: Produce and Validate the Release Lobby Raster Set

**Files:**
- Create: `art_source/generated/lobby/*.png`
- Create: `art_source/generated/lobby/prompts.md`
- Create: `assets/images/ui/lobby/*.png`
- Create: `assets/images/characters/lobby/*.png`
- Modify: `docs/assets/asset-rights-ledger.csv`

**Interfaces:**
- Consumes: runtime paths from `AssetCatalog`.
- Produces: validated PNGs that satisfy `lobby_visual_asset_contract_test.dart`.

- [ ] **Step 1: Write the generation manifest**

Record one prompt per asset in `art_source/generated/lobby/prompts.md`. Use these shared constraints in every prompt:

```text
Use case: stylized-concept
Asset type: release mobile game lobby asset
Style: polished Joseon folk-fantasy mobile game illustration, clean chibi proportions,
strong readable silhouette, restrained detail, warm lantern key light from upper left,
dark navy shadows, aged brass and ivory outlines
Constraints: no text, no letters, no watermark, no logo, no stock UI symbols,
no flat geometric placeholder, consistent lighting and outline thickness
```

- [ ] **Step 2: Generate the landscape background**

Use the existing lobby background and both user references as visual direction, not edit targets. Generate a 16:9 night palace courtyard with clear center floor space for a character, readable roofline, moon and lantern depth, subdued edges for UI, and no embedded character or text. Save the source as `art_source/generated/lobby/night_palace_landscape_source.png` and the reviewed runtime image as `assets/images/stages/joseon_night_palace_landscape.png`.

- [ ] **Step 3: Generate three character presentations**

Issue a separate built-in image-generation call for each character. Use a flat chroma-key background, full-body framing, identical camera height, identical left-side key light, and generous padding. Keep each character's established costume and weapon silhouette. Save untrimmed sources under `art_source/generated/lobby/` and alpha-cleaned 1024px-tall runtime PNGs under `assets/images/characters/lobby/`.

- [ ] **Step 4: Validate alpha cleanup**

For each character runtime file, verify RGBA mode, transparent corner pixels, no green or magenta fringe, and nontransparent subject coverage between 20% and 75% of the canvas. If hair or weapon edges fail after one chroma-key retry, stop before a model-path downgrade and request permission for the true-transparency fallback.

- [ ] **Step 5: Generate eight frame families**

Generate frames individually without text: profile plaque, resource slot, side command, stage plaque, deploy button, quick action, primary navigation, and feature notice. Keep stretchable centers visually quiet. Preserve the source image and export each runtime PNG with transparent outer corners.

- [ ] **Step 6: Generate eighteen menu icons**

Generate one icon per call with the same square camera, brass outline, dark navy backing shadow, and transparent outer canvas. The subject must be a single readable object matching the catalog key. Reject any icon containing pseudo-text or more than one competing focal object.

- [ ] **Step 7: Create the character shadow**

Create `assets/images/ui/lobby/character_shadow.png` as a soft painted oval shadow with alpha, not a Flutter-drawn ellipse. Keep it neutral enough for all three character cutouts.

- [ ] **Step 8: Record provenance**

Add one row per runtime asset to `docs/assets/asset-rights-ledger.csv` with generated-original ownership, source path, source SHA-256, runtime path, runtime SHA-256, creation date, and the prompt manifest path.

- [ ] **Step 9: Run the asset contract**

Run:

```powershell
$env:PUB_CACHE='D:\FlutterPubCache'
& 'D:\FlutterSDK\bin\flutter.bat' test test/game/lobby_visual_asset_contract_test.dart
```

Expected: PASS.

- [ ] **Step 10: Commit approved assets**

```powershell
git add art_source/generated/lobby assets/images/ui/lobby assets/images/characters/lobby assets/images/stages/joseon_night_palace_landscape.png docs/assets/asset-rights-ledger.csv
git commit -m "art: add release lobby raster system"
```

---

### Task 3: Add Contextual Unavailable-Feature Notices

**Files:**
- Create: `lib/app/lobby_feature_notice.dart`
- Create: `test/app/lobby_feature_notice_test.dart`

**Interfaces:**
- Produces: `enum LobbyFeature { mail, mission, pass, package, ranking, relic, companion, crafting, challenge }`.
- Produces: `LobbyFeatureNoticeCopy copyForLobbyFeature(LobbyFeature feature)`.
- Produces: `Future<void> showLobbyFeatureNotice(BuildContext context, LobbyFeature feature)`.

- [ ] **Step 1: Write copy and interaction tests**

```dart
testWidgets('crafting opens the approved forge notice and dismisses', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: _NoticeHarness()));
  await tester.tap(find.byKey(const Key('open-crafting-notice')));
  await tester.pumpAndSettle();
  expect(find.text('대장간'), findsOneWidget);
  expect(find.text('대장간의 화로를 달구고 있습니다.'), findsOneWidget);
  expect(find.byKey(const Key('lobby-feature-notice')), findsOneWidget);
  await tester.tap(find.byKey(const Key('lobby-feature-notice-confirm')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('lobby-feature-notice')), findsNothing);
});
```

Add a table-driven unit test for all nine exact title/body pairs from the approved design.

- [ ] **Step 2: Run tests and verify failure**

Expected: FAIL because the enum, copy resolver, and notice widget do not exist.

- [ ] **Step 3: Implement the notice**

Use `showGeneralDialog<void>` with a dimmed barrier and a custom `Stack`/`Image.asset` panel. Render title, body, and confirm label as Flutter text. Provide Korean semantics, barrier dismissal, and a 140–180ms fade/scale transition. Do not use `AlertDialog`, `Card`, or `SnackBar`.

- [ ] **Step 4: Run tests**

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add lib/app/lobby_feature_notice.dart test/app/lobby_feature_notice_test.dart
git commit -m "feat: add contextual lobby feature notices"
```

---

### Task 4: Build the Raster-Backed Controls and Status Bar

**Files:**
- Create: `lib/app/lobby_asset_frame.dart`
- Create: `lib/app/lobby_status_bar.dart`
- Modify: `lib/app/premium_wallet_badge.dart`
- Modify: `test/app/lobby_release_layout_test.dart`

**Interfaces:**
- Produces: `LobbyAssetButton({required String debugId, required String semanticLabel, required String frameAsset, required VoidCallback onPressed, required Widget child, Size minimumSize = const Size(48, 48)})`.
- Produces: `LobbyStatusBar({required int coin, required int spiritJade, required String trainingRank, required Widget premiumEntry, required VoidCallback onSettings})`.

- [ ] **Step 1: Write status and target-size tests**

Assert that `LobbyStatusBar` renders coin and spirit-jade values, uses the raster keys `lobby-profile-frame` and `lobby-resource-frame`, exposes the `설정` semantic label, and keeps every interactive target at least 48×48.

- [ ] **Step 2: Verify failure**

Expected: FAIL because both widgets do not exist.

- [ ] **Step 3: Implement pressed-depth raster controls**

`LobbyAssetButton` must use `GestureDetector`, a raster frame, and an `AnimatedTransform` or `AnimatedSlide` of 2–4 logical pixels. It must provide disabled-safe semantics and must not construct a `Material` button.

- [ ] **Step 4: Implement the status bar**

Compose profile, rank, resources, premium entry, and settings in one bounded `Row`. Use `FittedBox` only inside value slots, not around the entire bar. Replace any premium `ActionChip` presentation with a plain status widget and callback ownership in `LobbyScreen`.

- [ ] **Step 5: Run related tests**

Run the new release-layout tests plus existing premium wallet tests.

- [ ] **Step 6: Commit**

```powershell
git add lib/app/lobby_asset_frame.dart lib/app/lobby_status_bar.dart lib/app/premium_wallet_badge.dart test/app/lobby_release_layout_test.dart
git commit -m "feat: add release lobby status controls"
```

---

### Task 5: Build the Full-Scene Character and Deployment Hierarchy

**Files:**
- Create: `lib/app/lobby_scene.dart`
- Modify: `lib/app/lobby_battle_stage.dart`
- Modify: `test/app/lobby_release_layout_test.dart`

**Interfaces:**
- Produces: `LobbyScene({required String characterId, required Widget foreground})`.
- Produces: revised `LobbyBattleStage` with the existing constructor and callback behavior.

- [ ] **Step 1: Write scene-order tests**

Assert that the scene contains exactly one background image, one painted shadow, one character presentation, one stage plaque, and one deploy button. Assert that `lobby-character-art` appears after the background and before the foreground controls in the widget tree.

- [ ] **Step 2: Verify failure**

Expected: FAIL because `LobbyScene` does not exist and the current stage repeats the background.

- [ ] **Step 3: Implement the scene**

Use one full-screen `Stack` with `AssetCatalog.lobbyScene['night_palace_landscape']`, a restrained edge gradient, the raster shadow, and the selected character cutout. Use `LayoutBuilder` to size the character to 48–66% of available height while preserving its aspect ratio.

- [ ] **Step 4: Simplify deployment presentation**

Remove the duplicate framed background from `LobbyBattleStage`. Keep character name, stage name, best time, busy state, and `lobby-deploy` callback. Render these over the stage-plaque and deploy-frame assets.

- [ ] **Step 5: Run scene and existing deploy tests**

Expected: PASS, including persisted character and stage launch behavior.

- [ ] **Step 6: Commit**

```powershell
git add lib/app/lobby_scene.dart lib/app/lobby_battle_stage.dart test/app/lobby_release_layout_test.dart test/app/lobby_screen_test.dart
git commit -m "feat: build full-scene lobby deployment"
```

---

### Task 6: Add Side Menus, Quick Actions, and Primary Navigation

**Files:**
- Create: `lib/app/lobby_side_menu.dart`
- Create: `lib/app/lobby_quick_actions.dart`
- Create: `lib/app/lobby_primary_navigation.dart`
- Modify: `test/app/lobby_release_layout_test.dart`

**Interfaces:**
- Produces: `LobbyMenuAction` with `id`, `label`, `iconAsset`, and `onPressed`.
- Produces: `LobbySideMenu({required List<LobbyMenuAction> actions, required Axis axis})`.
- Produces: `LobbyQuickActions` and `LobbyPrimaryNavigation`, each receiving callbacks instead of a navigator.

- [ ] **Step 1: Write callback and label tests**

Create table-driven tests that tap every implemented and unavailable action, assert one callback invocation, and verify its Korean semantic label. Assert the central combat/deploy action is visually larger than neighboring navigation actions.

- [ ] **Step 2: Verify failure**

Expected: FAIL because the three widgets and `LobbyMenuAction` do not exist.

- [ ] **Step 3: Implement menu data and rails**

Use raster icon and frame paths from `AssetCatalog`. On wide layouts use vertical left/right rails; on constrained landscape layouts switch to compact horizontal rails. Preserve at least 48×48 targets.

- [ ] **Step 4: Implement quick and primary navigation**

Quick actions: 성장, 무기, 유물, 동료, 제작. Primary navigation: 로비, 인물, 전투, 도전, 상점. Keep text outside images and make the active 로비 tab distinct through frame state and label, not color alone.

- [ ] **Step 5: Run tests**

Expected: PASS.

- [ ] **Step 6: Commit**

```powershell
git add lib/app/lobby_side_menu.dart lib/app/lobby_quick_actions.dart lib/app/lobby_primary_navigation.dart test/app/lobby_release_layout_test.dart
git commit -m "feat: add illustrated lobby navigation"
```

---

### Task 7: Integrate the Landscape Lobby and Preserve Routes

**Files:**
- Modify: `lib/app/lobby_screen.dart`
- Modify: `test/app/lobby_screen_test.dart`
- Modify: `test/app/lobby_release_layout_test.dart`
- Delete: `lib/app/lobby_top_command_bar.dart`
- Delete: `lib/app/lobby_navigation_dock.dart`

**Interfaces:**
- Consumes: all presentation widgets from Tasks 3–6.
- Preserves: existing `_openPremiumShop`, `_openCharacterPicker`, `_openStagePicker`, `_openSettings`, `_openCompendium`, `_openTraining`, and `_deploy` route behavior.

- [ ] **Step 1: Add integration failures**

Add widget tests for:

```dart
for (final size in [
  const Size(640, 360),
  const Size(780, 360),
  const Size(800, 360),
]) {
  testWidgets('release lobby has no overflow at ${size.width}x${size.height}', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final lobby = LobbyController(
      store: _MemorySaveStore(SaveState.defaults()),
    );
    await lobby.load();
    await tester.pumpWidget(
      MaterialApp(
        home: LobbyScreen(
          controller: lobby,
          audioSettingsController: _audioController(),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const Key('lobby-deploy')), findsOneWidget);
    expect(find.byKey(const Key('lobby-character-art')), findsOneWidget);
    expect(find.byKey(const Key('lobby-status-bar')), findsOneWidget);
    expect(find.byKey(const Key('lobby-primary-navigation')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
```

Also assert that the `LobbyScreen` subtree contains no `Card`, `ListTile`, `AppBar`, or `ActionChip`.

- [ ] **Step 2: Verify failure**

Expected: FAIL because the current screen still composes the old command bar, stage card, and dock.

- [ ] **Step 3: Compose the new scene**

Keep `LobbyScreen` as the callback owner. Place `LobbyStatusBar` at the top, left and right `LobbySideMenu` rails around the `LobbyScene`, `LobbyBattleStage` at center bottom, `LobbyQuickActions` above `LobbyPrimaryNavigation`, and feature notices through `showLobbyFeatureNotice`.

- [ ] **Step 4: Map every destination**

Implemented actions call existing route methods. Unavailable actions call the exact approved feature enum. The shop action calls the existing purchase flow. The combat tab and deploy button both use the guarded `_deploy`.

- [ ] **Step 5: Remove obsolete lobby files and imports**

Delete old command-bar and navigation-dock files only after no production or test import remains. Preserve stable keys where external tests rely on them, or update tests in the same commit with an explicit replacement key.

- [ ] **Step 6: Run focused integration tests**

Run:

```powershell
$env:PUB_CACHE='D:\FlutterPubCache'
& 'D:\FlutterSDK\bin\flutter.bat' test test/app/lobby_screen_test.dart test/app/lobby_release_layout_test.dart test/app/lobby_feature_notice_test.dart
```

Expected: PASS.

- [ ] **Step 7: Commit**

```powershell
git add lib/app/lobby_screen.dart lib/app/lobby_top_command_bar.dart lib/app/lobby_navigation_dock.dart test/app/lobby_screen_test.dart test/app/lobby_release_layout_test.dart
git commit -m "feat: integrate landscape release lobby"
```

---

### Task 8: Review the Actual Runtime and Refine Assets

**Files:**
- Review and modify the failing asset only: `assets/images/ui/lobby/*.png`
- Review and modify the failing asset only: `assets/images/characters/lobby/*.png`
- Review and modify the failing asset only: `assets/images/stages/joseon_night_palace_landscape.png`
- Create: `art_source/review/lobby/lobby_16_9.png`
- Create: `art_source/review/lobby/lobby_19_5_9.png`
- Create: `art_source/review/lobby/lobby_feature_notice.png`
- Modify: `test/app/joseon_lobby_mobile_golden_test.dart`
- Modify: `test/app/release_surface_golden_test.dart`

**Interfaces:**
- Produces: the approved runtime visual baseline used by final verification.

- [ ] **Step 1: Start Chrome development mode**

Run with `MOBILE_PREVIEW=false` so the app uses the actual landscape viewport.

- [ ] **Step 2: Capture three runtime states**

Capture 16:9, 19.5:9, and a feature-notice state. Save exact PNGs under `art_source/review/lobby/`.

- [ ] **Step 3: Apply the visual acceptance rubric**

Reject and refine the relevant asset or layout if any answer is no:

- Does the character read before the background and menus?
- Is 출진 the strongest action?
- Are left and right rails visually balanced without covering the character?
- Do frame materials and icon lighting match?
- Are all values readable at native size?
- Does the notice look like part of the game rather than a development dialog?
- Are there any stock Material icons or flat placeholder surfaces?

- [ ] **Step 4: Perform one targeted refinement pass**

Change only the failing layer: regenerate the specific raster asset or adjust the responsible layout component. Do not regenerate unrelated approved assets.

- [ ] **Step 5: Update golden baselines**

Replace the landscape lobby golden only after the runtime rubric passes. Keep reference images and runtime captures separate from test golden files.

- [ ] **Step 6: Run golden tests**

Expected: PASS with the updated approved baselines.

- [ ] **Step 7: Commit**

```powershell
git add assets/images art_source/review/lobby docs/assets/asset-rights-ledger.csv test/app/goldens test/app/joseon_lobby_mobile_golden_test.dart test/app/release_surface_golden_test.dart
git commit -m "art: approve release lobby runtime"
```

---

### Task 9: Final Verification, Android Build, and Remote Publication

**Files:**
- Create: `docs/testing/release-lobby-report.md`
- Reopen the owning Task 1–8 file and add a focused regression test before any
  defect fix discovered by final verification.

**Interfaces:**
- Produces: one final report with checks, screenshots, APK path and hash, commit, and remote branch.

- [ ] **Step 1: Run static analysis**

```powershell
$env:PUB_CACHE='D:\FlutterPubCache'
& 'D:\FlutterSDK\bin\flutter.bat' analyze
```

Expected: no issues.

- [ ] **Step 2: Run the full test suite**

```powershell
$env:PUB_CACHE='D:\FlutterPubCache'
& 'D:\FlutterSDK\bin\flutter.bat' test
```

Expected: all tests pass.

- [ ] **Step 3: Build web**

```powershell
$env:PUB_CACHE='D:\FlutterPubCache'
& 'D:\FlutterSDK\bin\flutter.bat' build web --release
```

Expected: `build/web` is produced successfully.

- [ ] **Step 4: Build Android debug APK**

```powershell
$env:PUB_CACHE='D:\FlutterPubCache'
& 'D:\FlutterSDK\bin\flutter.bat' build apk --debug
```

Expected: `build/app/outputs/flutter-apk/app-debug.apk` exists.

- [ ] **Step 5: Write the verification report**

Record:

- all command results and test count
- runtime screenshot paths
- viewport sizes
- menu route and unavailable-notice coverage
- remaining non-lobby UI gaps, without describing the lobby as unfinished
- APK absolute path, byte size, and SHA-256
- final commit and branch

- [ ] **Step 6: Commit the report**

```powershell
git add docs/testing/release-lobby-report.md
git commit -m "docs: verify release lobby"
```

- [ ] **Step 7: Push master**

Verify `git status -sb` shows only the user-owned `.codex/` directory as untracked, then run:

```powershell
git push origin master
```

Expected: `origin/master` advances to the release-lobby verification commit.
