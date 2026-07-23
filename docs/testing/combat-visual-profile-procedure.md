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
- Output directory: a fresh, run-specific directory created once per capture.

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
$runId = Get-Date -Format 'yyyy-MM-ddTHHmmss-seed3107'
$runDirectory = Join-Path 'build/qa/combat-visual-profile' $runId
New-Item -ItemType Directory -Force -Path $runDirectory | Out-Null
$environmentPath = Join-Path $runDirectory 'environment.md'
$warmRestartPath = Join-Path $runDirectory 'warm-restart.md'
$coldTracePath = Join-Path $runDirectory 'cold-first-combat-trace.json'
$observationsPath = Join-Path $runDirectory 'cold-first-combat-observations.json'
$normalizedCapturePath = Join-Path $runDirectory 'normalized-capture.json'
$profileJsonPath = Join-Path $runDirectory 'chrome-frame-profile.json'
$profileMarkdownPath = Join-Path $runDirectory 'chrome-frame-profile.md'
$notMeasuredPath = Join-Path $runDirectory 'chrome-frame-profile-not-measured.json'
flutter pub get
flutter run -d chrome --profile --dart-define=MOBILE_PREVIEW=false
```

Keep this PowerShell session open so each later command uses the same existing
`$runDirectory`. Record the following verbatim in `$environmentPath`: date/time and time zone,
commit SHA, `flutter --version`, `chrome --version`, OS, CPU, RAM, display
refresh rate, browser command line, browser profile/extension state, and the
exact command above. If Flutter fails before the app starts with an
`ink_sparkle.frag`/`impellerc` SIGSEGV, save the console output to
`Join-Path $runDirectory 'pre-app-environment-failure.log'` and stop. This is a pre-app environment
failure, not an application performance result.

## Two-run sequence

If the supported seed-3107 scenario is unavailable, do not perform these
steps. Run the exact `--not-measured` command in the next section instead.

1. Launch the seeded scenario, enter combat, and allow 60.0 seconds of combat
   without recording. This is the warm restart run; save only its environment
   record at `$warmRestartPath`.
2. Close Chrome completely, then relaunch the same `flutter run` profile-mode
   command with the same seed-3107 scenario.
3. Enter combat for the first time. This is the cold first-combat run. Open
   Chrome DevTools > Performance, enable screenshots, and click Record exactly
   as the first combat input is issued.
4. At 60.0 seconds, stop input, click Stop, and export the trace to
   `$coldTracePath`.

## Measurements and export

With a future supported capture exporter, keep frame, build, and raster
duration series separate in milliseconds. The artifact tool feeds them to
`ChromeFrameProfile`, which sorts each copied series independently, uses
nearest-rank p50/p95/p99, and reports strict frame counts over 33 ms and 50 ms.
Never merge build or raster samples into frame samples.

The current app has neither a seed-3107 launcher nor instrumentation that
exports named image-load/component events into a normalized capture. Therefore
there is no truthful raw Chrome/Flutter DevTools trace conversion command to
document here: do not guess trace event names or infer these series from a
trace. Create the required evidence immediately with:

```powershell
dart run tool/combat_visual_profile_report.dart --not-measured "seed injection and profile instrumentation unavailable" --output $runDirectory
```

This writes
`chrome-frame-profile-not-measured.json` in that run directory and
does not create a made-up profile result.

When a future supported capture exporter produces the normalized JSON below,
the end-to-end aggregation and artifact-writing command is:

```powershell
dart run tool/combat_visual_profile_report.dart --input $normalizedCapturePath --output $runDirectory
```

`normalized-capture.json` has this exact schema; every field is required and
all duration values are milliseconds:

```json
{
  "frameMs": [8.0],
  "buildMs": [3.0],
  "rasterMs": [4.0],
  "imageLoadTimestampsMs": {"player": 12.0},
  "componentCreateRates": {"enemy": 3.0},
  "componentRemoveRates": {"enemy": 2.0}
}
```

The command validates the schema, aggregates through `ChromeFrameProfile`, and
writes `chrome-frame-profile.json` and `chrome-frame-profile.md`. It does not
parse Chrome trace events itself, so no tool output may be claimed until a
supported exporter supplies this normalized input.

The tool fails closed if a measured artifact (`chrome-frame-profile.json` or
`chrome-frame-profile.md`) and not-measured evidence would coexist in the same
directory. It does not delete or alter existing conflicting evidence. Repeating
the same mode is allowed and overwrites only that mode's own artifact files;
use a new timestamped directory for every capture to preserve prior evidence.

For a supported future capture, also record in
`$observationsPath`:

- first image-load timestamp per named asset, in milliseconds from capture
  start;
- named component create and remove rates, in components per second;
- whether each metric is `measured`, `not measured`, or `unavailable`, plus a
  concrete reason for the latter two;
- the profile JSON and Markdown exports written by the tool.

`not measured` means the app ran but the required instrumentation/export was
not collected. `unavailable` means an external limitation prevented collection
(for example, no seeded launcher or a pre-app shader compiler crash). Do not
estimate either state from deterministic host values, Chrome values, or another
machine. Chrome data is not mobile/device data.
