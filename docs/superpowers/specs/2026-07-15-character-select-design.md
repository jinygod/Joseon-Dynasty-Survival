# Character Select Design

## Goal

Add the smallest trustworthy character-selection step before a run, with save-backed lock state and no dead-end interactions.

## Flow

1. Main menu resolves tutorial state, then opens character selection.
2. Character selection loads `SaveState.unlockedCharacterIds`.
3. The first unlocked character is selected by default; locked cards cannot be selected and clearly show a lock.
4. Start creates a one-player `PlayerSlot` and opens the run.
5. Restart and result-screen retry preserve that slot.

## UI

- Two landscape-friendly cards show localized name, health, speed, damage, and starting weapon.
- Selected, unlocked, and locked states are visually distinct and expose stable test keys.
- Loading and load-failure states never allow starting an invalid slot; corrupted saves already fall back through `SaveSystem`.

## Verification

- Widget tests cover default unlocked/locked cards, unlocked selection, and exact `PlayerSlot` launch.
- GameScreen integration proves the requested slot builds the game and survives restart wiring.
- Full release gate includes web and Android APK.

