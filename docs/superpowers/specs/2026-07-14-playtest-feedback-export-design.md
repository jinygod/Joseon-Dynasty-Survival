# Playtest Feedback and Export Design

## Scope

Complete `TEL-008` through `TEL-012`: collect structured feedback on the result screen, show weapon performance, copy one run as JSON, export all retained runs as a JSON file, expand automated coverage, and provide a repeatable playtest guide.

## Result-screen flow

The existing result statistics and unlocks remain first. A weapon-performance section lists every weapon present in final levels, damage totals, or kill totals as `Lv N · 피해 N · 처치 N`. Below it, the tester selects fun 1–5, difficulty 1–5, and retry intent Yes/No; an optional comment is limited to 200 trimmed characters. Submission is disabled until all three structured answers exist and shows a saved confirmation afterward.

Two secondary actions follow: `이 런 JSON 복사` copies the latest stored representation of this run, including submitted feedback, and `전체 기록 JSON 내보내기` opens the platform share sheet with a UTF-8 `run-telemetry.json` file containing the retained history.

## Data flow and boundaries

`RunFeedback` is an immutable JSON value on `RunTelemetry`. Its fields are `funRating`, `difficultyRating`, `retryIntent`, and `comment`. Older schema-1 rows without feedback remain readable.

`RunTelemetryService.record` returns the stored telemetry on success and null on isolated failure. `GameScreen` passes its run ID to result-screen callbacks. `TelemetryRepository.updateFeedback` replaces only the matching row while preserving order and the 50-run cap. `TelemetryExportService` owns clipboard/share platform APIs; the widget receives callbacks and contains no persistence logic.

All feedback/export failures are reported with a `SnackBar` and never disable restart or menu navigation. Exporting an empty history reports that there is no data rather than creating an empty file.

## Export choice

The preferred approach is `share_plus: ^13.2.0` with an in-memory JSON `XFile`, because it produces a user-visible file destination without storage permissions. Clipboard-only export does not satisfy the file requirement, and writing directly to an app folder makes retrieval harder on Android.

## Testing

- Model round trip and legacy decoding for feedback.
- Repository feedback replacement, missing-run behavior, and history preservation.
- Export service exact JSON and isolated platform callbacks.
- Result-screen widget tests for validation, submission, weapon metrics, copy, and export actions.
- Existing end-to-end game-screen test verifies the recorded run ID reaches the summary callbacks.
- Full format, analysis, test, and web release gate before integration.

## Playtest documentation

The guide defines setup, consent/privacy wording for local-only data, a fixed 5-minute test protocol, required feedback answers, JSON handoff steps, file naming, and a run log template. No personal information is requested.
