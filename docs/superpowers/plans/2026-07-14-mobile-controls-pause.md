# Mobile Controls and Pause Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete `UX-001` through `UX-004` with a pointer-owned virtual joystick and one lifecycle-safe pause flow.

**Architecture:** `VirtualJoystick` owns raw pointer tracking and only emits `VectorInput`. `PauseMenuOverlay` is callback-driven presentation. `GameScreen` owns Flame engine pause state, lifecycle observation, Android back interception, route actions, and overlay wiring.

**Tech Stack:** Flutter widgets/pointer events, Flame overlays, Flutter test.

## Global Constraints

- First pointer owns the joystick until up/cancel; later pointers are ignored.
- Dead zone is 10 logical pixels; control diameter is 120; output magnitude never exceeds 1.
- Every pause source clears movement and never auto-resumes.
- Run end and level-up overlays take precedence over manual pause.
- Restart/menu remain available without persistent settings being implemented early.

---

### Task 1: Production virtual joystick

**Files:**
- Create: `lib/app/virtual_joystick.dart`
- Create: `test/app/virtual_joystick_test.dart`
- Modify: `lib/app/game_hud.dart`
- Modify: `test/app/game_hud_test.dart`

**Interfaces:**
- Produces: `VirtualJoystick(onInputChanged, size = 120, deadZone = 10)`.
- Changes: `GameHud(source, onPause)` with an optional pause callback for compatibility.

- [ ] **Step 1: Write failing pointer tests**

Use `WidgetTester.createGesture(pointer:)` to assert center/dead-zone zero, right-edge `(1, 0)`, outside clamp, diagonal magnitude at most 1, release zero, and second pointer moves do not change the first pointer's value.

- [ ] **Step 2: Verify RED**

Run: `flutter test test/app/virtual_joystick_test.dart -r expanded`

Expected: compilation fails because `VirtualJoystick` does not exist.

- [ ] **Step 3: Implement raw pointer ownership and visual thumb clamp**

Store `_activePointer`, ignore non-owner move/up/cancel events, and emit `VectorInput.zero` exactly when the owner ends. Dispose/reset safely if the widget is removed while active.

- [ ] **Step 4: Replace developer pad and add HUD pause button**

Use keys `virtual-joystick` and `hud-pause`. Assert the HUD renders both and pause callback fires once.

- [ ] **Step 5: Verify focused tests and commit**

```powershell
git add lib/app/virtual_joystick.dart lib/app/game_hud.dart test/app
git commit -m "feat: add mobile virtual joystick"
```

### Task 2: Pause menu overlay

**Files:**
- Create: `lib/app/pause_menu_overlay.dart`
- Create: `test/app/pause_menu_overlay_test.dart`

**Interfaces:**
- Produces callbacks `onResume`, `onRestart`, `onMenu` and internal settings panel state.

- [ ] **Step 1: Write failing menu action test**

Assert title and Continue/Restart/Settings/Main Menu render. Tap Continue, Restart, and Main Menu and assert exact callbacks.

- [ ] **Step 2: Write failing settings panel test**

Tap Settings, assert the panel explains persistent audio/vibration settings arrive in the settings phase, then tap Back and assert the four menu actions return.

- [ ] **Step 3: Implement callback-only overlay and verify GREEN**

Use a centered constrained Material panel with Korean labels and stable keys `pause-resume`, `pause-restart`, `pause-settings`, `pause-menu`, and `pause-settings-back`.

- [ ] **Step 4: Commit**

```powershell
git add lib/app/pause_menu_overlay.dart test/app/pause_menu_overlay_test.dart
git commit -m "feat: add pause menu overlay"
```

### Task 3: Game lifecycle and Android back integration

**Files:**
- Modify: `lib/app/game_screen.dart`
- Modify: `lib/game/pixel_survivor_game.dart`
- Create: `test/app/game_screen_pause_test.dart`
- Modify: `docs/master-development-todo.md`

**Interfaces:**
- Adds: `PixelSurvivorGame.canPauseRun` and `hasPendingLevelUp` read-only state.
- `GameScreen` observes lifecycle and wraps `GameWidget` in `PopScope`.

- [ ] **Step 1: Write failing HUD pause integration test**

Pump `GameScreen`, find the underlying game, set non-zero movement, tap `hud-pause`, and assert movement is zero, engine paused, and pause menu visible. Tap Continue and assert overlay is gone and engine resumed.

- [ ] **Step 2: Write failing lifecycle/back tests**

Send `AppLifecycleState.paused` twice and assert one menu overlay. Resume lifecycle and assert the game stays paused. Simulate `handlePopRoute` and assert pause opens instead of route removal.

- [ ] **Step 3: Implement one idempotent pause coordinator**

Register/remove observer, gate with live-run and level-up state, use overlay ID `pauseMenu`, and keep pause callbacks route-safe with `mounted` checks.

- [ ] **Step 4: Run focused and full verification**

Run focused app tests, then `.\tool\release_check.ps1`. Expected: analysis clean, all tests pass, web build succeeds.

- [ ] **Step 5: Mark TODO and commit**

Mark `UX-001` through `UX-004` complete with evidence, record the new test count, advance to `UX-005`, and commit only after the full gate.
