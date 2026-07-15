# Audio Settings Design

## Goal

Complete `AUD-007` by giving players independent music volume, sound-effect volume, and vibration preferences that apply immediately and survive app restarts. The settings must remain useful while the current backend is silent and must be ready for future real audio and haptic implementations.

## Scope

This milestone includes:

- music volume from 0% to 100%, default 70%;
- sound-effect volume from 0% to 100%, default 80%;
- vibration enabled or disabled, default enabled;
- independent `SharedPreferences` persistence;
- safe recovery from missing, malformed, non-finite, or out-of-range values;
- an observable controller for immediate UI updates;
- volume propagation into typed audio playback requests;
- suppression of music or sound-effect playback when its volume is zero;
- a functional settings page inside the pause overlay;
- persistence, controller, audio-service, widget, and game-screen integration tests.

This milestone does not add audio files, an audio playback package, haptic calls, menu-screen settings, screen-shake settings, damage-number settings, or UI-scale settings. Actual vibration behavior remains `AUD-008`; broader accessibility settings remain `META-004`.

## Data Model

`AudioSettings` is immutable and contains normalized values:

- `double musicVolume` in `0.0..1.0`;
- `double sfxVolume` in `0.0..1.0`;
- `bool vibrationEnabled`.

`AudioSettings.defaults` is `(0.7, 0.8, true)`. Copy operations clamp finite volume values to the valid range. Persistence recovery treats non-numeric and non-finite values as the corresponding default rather than guessing.

UI cues share the sound-effect volume because `AUD-007` defines only music and effects controls. A future milestone may add a separate UI channel setting without changing persisted music or effect values.

## Persistence

`AudioSettingsRepository` owns three namespaced `SharedPreferences` keys and exposes:

- `Future<AudioSettings> load()`;
- `Future<void> save(AudioSettings settings)`.

Loading is tolerant: absent or invalid values resolve independently to defaults, and valid values are clamped to `0.0..1.0`. Saving writes all three values and throws if any platform write reports failure. The controller contains those failures so repository behavior remains observable and testable.

These preferences are deliberately separate from progression `SaveState`. Resetting or migrating player unlock data must not silently change audio preferences, and audio setting changes must not rewrite progression data.

## Controller

`AudioSettingsController` extends `ChangeNotifier`. It starts with defaults, exposes the current immutable `settings`, and has:

- `Future<void> load()`;
- `Future<void> setMusicVolume(double value)`;
- `Future<void> setSfxVolume(double value)`;
- `Future<void> setVibrationEnabled(bool value)`.

Updates are optimistic: the controller clamps and publishes the new in-memory value immediately, then persists the complete snapshot. A load or save failure is reported through an optional diagnostic callback and never escapes into widget event handling or gameplay. A load failure retains defaults. Repeated assignment of the same normalized value does not notify or write again.

## Audio Integration

`AudioPlaybackRequest` gains a normalized `volume` field. `AudioPlaybackPolicy.requestFor` accepts the current channel volume and includes it in the request.

`GameAudioService` accepts an optional `AudioSettings` reader. On each `play` call it reads the latest settings, maps music to `musicVolume` and both SFX/UI to `sfxVolume`, and constructs the request with that volume. A zero-volume request returns before backend admission and does not consume a voice, advance SFX pitch, or call the backend. Existing priority, capacity, pitch, lifecycle, and error-isolation behavior remains unchanged.

The default settings reader uses `AudioSettings.defaults`, preserving current callers and test behavior until app-wide audio wiring is added.

## UI and Ownership

`GameScreen` owns an `AudioSettingsController` unless one is injected for tests. It starts loading during initialization, passes the controller to `PauseMenuOverlay`, and disposes only a controller it created.

The pause settings page replaces the placeholder with:

- a music slider labeled with the current percentage;
- an effects slider labeled with the current percentage;
- a vibration switch;
- the existing back button.

Sliders use ten divisions for 10% steps and call controller setters without blocking interaction. The page rebuilds from controller notifications. Vibration changes are stored now but do not trigger platform haptics in this milestone.

## Error Handling

- Invalid persisted fields recover independently.
- Repository load/save errors become controller diagnostics.
- Controller diagnostic callback errors are contained.
- Settings failures never pause, restart, exit, or trap the game.
- Zero volume is treated as a normal policy decision, not an error.
- Existing backend and playback-handle diagnostics remain unchanged.

## Acceptance Criteria

- Defaults are exactly 70% music, 80% effects, and vibration enabled.
- Valid values round-trip through `SharedPreferences`.
- Missing, malformed, non-finite, and out-of-range values recover or clamp independently.
- Controller changes are visible immediately and persist across a new repository/controller instance.
- Equal-value changes do not write or notify twice.
- Playback requests carry current normalized volume.
- Music zero suppresses only music; effects zero suppresses SFX and UI.
- Muted requests do not advance the repeated-SFX pitch cycle.
- Pause settings display and change all three preferences.
- Game-screen-created controllers are loaded and disposed safely; injected controllers are not disposed by the screen.
- Existing 227 tests remain green and new tests cover model, repository, controller, service, and UI behavior.
- Formatting, analysis, all tests, web build, and Android debug APK build pass.
