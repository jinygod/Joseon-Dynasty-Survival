# Mobile Controls and Pause Design

## Scope

Complete `UX-001` through `UX-004`: production virtual joystick behavior, explicit multi-touch ownership, automatic lifecycle/back-button pause, and a functional pause overlay with continue, restart, settings entry, and main-menu actions.

## Virtual joystick

Replace the private developer pad with a public `VirtualJoystick` widget. A `Listener` owns the first pointer that touches the 120px circular control; moves from other pointers are ignored so level-up and pause taps cannot steal movement. Input inside a 10px dead zone is zero. Outside it, the vector is divided by the 60px radius and clamped to magnitude 1. Pointer up, cancellation, and movement outside the visual circle all continue tracking the owned pointer and always emit zero on release. The thumb is visually clamped to the circle.

## Pause ownership

`GameScreen` is the single pause coordinator and a `WidgetsBindingObserver`. HUD pause button, `inactive`, `paused`, `hidden`, and Android back invoke the same idempotent `_pauseGame` method. Pausing clears movement input before pausing the Flame engine and showing the `pauseMenu` overlay. It is ignored after run completion and does not replace an active level-up choice.

Continuing removes the overlay and resumes only a live run without a pending level-up. Restart replaces the current route with a fresh `GameScreen`; main menu pops to the first route. Settings opens a small in-overlay panel describing the available control behavior and linking back to the pause menu; persistent audio, vibration, screen shake, damage numbers, and UI scale are implemented under `META-004`.

## Back and lifecycle behavior

`PopScope(canPop: false)` consumes Android back during a live run and opens pause. While already paused it remains in the pause menu rather than exiting accidentally. `WidgetsBindingObserver` is registered in `initState` and removed in `dispose`. Returning to foreground never auto-resumes; the player must choose Continue.

## Testing

- Joystick widget tests: dead zone, normalized direction, radius clamp, release/cancel zero, second pointer ignored.
- Pause overlay widget tests: all four actions and settings/back behavior.
- Game screen integration: HUD pause opens overlay and stops input; continue removes it; lifecycle pause is idempotent; Android pop opens pause.
- Existing keyboard and game-loop tests remain unchanged.
- Full release gate before integration.
