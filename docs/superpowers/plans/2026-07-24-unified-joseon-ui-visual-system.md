# Unified Joseon UI and Combat Visual System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Unify every existing lobby, selection, codex, records, training-entry, combat HUD, overlay, and stage-ground surface under one responsive Joseon folk-fantasy mobile design system without changing balance or save semantics.

**Architecture:** Presentation-only widgets consume the existing controllers and content definitions; they never duplicate progression or combat state. A shared scaffold and tokenized components establish layout and styling, presentation adapters derive integer stats and weapon mastery labels, and existing Flame chunk/batch renderers gain deterministic low-contrast tile variation plus sparse decals.

**Tech Stack:** Flutter, Dart, Flame, widget tests, golden tests, existing content/save systems, existing fixed-seed world streaming.

## Global Constraints

- Keep all existing character, weapon, stage, save, selection, navigation, and battle-balance semantics.
- Display base health, attack, and movement speed as rounded integers; use `%` only for values that are inherently ratios.
- Never display level 6 as six stars; display five blue/teal stars plus `통달`.
- Preserve the existing lobby background and current character, monster, weapon, stage-tile, and VFX assets.
- Do not finalize a missing illustration with a Material icon; show `ASSET MISSING` in debug builds and record the gap.
- Support 390×844, 375×667, and 430×932 without overflow or obscured fixed actions.
- Keep bottom navigation and confirm/deploy actions outside the scrollable body.
- Do not add new characters, weapons, stages, training economy, stat formulas, or balance changes.
- Run focused tests during implementation. Run full `flutter analyze`, full `flutter test`, and `flutter build web` once, only after all tasks.
- Do not run Android or iOS builds.
- Do not open a new external tunnel unless explicitly requested.

---

## File Structure

### Shared presentation

- Create `lib/app/joseon_scaffold.dart`: SafeArea-aware page shell with fixed top/bottom slots.
- Create `lib/app/joseon_panel.dart`: reusable navy/ivory panel surfaces.
- Create `lib/app/joseon_buttons.dart`: primary and secondary action buttons.
- Create `lib/app/joseon_resource_chip.dart`: resource amount and icon treatment.
- Create `lib/app/joseon_tab_bar.dart`: compact shared tabs.
- Create `lib/app/joseon_selection_card.dart`: selected/locked card shell.
- Create `lib/app/joseon_codex_card.dart`: unlocked/locked codex states.
- Create `lib/app/weapon_star_rating.dart`: level 1–6 visual contract.
- Create `lib/app/missing_asset_placeholder.dart`: debug-only missing-art signal.
- Create `lib/app/character_stat_presenter.dart`: integer UI stats derived from existing definitions.
- Modify `lib/app/joseon_ui_theme.dart`: shared color, radius, spacing, border, and text tokens.

### Non-combat screens

- Modify `lib/app/lobby_screen.dart`, `lobby_top_command_bar.dart`, `lobby_battle_stage.dart`, `lobby_navigation_dock.dart`.
- Modify `lib/app/character_select_screen.dart`, `stage_select_screen.dart`, `compendium_screen.dart`, `records_screen.dart`.
- Create `lib/app/training_screen.dart`: read-only existing training progress surface.
- Modify `lib/game/content/character_definitions.dart`, `weapon_definitions.dart`, and `stage_definitions.dart` only to repair display strings and add presentation metadata without changing IDs or balance.

### Combat presentation

- Modify `lib/game/content/stage_visual_spec.dart`: distinguish base variants, transitions, and decals.
- Modify `lib/game/components/stage_tile_batch_component.dart`: seam-safe deterministic variant sampling.
- Modify `lib/game/components/stage_backdrop_component.dart`: sparse deterministic decal placement.
- Modify `lib/app/game_hud.dart`, `level_up_overlay.dart`, `pause_menu_overlay.dart`, `run_summary_screen.dart`.

### Tests

- Add focused widget tests beside existing `test/app` coverage.
- Add deterministic tile and decal tests under `test/game`.
- Add three portrait golden baselines under `test/app/goldens`.

---

### Task 1: Repair Korean presentation strings

**Files:**
- Modify: `lib/game/content/character_definitions.dart`
- Modify: `lib/game/content/weapon_definitions.dart`
- Modify: `lib/game/content/stage_definitions.dart`
- Modify: `lib/app/character_select_screen.dart`
- Modify: `lib/app/stage_select_screen.dart`
- Test: `test/game/content_display_strings_test.dart`

**Interfaces:**
- Consumes: existing IDs and definition constructors.
- Produces: valid Korean `name`, `description`, `passiveName`, and `passiveDescription` strings for every later UI task.

- [ ] **Step 1: Write a failing encoding regression test**

```dart
test('player-facing content strings contain valid Korean and no mojibake', () {
  final values = <String>[
    ...characterDefinitions.expand(
      (item) => [item.name, item.passiveName, item.passiveDescription],
    ),
    ...weaponDefinitions.map((item) => item.name),
    ...stageDefinitions.expand((item) => [item.name, item.description]),
  ];
  for (final value in values) {
    expect(value, isNot(contains('�')));
    expect(value, isNot(matches(RegExp(r'[?][가-힣]'))));
    expect(value, matches(RegExp(r'[가-힣]')));
  }
});
```

- [ ] **Step 2: Run the test and confirm it fails**

Run: `D:\FlutterSdk\bin\flutter.bat test test/game/content_display_strings_test.dart`

Expected: FAIL on the current mojibake strings.

- [ ] **Step 3: Restore canonical Korean copy**

Use the existing design docs and IDs to restore names such as `신참 포졸`, `퇴마 의사`, `설산 사냥꾼`, `환도 베기`, `각궁 사격`, and `부적 투척`. Do not change IDs, numeric fields, unlock rules, or level definitions.

- [ ] **Step 4: Run the focused test**

Run: `D:\FlutterSdk\bin\flutter.bat test test/game/content_display_strings_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add lib/game/content/character_definitions.dart lib/game/content/weapon_definitions.dart lib/game/content/stage_definitions.dart lib/app/character_select_screen.dart lib/app/stage_select_screen.dart test/game/content_display_strings_test.dart
git commit -m "fix: restore korean presentation strings"
```

### Task 2: Add theme tokens and shared Joseon components

**Files:**
- Modify: `lib/app/joseon_ui_theme.dart`
- Create: `lib/app/joseon_panel.dart`
- Create: `lib/app/joseon_buttons.dart`
- Create: `lib/app/joseon_resource_chip.dart`
- Create: `lib/app/joseon_tab_bar.dart`
- Create: `lib/app/joseon_selection_card.dart`
- Create: `lib/app/joseon_codex_card.dart`
- Test: `test/app/joseon_components_test.dart`

**Interfaces:**
- Produces: `JoseonPanel`, `JoseonPrimaryButton`, `JoseonSecondaryButton`, `JoseonResourceChip`, `JoseonTabBar`, `JoseonSelectionCard`, and `JoseonCodexCard`.
- Produces theme constants for navy, ivory, gold, danger, unlocked, radii, panel border, and compact spacing.

- [ ] **Step 1: Write failing component-state tests**

```dart
testWidgets('selection card exposes selected and locked semantics', (tester) async {
  await tester.pumpWidget(
    testApp(
      const JoseonSelectionCard(
        selected: true,
        locked: false,
        semanticsLabel: '신참 포졸 선택됨',
        child: Text('신참 포졸'),
      ),
    ),
  );
  expect(find.bySemanticsLabel('신참 포졸 선택됨'), findsOneWidget);
  expect(find.byKey(const Key('selection-check')), findsOneWidget);
});
```

- [ ] **Step 2: Run the test and confirm missing classes**

Run: `D:\FlutterSdk\bin\flutter.bat test test/app/joseon_components_test.dart`

Expected: compile failure for missing shared components.

- [ ] **Step 3: Implement tokenized components**

Each component accepts content and callbacks rather than reading controllers. Selected and locked states must be both visual and semantic. Use a 1–2px ivory/gold border and restrained corner ornamentation.

- [ ] **Step 4: Run component and theme tests**

Run: `D:\FlutterSdk\bin\flutter.bat test test/app/joseon_components_test.dart test/app/joseon_ui_theme_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add lib/app/joseon_ui_theme.dart lib/app/joseon_panel.dart lib/app/joseon_buttons.dart lib/app/joseon_resource_chip.dart lib/app/joseon_tab_bar.dart lib/app/joseon_selection_card.dart lib/app/joseon_codex_card.dart test/app/joseon_components_test.dart test/app/joseon_ui_theme_test.dart
git commit -m "feat: add shared joseon ui components"
```

### Task 3: Add SafeArea-aware scaffold and fixed action layout

**Files:**
- Create: `lib/app/joseon_scaffold.dart`
- Test: `test/app/joseon_scaffold_test.dart`

**Interfaces:**
- Produces:

```dart
class JoseonScaffold extends StatelessWidget {
  const JoseonScaffold({
    required this.body,
    this.topBar,
    this.bottomBar,
    this.background,
    super.key,
  });
  final Widget body;
  final Widget? topBar;
  final Widget? bottomBar;
  final Widget? background;
}
```

- [ ] **Step 1: Write portrait inset and scrolling tests**

```dart
testWidgets('bottom action stays visible at 375x667 with view padding', (tester) async {
  tester.view.physicalSize = const Size(375, 667);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    mediaApp(
      viewPadding: const EdgeInsets.only(top: 24, bottom: 20),
      child: JoseonScaffold(
        body: ListView(children: List.generate(30, (i) => Text('$i'))),
        bottomBar: const Text('선택 완료', key: Key('fixed-action')),
      ),
    ),
  );
  expect(find.byKey(const Key('fixed-action')), findsOneWidget);
  expect(tester.takeException(), isNull);
});
```

- [ ] **Step 2: Run and confirm failure**

Run: `D:\FlutterSdk\bin\flutter.bat test test/app/joseon_scaffold_test.dart`

Expected: compile failure.

- [ ] **Step 3: Implement the scaffold**

Use `SafeArea(child: Column(children: [topBar, Expanded(child: body), bottomBar]))`. Do not wrap `bottomBar` in the body scroll view. Read insets from the ambient `MediaQuery`; do not inject device-specific heights.

- [ ] **Step 4: Run tests at all three portrait sizes**

Run: `D:\FlutterSdk\bin\flutter.bat test test/app/joseon_scaffold_test.dart`

Expected: PASS for 390×844, 375×667, and 430×932 cases.

- [ ] **Step 5: Commit**

```powershell
git add lib/app/joseon_scaffold.dart test/app/joseon_scaffold_test.dart
git commit -m "feat: add safe area joseon scaffold"
```

### Task 4: Add integer character stats and shared weapon mastery

**Files:**
- Create: `lib/app/character_stat_presenter.dart`
- Create: `lib/app/weapon_star_rating.dart`
- Test: `test/app/character_stat_presenter_test.dart`
- Test: `test/app/weapon_star_rating_test.dart`

**Interfaces:**
- Produces:

```dart
class CharacterDisplayStats {
  const CharacterDisplayStats({
    required this.health,
    required this.attack,
    required this.moveSpeed,
  });
  final int health;
  final int attack;
  final int moveSpeed;
}

CharacterDisplayStats characterDisplayStats(CharacterDefinition character);
```

- Attack equals `weaponLevels[character.startingWeaponId]!.first.damage * character.damageMultiplier`, rounded to the nearest integer. It is a presentation value, not a new combat stat.

- [ ] **Step 1: Write failing stat and mastery tests**

```dart
test('character stats are rounded integer presentation values', () {
  final stats = characterDisplayStats(characterDefinitions.first);
  expect(stats.health, 105);
  expect(stats.moveSpeed, 125);
  expect(stats.attack, isA<int>());
});

testWidgets('level six renders mastery instead of a sixth star', (tester) async {
  await tester.pumpWidget(testApp(const WeaponStarRating(level: 6)));
  expect(find.text('통달'), findsOneWidget);
  expect(find.byKey(const Key('filled-star-5')), findsNothing);
});
```

- [ ] **Step 2: Run and confirm failure**

Run: `D:\FlutterSdk\bin\flutter.bat test test/app/character_stat_presenter_test.dart test/app/weapon_star_rating_test.dart`

Expected: compile failure.

- [ ] **Step 3: Implement adapters and widget**

Clamp the rating input to 1–6. Levels 1–5 render five total star slots in regular mode. Level 6 renders five teal/blue filled stars and `통달`. Compact mode may omit empty stars but must retain `통달`.

- [ ] **Step 4: Run focused tests**

Run: `D:\FlutterSdk\bin\flutter.bat test test/app/character_stat_presenter_test.dart test/app/weapon_star_rating_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add lib/app/character_stat_presenter.dart lib/app/weapon_star_rating.dart test/app/character_stat_presenter_test.dart test/app/weapon_star_rating_test.dart
git commit -m "feat: add integer stats and weapon mastery rating"
```

### Task 5: Migrate the lobby and add training entry

**Files:**
- Modify: `lib/app/lobby_screen.dart`
- Modify: `lib/app/lobby_top_command_bar.dart`
- Modify: `lib/app/lobby_battle_stage.dart`
- Modify: `lib/app/lobby_navigation_dock.dart`
- Create: `lib/app/training_screen.dart`
- Test: `test/app/lobby_screen_test.dart`
- Test: `test/app/training_screen_test.dart`

**Interfaces:**
- `TrainingScreen` consumes the existing `TrainingProgress` and does not mutate it.
- The lobby continues to call existing character, stage, deploy, compendium, records, settings, and sync callbacks.

- [ ] **Step 1: Add failing lobby structure tests**

```dart
testWidgets('lobby keeps deploy and training entry above the safe bottom area', (tester) async {
  await pumpLobby(tester, const Size(375, 667));
  expect(find.byKey(const Key('lobby-deploy')), findsOneWidget);
  expect(find.byKey(const Key('lobby-training-entry')), findsOneWidget);
  expect(find.byKey(const Key('legacy-character-green-circle')), findsNothing);
  expect(tester.takeException(), isNull);
});
```

- [ ] **Step 2: Run focused lobby tests and confirm failure**

Run: `D:\FlutterSdk\bin\flutter.bat test test/app/lobby_screen_test.dart test/app/training_screen_test.dart`

Expected: FAIL for missing training entry and new stage treatment.

- [ ] **Step 3: Implement lobby migration**

Keep the existing background image and overlay gradient. Replace the circular green character plate with a low oval gold/teal plate and contact shadow. Consolidate resources using `JoseonResourceChip`. Add a clearly labeled training entry that opens the read-only `TrainingScreen`.

- [ ] **Step 4: Verify focused tests and hot reload**

Run: `D:\FlutterSdk\bin\flutter.bat test test/app/lobby_screen_test.dart test/app/training_screen_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add lib/app/lobby_screen.dart lib/app/lobby_top_command_bar.dart lib/app/lobby_battle_stage.dart lib/app/lobby_navigation_dock.dart lib/app/training_screen.dart test/app/lobby_screen_test.dart test/app/training_screen_test.dart
git commit -m "feat: unify lobby and expose training progress"
```

### Task 6: Rebuild character and stage selection for portrait mobile

**Files:**
- Modify: `lib/app/character_select_screen.dart`
- Modify: `lib/app/stage_select_screen.dart`
- Modify: `lib/game/content/asset_catalog.dart`
- Modify: `lib/game/content/stage_definitions.dart` to add a required presentation image key to `StageDefinition`.
- Test: `test/app/character_select_screen_test.dart`
- Test: `test/app/stage_select_screen_test.dart`

**Interfaces:**
- Consumes: `JoseonScaffold`, `JoseonSelectionCard`, `JoseonPrimaryButton`, `characterDisplayStats`.
- Preserves: `ValueChanged<String> onSelected` and existing initial/unlocked IDs.

- [ ] **Step 1: Write failing portrait interaction tests**

```dart
testWidgets('character carousel shows integer stats and fixed confirm action', (tester) async {
  await pumpCharacterSelect(tester, size: const Size(390, 844));
  expect(find.textContaining('체력 105'), findsOneWidget);
  expect(find.textContaining('%'), findsNothing);
  expect(find.byKey(const Key('character-confirm')), findsOneWidget);
  expect(tester.takeException(), isNull);
});
```

- [ ] **Step 2: Run focused selection tests**

Run: `D:\FlutterSdk\bin\flutter.bat test test/app/character_select_screen_test.dart test/app/stage_select_screen_test.dart`

Expected: FAIL against the legacy horizontal rows.

- [ ] **Step 3: Implement PageView cards and fixed actions**

Use `PageView` with `viewportFraction` between 0.84 and 0.9. A locked page remains browseable but cannot be confirmed. Keep names to one line and passive descriptions to two lines. Stage cards contain their own illustration, details, and state rather than using a separate right-side panel.

- [ ] **Step 4: Run focused tests at three sizes**

Run: `D:\FlutterSdk\bin\flutter.bat test test/app/character_select_screen_test.dart test/app/stage_select_screen_test.dart`

Expected: PASS and no overflow exceptions.

- [ ] **Step 5: Commit**

```powershell
git add lib/app/character_select_screen.dart lib/app/stage_select_screen.dart lib/game/content/asset_catalog.dart lib/game/content/stage_definitions.dart test/app/character_select_screen_test.dart test/app/stage_select_screen_test.dart
git commit -m "feat: rebuild mobile character and stage selection"
```

### Task 7: Migrate compendium and records states

**Files:**
- Modify: `lib/app/compendium_screen.dart`
- Modify: `lib/app/records_screen.dart`
- Create: `lib/app/missing_asset_placeholder.dart`
- Test: `test/app/compendium_screen_test.dart`
- Test: `test/app/records_screen_test.dart`

**Interfaces:**
- Consumes: existing compendium entries and `MetaHistoryService` results.
- Produces: locked cards that never render the unlocked art subtree.

- [ ] **Step 1: Write failing locked-content and density tests**

```dart
testWidgets('locked codex entry hides original asset and shows condition', (tester) async {
  await pumpLockedCompendium(tester);
  expect(find.byKey(const Key('locked-silhouette')), findsWidgets);
  expect(find.byKey(const Key('locked-original-image')), findsNothing);
  expect(find.textContaining('해금 조건'), findsWidgets);
});
```

- [ ] **Step 2: Run focused tests**

Run: `D:\FlutterSdk\bin\flutter.bat test test/app/compendium_screen_test.dart test/app/records_screen_test.dart`

Expected: FAIL against the current Card/List presentation.

- [ ] **Step 3: Implement shared cards and compact lists**

Use `JoseonTabBar` and `JoseonCodexCard`. Render two columns when 375px or wider and fall back to one column only when text scaling requires it. Records summary cards remain two columns, while character and weapon histories use compact rows with actual catalog image keys or `MissingAssetPlaceholder` in debug.

- [ ] **Step 4: Run focused tests**

Run: `D:\FlutterSdk\bin\flutter.bat test test/app/compendium_screen_test.dart test/app/records_screen_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add lib/app/compendium_screen.dart lib/app/records_screen.dart lib/app/missing_asset_placeholder.dart test/app/compendium_screen_test.dart test/app/records_screen_test.dart
git commit -m "feat: unify codex and records presentation"
```

### Task 8: Remove tile checkerboarding and separate sparse decals

**Files:**
- Modify: `lib/game/content/stage_visual_spec.dart`
- Modify: `lib/game/components/stage_tile_batch_component.dart`
- Modify: `lib/game/components/stage_backdrop_component.dart`
- Test: `test/game/stage_visual_spec_test.dart`
- Test: `test/game/stage_tile_batch_component_test.dart`
- Test: `test/game/stage_backdrop_component_test.dart`

**Interfaces:**
- Produces deterministic base variant selection from `(seed, chunk, tileCoordinate)`.
- Produces a separate decal list with density bands for center, edge, and landmark zones.

- [ ] **Step 1: Write failing deterministic distribution tests**

```dart
test('center keeps sparse decals and base variants are reproducible', () {
  final first = buildStagePlacements(seed: 104729, chunk: const Chunk(1, 2));
  final second = buildStagePlacements(seed: 104729, chunk: const Chunk(1, 2));
  expect(first, second);
  expect(first.centerDecalRatio, lessThan(0.08));
  expect(first.baseVariantCount, greaterThanOrEqualTo(4));
});
```

- [ ] **Step 2: Run focused Flame tests**

Run: `D:\FlutterSdk\bin\flutter.bat test test/game/stage_visual_spec_test.dart test/game/stage_tile_batch_component_test.dart test/game/stage_backdrop_component_test.dart`

Expected: FAIL because base variants and decals are not separately budgeted.

- [ ] **Step 3: Implement deterministic variant and decal policies**

Keep the existing chunk and batch lifecycle. Snap tile positions and source rectangles to integer coordinates. Use low-contrast base variants; do not place puddles, roots, blood, or large debris in the base repeating pattern. Bias decals toward edges and landmarks.

- [ ] **Step 4: Run focused tests and inspect one fixed-seed combat viewport**

Run: `D:\FlutterSdk\bin\flutter.bat test test/game/stage_visual_spec_test.dart test/game/stage_tile_batch_component_test.dart test/game/stage_backdrop_component_test.dart`

Expected: PASS; no visible 1px seams at 0.9 camera zoom.

- [ ] **Step 5: Commit**

```powershell
git add lib/game/content/stage_visual_spec.dart lib/game/components/stage_tile_batch_component.dart lib/game/components/stage_backdrop_component.dart test/game/stage_visual_spec_test.dart test/game/stage_tile_batch_component_test.dart test/game/stage_backdrop_component_test.dart
git commit -m "feat: diversify stage tiles and sparse decals"
```

### Task 9: Apply shared mastery and panels to combat UI

**Files:**
- Modify: `lib/app/game_hud.dart`
- Modify: `lib/app/level_up_overlay.dart`
- Modify: `lib/app/pause_menu_overlay.dart`
- Modify: `lib/app/run_summary_screen.dart`
- Test: `test/app/game_hud_test.dart`
- Test: `test/app/level_up_overlay_test.dart`
- Test: `test/app/game_screen_pause_test.dart`
- Create: `test/app/run_summary_screen_test.dart`

**Interfaces:**
- Consumes: `WeaponStarRating`, `JoseonPanel`, shared buttons.
- Preserves: pause, resume, level-up choice, result persistence, sync, and navigation callbacks.

- [ ] **Step 1: Write failing shared-rating and HUD meaning tests**

```dart
testWidgets('combat hud labels kills and shows mastery for level six', (tester) async {
  await pumpHud(tester, kills: 119, weaponLevel: 6);
  expect(find.byKey(const Key('kill-count-icon')), findsOneWidget);
  expect(find.text('119'), findsOneWidget);
  expect(find.text('통달'), findsOneWidget);
});
```

- [ ] **Step 2: Run focused overlay tests**

Run: `D:\FlutterSdk\bin\flutter.bat test test/app/game_hud_test.dart test/app/level_up_overlay_test.dart test/app/game_screen_pause_test.dart test/app/run_summary_screen_test.dart`

Expected: FAIL for missing shared mastery and updated panel contracts.

- [ ] **Step 3: Migrate combat surfaces**

Keep the HUD compact and screen-fixed. Add a small kill icon. Replace duplicate star/level labels with `WeaponStarRating`. Apply shared panels and buttons without increasing overlay height or changing callbacks.

- [ ] **Step 4: Run focused tests**

Run: `D:\FlutterSdk\bin\flutter.bat test test/app/game_hud_test.dart test/app/level_up_overlay_test.dart test/app/game_screen_pause_test.dart test/app/run_summary_screen_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```powershell
git add lib/app/game_hud.dart lib/app/level_up_overlay.dart lib/app/pause_menu_overlay.dart lib/app/run_summary_screen.dart test/app/game_hud_test.dart test/app/level_up_overlay_test.dart test/app/game_screen_pause_test.dart test/app/run_summary_screen_test.dart
git commit -m "feat: unify combat hud and overlays"
```

### Task 10: Add portrait golden coverage and asset contracts

**Files:**
- Modify: `test/app/joseon_lobby_mobile_golden_test.dart`
- Create: `test/app/joseon_mobile_surfaces_golden_test.dart`
- Modify: `test/game/player_visual_asset_contract_test.dart`
- Modify: `test/game/stage_visual_asset_contract_test.dart`
- Create/update golden PNG files under `test/app/goldens`.

**Interfaces:**
- Produces golden coverage for lobby, character select, stage select, compendium, records, pause, and result at required mobile sizes.

- [ ] **Step 1: Add golden harness cases**

```dart
for (final size in const [Size(390, 844), Size(375, 667), Size(430, 932)]) {
  testWidgets('character select ${size.width}x${size.height}', (tester) async {
    await pumpAtSize(tester, size, buildCharacterSelect());
    await expectLater(
      find.byType(CharacterSelectScreen),
      matchesGoldenFile('goldens/character_select_${size.width.toInt()}x${size.height.toInt()}.png'),
    );
  });
}
```

- [ ] **Step 2: Run goldens without update and confirm missing baselines**

Run: `D:\FlutterSdk\bin\flutter.bat test test/app/joseon_mobile_surfaces_golden_test.dart`

Expected: FAIL because new baselines do not exist.

- [ ] **Step 3: Generate baselines and visually inspect every image**

Run: `D:\FlutterSdk\bin\flutter.bat test --update-goldens test/app/joseon_mobile_surfaces_golden_test.dart test/app/joseon_lobby_mobile_golden_test.dart`

Expected: PASS after generation. Inspect for clipped names, browser-bottom overlap, unreadable stats, exposed locked art, six-star level 6, and repeated tile seams.

- [ ] **Step 4: Run asset contracts**

Run: `D:\FlutterSdk\bin\flutter.bat test test/game/player_visual_asset_contract_test.dart test/game/stage_visual_asset_contract_test.dart`

Expected: PASS or explicit debug missing-art state covered by tests.

- [ ] **Step 5: Commit**

```powershell
git add test/app/joseon_lobby_mobile_golden_test.dart test/app/joseon_mobile_surfaces_golden_test.dart test/app/goldens test/game/player_visual_asset_contract_test.dart test/game/stage_visual_asset_contract_test.dart
git commit -m "test: cover unified joseon mobile surfaces"
```

### Task 11: Run final integration review and required gates

**Files:**
- Modify only files required to fix failures found by the gates.
- Update: `docs/UI_ASSET_GAPS.md` if implemented assets or remaining gaps changed.

**Interfaces:**
- Produces a clean release-ready web build and a final mobile manual-check list.

- [ ] **Step 1: Run related UI and stage suites**

Run:

```powershell
D:\FlutterSdk\bin\flutter.bat test test/app test/game/stage_visual_spec_test.dart test/game/stage_tile_batch_component_test.dart test/game/stage_backdrop_component_test.dart
```

Expected: PASS.

- [ ] **Step 2: Run the one final analyzer gate**

Run: `D:\FlutterSdk\bin\flutter.bat analyze`

Expected: `No issues found!`

- [ ] **Step 3: Run the one final full test gate**

Run: `D:\FlutterSdk\bin\flutter.bat test`

Expected: `All tests passed!`

- [ ] **Step 4: Run the one final web build**

Run: `D:\FlutterSdk\bin\flutter.bat build web`

Expected: `Built build\web`.

- [ ] **Step 5: Manually verify the production web build**

Check 390×844, 375×667, and 430×932 for:

- SafeArea and bottom action visibility
- character and stage carousel legibility
- integer health/attack/speed
- locked codex confidentiality
- training entry and read-only state
- tile seams and decal repetition
- HUD/joystick/camera independence
- level 6 mastery treatment
- pause and result navigation

- [ ] **Step 6: Commit final verification fixes**

```powershell
git add docs/UI_ASSET_GAPS.md lib test
git commit -m "fix: complete unified joseon ui verification"
```

---

## Plan Self-Review

- Spec coverage: all audit surfaces, common components, SafeArea, integer stats, lock rules, training entry, tile/decal separation, HUD, mastery levels, assets, three mobile sizes, and final gates map to explicit tasks.
- Placeholder scan: every implementation and verification step is concrete.
- Type consistency: shared widgets and `CharacterDisplayStats` are defined before consumer tasks; callbacks and existing controller ownership remain unchanged.
- Scope: presentation and rendering work is isolated from balance, new content, save migrations, and training economy.
