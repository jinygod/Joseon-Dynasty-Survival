# Mobile Lobby and Choice Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make player facing and health readable, replace the fixed lower-left stick with a floating bottom-center joystick, and rebuild the lobby and level-up cards for clear portrait-mobile use.

**Architecture:** Keep combat state and save flows unchanged. `PlayerComponent` owns only world-space presentation, `VirtualJoystick` owns one pointer and its floating origin, while `GameHud`, `LobbyScreen`, and `LevelUpOverlay` provide adaptive Flutter layouts around existing callbacks and models.

**Tech Stack:** Flutter widgets and widget tests, Flame component rendering, Dart, golden tests.

## Global Constraints

- Do not copy the supplied commercial game images, characters, icons, or exact UI composition.
- Preserve combat collision, attack geometry, save data, unlock policy, callbacks, and premium-shop behavior.
- Portrait mobile at `390 x 844` is the primary layout; wide and large-text layouts must remain usable.
- Existing high-resolution representative actor assets remain the art source; do not add bulk raster art.
- The joystick accepts one pointer, resets to zero on release, and never captures pause or modal-choice interactions.

---

### Task 1: Instant 2D Facing and World Health Bar

**Files:**
- Modify: `lib/game/components/player_component.dart`
- Modify: `test/game/player_component_test.dart`

**Interfaces:**
- Consumes: `PlayerComponent.healthFraction`, `_desiredFacingX`, Flame `Canvas` rendering.
- Produces: `double get displayedFacingX`, `Color get worldHealthBarColor`, and a non-transformed health-bar render pass.

- [ ] **Step 1: Write failing behavior tests**

Add tests that switch from right to left and assert the displayed facing jumps directly to `-1`, and that health thresholds map to safe, warning, and danger colors:

```dart
player.applyInput(const VectorInput(1, 0), 0);
player.update(0.016);
player.applyInput(const VectorInput(-1, 0), 0);
player.update(0.016);
expect(player.displayedFacingX, -1);

expect(player.worldHealthBarColor, const Color(0xff39d98a));
player.takeDamage(70);
expect(player.worldHealthBarColor, const Color(0xffffc857));
player.takeDamage(20);
expect(player.worldHealthBarColor, const Color(0xffef5b5b));
```

- [ ] **Step 2: Run the focused test and confirm RED**

Run: `F:\bin\flutter.bat test test/game/player_component_test.dart`

Expected: FAIL because `displayedFacingX` and `worldHealthBarColor` are not public and facing still interpolates.

- [ ] **Step 3: Implement the minimal presentation change**

Remove the exponential facing interpolation and assign `_displayedFacingX = _desiredFacingX` during pose update. Expose read-only test getters. After restoring the sprite canvas, draw a centered `30 x 5` bar at `size.y + 3` with a dark outline, dark track, and width `healthFraction * 28` using the threshold colors.

```dart
double get displayedFacingX => _displayedFacingX;
Color get worldHealthBarColor => healthFraction <= .2
    ? const Color(0xffef5b5b)
    : healthFraction <= .35
    ? const Color(0xffffc857)
    : const Color(0xff39d98a);
```

- [ ] **Step 4: Run focused tests and confirm GREEN**

Run: `F:\bin\flutter.bat test test/game/player_component_test.dart`

Expected: all player component tests pass.

- [ ] **Step 5: Commit**

```powershell
git add lib/game/components/player_component.dart test/game/player_component_test.dart
git commit -m "fix: use instant 2d facing and world health bar"
```

### Task 2: Bottom-Center Floating Joystick

**Files:**
- Modify: `lib/app/virtual_joystick.dart`
- Modify: `lib/app/game_hud.dart`
- Modify: `test/app/virtual_joystick_test.dart`
- Modify: `test/app/game_hud_test.dart`
- Modify: `test/app/responsive_layout_test.dart`

**Interfaces:**
- Consumes: `ValueChanged<VectorInput> onInputChanged`, full HUD constraints, pointer-local positions.
- Produces: a full-area `VirtualJoystick` with `idleCenter`, active-origin ownership, clamped vector output, and keyed visual base `virtual-joystick-base`.

- [ ] **Step 1: Write failing floating-origin tests**

Render the joystick in `SizedBox(width: 390, height: 844)`. Assert its idle base center is near `(195, 756)`, then start gestures at `(80, 600)` and `(300, 500)` and verify each start yields zero while a 60-pixel right drag yields positive X. Release must append `VectorInput.zero` and restore the visual base to the idle center.

```dart
final first = await tester.startGesture(origin + const Offset(80, 600));
expect(inputs.last, VectorInput.zero);
await first.moveBy(const Offset(60, 0));
expect(inputs.last.x, closeTo(1, .01));
await first.up();
expect(inputs.last, VectorInput.zero);
```

- [ ] **Step 2: Run tests and confirm RED**

Run: `F:\bin\flutter.bat test test/app/virtual_joystick_test.dart test/app/game_hud_test.dart test/app/responsive_layout_test.dart`

Expected: FAIL because the current joystick only responds inside a fixed 104-pixel square at lower left.

- [ ] **Step 3: Implement one-pointer floating control**

Make `VirtualJoystick` fill its parent. On pointer down, store `event.localPosition` as `_activeCenter`, emit zero, and move the base there. Compute subsequent deltas from `_activeCenter`, clamp by `size / 2`, and on release reset input and center. Paint only a positioned `size x size` base so the invisible listener covers the battle area while the visible control remains compact.

In `GameHud`, replace the lower-left `Positioned` with `Positioned.fill`, pass an idle center derived from `LayoutBuilder` as bottom-center, and keep the pause button later in the Stack so it wins hit testing.

- [ ] **Step 4: Run focused tests and confirm GREEN**

Run: `F:\bin\flutter.bat test test/app/virtual_joystick_test.dart test/app/game_hud_test.dart test/app/responsive_layout_test.dart test/app/accessibility_surfaces_test.dart`

Expected: all joystick, HUD, responsive, and accessibility tests pass.

- [ ] **Step 5: Commit**

```powershell
git add lib/app/virtual_joystick.dart lib/app/game_hud.dart test/app/virtual_joystick_test.dart test/app/game_hud_test.dart test/app/responsive_layout_test.dart
git commit -m "feat: add bottom-center floating joystick"
```

### Task 3: Joseon Casual Adaptive Lobby

**Files:**
- Modify: `lib/app/lobby_screen.dart`
- Modify: `test/app/lobby_screen_test.dart`
- Modify: `test/app/release_surface_golden_test.dart`
- Modify: relevant files under `test/app/goldens/`

**Interfaces:**
- Consumes: existing `LobbyController.state`, character/stage definitions, current navigation callbacks and asset catalog.
- Produces: keyed regions `lobby-resource-bar`, `lobby-stage-hero`, `lobby-character-art`, and `lobby-bottom-menu` without changing destination keys.

- [ ] **Step 1: Add portrait layout tests**

Set the test view to `390 x 844`, render `LobbyScreen`, and assert the resource bar, stage hero, character art, deploy action, and all five destination keys exist without `FlutterError` overflow exceptions. Assert the deploy button is horizontally centered and below the stage title.

- [ ] **Step 2: Run lobby tests and confirm RED**

Run: `F:\bin\flutter.bat test test/app/lobby_screen_test.dart`

Expected: FAIL because the new keyed regions and portrait hierarchy do not exist.

- [ ] **Step 3: Implement the adaptive lobby**

Use `LayoutBuilder`: under 600 logical pixels, render a warm hanji gradient background, compact resource row, central scrollable stage hero, large gold deploy button, and bottom `Wrap` menu; at 600 or wider retain side actions around a larger hero. Reuse the selected character's existing high-resolution image with `FilterQuality.medium`. Create the Joseon office silhouette with Flutter shapes and the existing low-opacity lobby texture; retain every existing navigation callback and key.

- [ ] **Step 4: Run tests, update goldens, and visually inspect**

Run: `F:\bin\flutter.bat test test/app/lobby_screen_test.dart`

Run golden update: `F:\bin\flutter.bat test --update-goldens test/app/release_surface_golden_test.dart`

Inspect the updated portrait and wide lobby images for text clipping, touch-target overlap, and sufficient character contrast.

- [ ] **Step 5: Commit**

```powershell
git add lib/app/lobby_screen.dart test/app/lobby_screen_test.dart test/app/release_surface_golden_test.dart test/app/goldens
git commit -m "feat: rebuild lobby for portrait mobile"
```

### Task 4: Readable Adaptive Level-Up Cards

**Files:**
- Modify: `lib/app/level_up_overlay.dart`
- Create: `test/app/level_up_overlay_test.dart`
- Modify: any level-up overlay golden under `test/app/goldens/` if covered by release surfaces.

**Interfaces:**
- Consumes: unchanged `List<LevelUpChoice>` and `ValueChanged<LevelUpChoice>`.
- Produces: keyed `level-up-title`, `level-up-choice-<index>`, `level-up-choice-name-<index>`, and `level-up-choice-effect-<index>` widgets.

- [ ] **Step 1: Write portrait and wide failing tests**

At `390 x 844`, supply three choices with long Korean names and descriptions. Assert all exact strings are present, each card is wider than 300 pixels, and tapping the second key returns that exact choice. At `844 x 390`, assert the three cards share one row and each name/effect remains discoverable.

- [ ] **Step 2: Run the new test and confirm RED**

Run: `F:\bin\flutter.bat test test/app/level_up_overlay_test.dart`

Expected: FAIL because the current overlay always uses a narrow fixed three-column row and lacks the new keys.

- [ ] **Step 3: Implement the card design**

Build a dark scrim with a gold `성장 선택` ribbon. Under 600 pixels wide, use a scrollable Column of three horizontal cards with icon medallion, colored type header, name, level transition, full effect text, and six level pips. At wider widths, use three equal vertical cards. Do not set ellipsis on the effect; allow wrapping and use scroll instead of shrinking the type.

- [ ] **Step 4: Run overlay and accessibility tests**

Run: `F:\bin\flutter.bat test test/app/level_up_overlay_test.dart test/app/accessibility_surfaces_test.dart test/app/game_screen_settings_test.dart`

Expected: all tests pass with no overflow exceptions.

- [ ] **Step 5: Commit**

```powershell
git add lib/app/level_up_overlay.dart test/app/level_up_overlay_test.dart test/app/goldens
git commit -m "feat: make level-up choices readable on mobile"
```

### Task 5: Integrated Visual and Release Verification

**Files:**
- Modify: `docs/playtest/2026-07-22-complete-base-roster-checklist.md`
- Modify: impacted golden files under `test/app/goldens/`

**Interfaces:**
- Consumes: Tasks 1-4.
- Produces: updated phone checklist, clean branch, web build, Android debug APK, remote branch, and refreshed external play URL.

- [ ] **Step 1: Add manual phone checks**

Add checks for instant facing with no squash frame, player-foot health bar readability, two different floating-stick origins, portrait lobby hierarchy, and complete level-up effect text.

- [ ] **Step 2: Run focused visual tests**

Run: `F:\bin\flutter.bat test test/game/player_component_test.dart test/app/virtual_joystick_test.dart test/app/lobby_screen_test.dart test/app/level_up_overlay_test.dart`

Expected: all focused tests pass.

- [ ] **Step 3: Run complete gates**

```powershell
F:\bin\flutter.bat test
F:\bin\flutter.bat analyze
$env:PUB_CACHE='D:\codex-pub-cache'; F:\bin\flutter.bat build web --release
$env:PUB_CACHE='D:\codex-pub-cache'; F:\bin\flutter.bat build apk --debug
```

Expected: zero test/analyze failures and both builds exit 0.

- [ ] **Step 4: Commit and push**

```powershell
git add docs/playtest test/app/goldens
git commit -m "test: verify mobile lobby and control polish"
git push
```

- [ ] **Step 5: Refresh external test deployment**

Serve `build/web`, reuse or create a Cloudflare quick tunnel, verify HTTP 200, and compare external `main.dart.js` SHA-256 with the local build before returning the phone link.
