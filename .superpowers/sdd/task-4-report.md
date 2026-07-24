# Task 4 report — deterministic stage chunks

## Evidence

- RED: `flutter test --no-pub --no-test-assets` for the focused stage tests
  failed first because `StageLayout.buildChunk`, `StageChunkStreamer`, and
  `WorldBoundaryComponent` did not yet exist.
- GREEN: the five prescribed focused test files pass (23 tests).
- Targeted `flutter analyze` for the changed stage and game files passes.

## Self-review

- Chunk selection is explicit integer mixing of the run seed, visual salt, and
  cell coordinates; no string hash is used for stage art.
- Static art is chunk-local and batched no more than once per atlas key. Edge
  decoration is presentation-only and uses the four existing layout anchors.
- The game preloads both stage atlas sets and updates streaming after camera
  snap and camera updates; no backdrop component is mounted by production.

## Concern

No full-suite or device run was requested. Streamer lifecycle behavior is
covered by focused unit tests and targeted static analysis only.

## Follow-up fixes

- Boundary props now clamp their complete 128px render rectangles inside their
  owning chunk and the finite world; the boundary test uses a real prop atlas
  and verifies the rendered-placement bounds.
- Streamer priority is stage-level, immediate re-entry cancels a retiring
  bundle before it can be duplicated, and focused lifecycle coverage verifies
  a single mounted bundle per requested coordinate.
- Chunk tiles use a seed-offset global checker pattern so every horizontal and
  vertical neighbor differs, including across chunk edges. Invalid chunk sizes
  now reject with `ArgumentError`.
- The representative loop assertion now verifies the streamer and loaded
  chunks rather than the removed backdrop component.

## Follow-up verification

- The five focused Task 4 test files pass (27 tests).
- The named game-loop file still contains three unrelated combat failures:
  sealing-slash presentation plus the two Hwando mastery/critical assertions.
