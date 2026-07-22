# Joseon Lobby Typography and Navigation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the generic Gothic lobby typography and flat utility buttons with an offline, Joseon-inspired type system and a polished mobile-game lobby shell.

**Architecture:** Add a centralized `JoseonUiTheme`, a reusable depth-button primitive, and three presentational lobby components for the command bar, battle stage, and navigation dock. Keep `LobbyScreen` responsible for controller state and navigation callbacks, while all new components remain stateless or presentation-state-only.

**Tech Stack:** Flutter 3.38/Dart 3.12, Material widgets, custom painters, bundled SIL OFL 1.1 TTF assets, `flutter_test` widget and golden tests.

## Global Constraints

- Do not copy the layout, characters, icons, or assets of Clash Royale or another commercial game.
- Preserve every existing lobby navigation callback, persistence flow, purchase gate, and widget Key.
- Use `Song Myung` only for large display text and `Gowun Batang` for readable UI text.
- Keep every primary lobby target at least 64 logical pixels wide and 72 logical pixels high.
- Support 390×844 portrait, wide layouts, and 2.0 text scale without unhandled overflow.
- Bundle the unmodified font files and their SIL Open Font License 1.1 text.

## File Map

- Create `assets/fonts/SongMyung-Regular.ttf`: unmodified official display font.
- Create `assets/fonts/GowunBatang-Regular.ttf`: unmodified official body font.
- Create `assets/fonts/GowunBatang-Bold.ttf`: unmodified official emphasized body font.
- Create `assets/fonts/licenses/SongMyung-OFL.txt` and `assets/fonts/licenses/GowunBatang-OFL.txt`: redistribution notices.
- Create `lib/app/joseon_ui_theme.dart`: font family names, palette, and app `ThemeData`.
- Create `lib/app/joseon_game_button.dart`: reusable pressed-depth button primitive.
- Create `lib/app/lobby_top_command_bar.dart`: app title, resources, premium entry slot, and settings.
- Create `lib/app/lobby_navigation_dock.dart`: four large mobile-game navigation buttons.
- Create `lib/app/lobby_battle_stage.dart`: stage, character, record, and deploy presentation.
- Modify `lib/app/lobby_screen.dart`: compose the new presentational components.
- Modify `lib/app/pixel_survivor_app.dart`: apply `JoseonUiTheme`.
- Modify `pubspec.yaml`: register font files and licenses.
- Create `test/app/joseon_ui_theme_test.dart`: font registration and theme contract.
- Create `test/app/joseon_game_button_test.dart`: depth, callback, and size contract.
- Modify `test/app/lobby_screen_test.dart`: mobile layout and preserved destinations.
- Modify `test/app/release_surface_golden_test.dart`: add real-font 390×844 lobby golden.
- Create `test/app/goldens/lobby_mobile_390x844.png`: reviewed portrait reference.

---

### Task 1: Offline Joseon Typography Theme

**Files:**
- Create: `assets/fonts/SongMyung-Regular.ttf`
- Create: `assets/fonts/GowunBatang-Regular.ttf`
- Create: `assets/fonts/GowunBatang-Bold.ttf`
- Create: `assets/fonts/licenses/SongMyung-OFL.txt`
- Create: `assets/fonts/licenses/GowunBatang-OFL.txt`
- Create: `lib/app/joseon_ui_theme.dart`
- Modify: `lib/app/pixel_survivor_app.dart`
- Modify: `pubspec.yaml`
- Test: `test/app/joseon_ui_theme_test.dart`

**Interfaces:**
- Produces: `JoseonUiTheme.displayFontFamily`, `JoseonUiTheme.bodyFontFamily`, and `JoseonUiTheme.create()`.
- Consumes: no feature-local interface.

- [ ] **Step 1: Write the failing font contract tests**

```dart
test('theme uses bundled Joseon font families', () {
  final theme = JoseonUiTheme.create();
  expect(theme.textTheme.bodyMedium?.fontFamily, JoseonUiTheme.bodyFontFamily);
  expect(JoseonUiTheme.displayStyle.fontFamily, JoseonUiTheme.displayFontFamily);
});

test('pubspec registers every offline font and license', () {
  final pubspec = File('pubspec.yaml').readAsStringSync();
  expect(pubspec, contains('assets/fonts/SongMyung-Regular.ttf'));
  expect(pubspec, contains('assets/fonts/GowunBatang-Regular.ttf'));
  expect(pubspec, contains('assets/fonts/GowunBatang-Bold.ttf'));
  expect(pubspec, contains('assets/fonts/licenses/'));
});
```

- [ ] **Step 2: Run the tests and verify the missing theme fails**

Run: `F:\bin\flutter.bat test test/app/joseon_ui_theme_test.dart --reporter compact`

Expected: FAIL because `joseon_ui_theme.dart` and the registered families do not exist.

- [ ] **Step 3: Download the exact official font and license files**

```powershell
Invoke-WebRequest https://raw.githubusercontent.com/google/fonts/main/ofl/songmyung/SongMyung-Regular.ttf -OutFile assets/fonts/SongMyung-Regular.ttf
Invoke-WebRequest https://raw.githubusercontent.com/google/fonts/main/ofl/gowunbatang/GowunBatang-Regular.ttf -OutFile assets/fonts/GowunBatang-Regular.ttf
Invoke-WebRequest https://raw.githubusercontent.com/google/fonts/main/ofl/gowunbatang/GowunBatang-Bold.ttf -OutFile assets/fonts/GowunBatang-Bold.ttf
Invoke-WebRequest https://raw.githubusercontent.com/google/fonts/main/ofl/songmyung/OFL.txt -OutFile assets/fonts/licenses/SongMyung-OFL.txt
Invoke-WebRequest https://raw.githubusercontent.com/google/fonts/main/ofl/gowunbatang/OFL.txt -OutFile assets/fonts/licenses/GowunBatang-OFL.txt
```

- [ ] **Step 4: Register fonts and implement the theme**

Add to `pubspec.yaml`:

```yaml
  assets:
    - assets/fonts/licenses/
  fonts:
    - family: SongMyung
      fonts:
        - asset: assets/fonts/SongMyung-Regular.ttf
    - family: GowunBatang
      fonts:
        - asset: assets/fonts/GowunBatang-Regular.ttf
          weight: 400
        - asset: assets/fonts/GowunBatang-Bold.ttf
          weight: 700
```

Implement `JoseonUiTheme.create()` with `fontFamily: bodyFontFamily`, a paper/jade/crimson/gold palette, explicit Gowun body styles, and a `displayStyle` using Song Myung. Replace the inline `ThemeData` in `PixelSurvivorApp` with `JoseonUiTheme.create()`.

- [ ] **Step 5: Verify the focused tests pass**

Run: `F:\bin\flutter.bat test test/app/joseon_ui_theme_test.dart --reporter compact`

Expected: PASS.

- [ ] **Step 6: Commit the typography foundation**

```bash
git add assets/fonts lib/app/joseon_ui_theme.dart lib/app/pixel_survivor_app.dart pubspec.yaml test/app/joseon_ui_theme_test.dart
git commit -m "feat: add joseon lobby typography theme"
```

---

### Task 2: Shared Pressed-Depth Game Button and Navigation Dock

**Files:**
- Create: `lib/app/joseon_game_button.dart`
- Create: `lib/app/lobby_navigation_dock.dart`
- Test: `test/app/joseon_game_button_test.dart`
- Modify: `test/app/lobby_screen_test.dart`

**Interfaces:**
- Produces: `JoseonGameButton`, with `onPressed`, `faceGradient`, `depthColor`, `borderColor`, `borderRadius`, `minimumSize`, `semanticLabel`, and `child`.
- Produces: `LobbyNavigationDock`, with four required callbacks and existing lobby Keys.
- Consumes: `JoseonUiTheme` colors and body font.

- [ ] **Step 1: Write failing button and dock tests**

```dart
testWidgets('game button exposes face, depth, and a 72px target', (tester) async {
  var taps = 0;
  await tester.pumpWidget(MaterialApp(
    home: Center(child: JoseonGameButton(
      debugId: 'test-button',
      semanticLabel: '시험 버튼',
      minimumSize: const Size(96, 72),
      onPressed: () => taps += 1,
      child: const Text('시험'),
    )),
  ));
  expect(find.byKey(const Key('test-button-face')), findsOneWidget);
  expect(find.byKey(const Key('test-button-depth')), findsOneWidget);
  expect(tester.getSize(find.byType(JoseonGameButton)).height, greaterThanOrEqualTo(72));
  await tester.tap(find.byType(JoseonGameButton));
  expect(taps, 1);
});
```

Add a `LobbyNavigationDock` test that expects `lobby-stage`, `lobby-character`, `lobby-compendium`, and `lobby-records`, each with a face and depth descendant and a minimum 72-pixel height.

- [ ] **Step 2: Run focused tests and verify missing widgets fail**

Run: `F:\bin\flutter.bat test test/app/joseon_game_button_test.dart test/app/lobby_screen_test.dart --reporter compact`

Expected: FAIL because the game button and dock do not exist.

- [ ] **Step 3: Implement press depth without owning business state**

`JoseonGameButton` uses a `Semantics(button: true)`, `GestureDetector`, `AnimatedSlide`, a fixed bottom depth layer, a gradient face, a two-pixel rim, and a top highlight. Pointer down shifts the face by four logical pixels; pointer cancel/up restores it and invokes only the supplied callback.

- [ ] **Step 4: Implement the four-button dock**

Create a dark indigo/wood dock with a gold upper rim. Each equal-width item uses `JoseonGameButton`, a colored circular icon medal, and a bold Gowun Batang label. Preserve the existing four button Keys and pass callbacks through unchanged.

- [ ] **Step 5: Run focused tests and verify green**

Run: `F:\bin\flutter.bat test test/app/joseon_game_button_test.dart test/app/lobby_screen_test.dart --reporter compact`

Expected: PASS.

- [ ] **Step 6: Commit the reusable controls**

```bash
git add lib/app/joseon_game_button.dart lib/app/lobby_navigation_dock.dart test/app/joseon_game_button_test.dart test/app/lobby_screen_test.dart
git commit -m "feat: add raised joseon lobby controls"
```

---

### Task 3: Command Bar, Battle Stage, and Responsive Lobby Composition

**Files:**
- Create: `lib/app/lobby_top_command_bar.dart`
- Create: `lib/app/lobby_battle_stage.dart`
- Modify: `lib/app/lobby_screen.dart`
- Modify: `test/app/lobby_screen_test.dart`

**Interfaces:**
- Produces: `LobbyTopCommandBar(coin, spiritJade, premiumEntry, onSettings)`.
- Produces: `LobbyBattleStage(characterId, characterName, stage, bestSeconds, launching, saving, onDeploy)`.
- Consumes: `JoseonGameButton`, `LobbyNavigationDock`, `JoseonUiTheme`, existing controller state, and existing navigation callbacks.

- [ ] **Step 1: Add failing 390×844 layout and hierarchy tests**

Pump `LobbyScreen` at 390×844 and assert:

```dart
expect(find.byKey(const Key('lobby-title-plaque')), findsOneWidget);
expect(find.byKey(const Key('lobby-resource-ribbon')), findsOneWidget);
expect(find.byKey(const Key('lobby-stage-hero')), findsOneWidget);
expect(find.byKey(const Key('lobby-deploy-face')), findsOneWidget);
expect(find.byKey(const Key('lobby-navigation-dock')), findsOneWidget);
expect(tester.takeException(), isNull);
```

Repeat with `tester.platformDispatcher.textScaleFactorTestValue = 2.0`, scroll the center stage if required, and assert all existing destinations remain reachable.

- [ ] **Step 2: Run the lobby tests and verify the new hierarchy fails**

Run: `F:\bin\flutter.bat test test/app/lobby_screen_test.dart --reporter compact`

Expected: FAIL because the title plaque, resource ribbon, deploy face, and fixed dock are absent.

- [ ] **Step 3: Implement the top command bar**

Use a paper title plaque with Song Myung, a dark resource ribbon containing rank/coin/jade medals, and an embossed circular settings button. Accept the premium widget as a slot so purchase state remains owned by `LobbyScreen`.

- [ ] **Step 4: Implement the battle stage**

Move the existing stage painter and character atlas crop into `LobbyBattleStage`. Add layered roof tiles, paper screen, moon halo, floor shadow, stage ribbon, and a large `JoseonGameButton(debugId: 'lobby-deploy')`. Keep `lobby-stage-hero`, `lobby-character-art`, and `lobby-deploy` behavior available.

- [ ] **Step 5: Compose the responsive lobby**

Use `SafeArea > Column` with the top command bar, an `Expanded` scrollable center stage constrained to a readable maximum width, and the fixed navigation dock. At widths above 600, keep the same hierarchy and center it rather than reverting to utility side buttons. Remove the old private header, menu button, stage, character art, and painter definitions from `lobby_screen.dart`.

- [ ] **Step 6: Run navigation, responsive, and accessibility tests**

Run: `F:\bin\flutter.bat test test/app/lobby_screen_test.dart test/app/responsive_layout_test.dart test/app/accessibility_surfaces_test.dart --reporter compact`

Expected: PASS with no overflow exception.

- [ ] **Step 7: Commit the lobby composition**

```bash
git add lib/app/lobby_screen.dart lib/app/lobby_top_command_bar.dart lib/app/lobby_battle_stage.dart test/app/lobby_screen_test.dart
git commit -m "feat: rebuild lobby as joseon command hall"
```

---

### Task 4: Real-Font Portrait Golden and Release Gates

**Files:**
- Modify: `test/app/release_surface_golden_test.dart`
- Create: `test/app/goldens/lobby_mobile_390x844.png`
- Modify: `docs/testing/balanced-casual-mobile-checklist.md`

**Interfaces:**
- Consumes: `JoseonUiTheme.create()` and the complete `LobbyScreen`.
- Produces: deterministic 390×844 visual regression coverage.

- [ ] **Step 1: Add the portrait golden test before the file exists**

Create a helper that sets `physicalSize = Size(390, 844)`, `devicePixelRatio = 1`, pumps `MaterialApp(theme: JoseonUiTheme.create(), home: LobbyScreen(...))`, waits for bundled fonts, and matches `goldens/lobby_mobile_390x844.png`.

- [ ] **Step 2: Run the golden test and verify the missing golden failure**

Run: `F:\bin\flutter.bat test test/app/release_surface_golden_test.dart --plain-name "lobby mobile 390x844 golden"`

Expected: FAIL because the new golden file does not exist.

- [ ] **Step 3: Generate and inspect the golden**

Run: `F:\bin\flutter.bat test test/app/release_surface_golden_test.dart --plain-name "lobby mobile 390x844 golden" --update-goldens`

Inspect the PNG at original resolution. Reject it if Korean text clips, the dock resembles pale Material pills, the deploy action lacks depth, or the character/stage loses visual priority.

- [ ] **Step 4: Record physical review items**

Add unchecked checklist items for Korean font rendering, button press depth, thumb reach, 2.0 text scale, SafeArea, and 60 FPS lobby transitions. Do not mark physical-device checks complete from a desktop golden.

- [ ] **Step 5: Run all release gates**

```powershell
F:\bin\flutter.bat test --reporter compact
F:\bin\flutter.bat analyze
F:\bin\flutter.bat build web --release
$env:ANDROID_HOME='D:\android-sdk'; $env:ANDROID_SDK_ROOT='D:\android-sdk'; F:\bin\flutter.bat build apk --debug
git diff --check
```

Expected: all tests pass, analysis reports no issues, both builds exit 0, and diff check prints nothing.

- [ ] **Step 6: Commit the verified golden and checklist**

```bash
git add test/app/release_surface_golden_test.dart test/app/goldens/lobby_mobile_390x844.png docs/testing/balanced-casual-mobile-checklist.md
git commit -m "test: lock joseon mobile lobby presentation"
```

- [ ] **Step 7: Push and refresh the external play link**

Push `codex/balanced-casual-art-overhaul`, start a fresh server from `build/web`, create a new Cloudflare quick tunnel, and verify the external `main.dart.js` SHA-256 equals the local build before giving the URL to the user.
