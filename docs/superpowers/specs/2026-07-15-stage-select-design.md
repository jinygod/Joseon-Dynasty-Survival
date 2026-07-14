# Stage Select Design

## Goal

Give players a clear confirmation step between character choice and combat, and state the five-minute run contract before launch.

## Flow

- Character selection pushes stage selection so Back returns to character choice.
- The initial release exposes one selected stage: `moonlit_abandoned_office` / 달빛 폐관아.
- The card states the 5:00 target, 4:30 boss arrival, and boss-defeat victory condition.
- Start passes both the existing `PlayerSlot` and selected stage ID to GameScreen.
- Pause restart and result retry preserve both values.

## Architecture

- `StageDefinition` and `stageDefinitions` hold release content and timings.
- `StageSelectScreen` is callback-only presentation with a selected stage.
- `GameScreen.stageId` is explicit future-facing run configuration; current gameplay remains the single implemented map.

## Verification

- Widget tests assert the timing contract and exact stage/slot launch.
- Navigation tests assert menu → character → stage → game.
- Restart tests assert stage ID continuity.

