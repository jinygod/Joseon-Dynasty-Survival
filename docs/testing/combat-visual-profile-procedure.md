# Chrome Combat Visual Profile Procedure

This procedure produces Chrome-only evidence. It never supports a mobile or
device-performance claim. The separate deterministic host test reports only
fixed-dt logical FPS and test-loop update+lifecycle wall time; neither is a
frame/render timing measurement.

## Fixed capture contract

- Scenario seed: `3107`.
- Captured combat window: exactly 60.0 seconds, from the first combat input
  after the HUD is interactive until the 60.0-second timer expires.
- Browser: Google Chrome, one normal-profile window, extensions disabled.
- Flutter mode: web profile mode. Flutter web profile traces are recorded in
  Chrome DevTools, not Flutter DevTools.
- Output directory: `build/qa/combat-visual-profile/`.

The current interactive app has no supported runtime seed injection. Before
calling a capture `seed 3107`, use a build that exposes the existing seeded
combat scenario (or record `not measured: seed injection unavailable`). Do not
silently substitute a random interactive run for seed 3107. Adding that launch
hook is outside this reporting-only task.

## Preparation

In PowerShell at the repository root, use ASCII drive mappings if the local
Flutter SDK or workspace path contains non-ASCII characters (see
`docs/testing/local-playtest.md`). Then run:

```powershell
New-Item -ItemType Directory -Force -Path build/qa/combat-visual-profile | Out-Null
flutter pub get
flutter run -d chrome --profile --dart-define=MOBILE_PREVIEW=false
```

Record the following verbatim in
`build/qa/combat-visual-profile/environment.md`: date/time and time zone,
commit SHA, `flutter --version`, `chrome --version`, OS, CPU, RAM, display
refresh rate, browser command line, browser profile/extension state, and the
exact command above. If Flutter fails before the app starts with an
`ink_sparkle.frag`/`impellerc` SIGSEGV, save the console output as
`pre-app-environment-failure.log` and stop. This is a pre-app environment
failure, not an application performance result.

## Two-run sequence

1. Launch the seeded scenario, enter combat, and allow 60.0 seconds of combat
   without recording. This is the warm restart run; save only its environment
   record as `warm-restart.md`.
2. Close Chrome completely, then relaunch the same `flutter run` profile-mode
   command with the same seed-3107 scenario.
3. Enter combat for the first time. This is the cold first-combat run. Open
   Chrome DevTools > Performance, enable screenshots, and click Record exactly
   as the first combat input is issued.
4. At 60.0 seconds, stop input, click Stop, and export the trace to
   `build/qa/combat-visual-profile/cold-first-combat-trace.json`.

## Measurements and export

From the cold trace, export frame, build, and raster duration series separately
in milliseconds. Feed them to `ChromeFrameProfile.fromMilliseconds`; it sorts
each copied series independently, uses nearest-rank p50/p95/p99, and reports
strict frame counts over 33 ms and 50 ms. Never merge build or raster samples
into frame samples.

Also record in `cold-first-combat-observations.json`:

- first image-load timestamp per named asset, in milliseconds from capture
  start;
- named component create and remove rates, in components per second;
- whether each metric is `measured`, `not measured`, or `unavailable`, plus a
  concrete reason for the latter two;
- the profile JSON and Markdown exports as
  `chrome-frame-profile.json` and `chrome-frame-profile.md`.

`not measured` means the app ran but the required instrumentation/export was
not collected. `unavailable` means an external limitation prevented collection
(for example, no seeded launcher or a pre-app shader compiler crash). Do not
estimate either state from deterministic host values, Chrome values, or another
machine. Chrome data is not mobile/device data.
