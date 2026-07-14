# First-run Tutorial Design

## Goal

Teach the five facts needed to finish a first run without delaying returning players: movement, automatic attacks, experience pickups, level-up choices, and the boss warning.

## Experience

- Starting a run from the main menu checks one local completion flag.
- New players enter a paused game with a five-card tutorial overlay.
- Next advances one card; the final action and Skip both persist completion and start the run.
- Returning players enter the run immediately.
- Tutorial presentation has priority over manual pause and lifecycle handling; foregrounding never resumes it automatically.

## Architecture

- `TutorialProgressRepository` owns the SharedPreferences flag.
- `MainMenuScreen` decides whether the next `GameScreen` needs onboarding.
- `FirstRunTutorialOverlay` is callback-only presentation with internal page state.
- `GameScreen` owns pause/resume and completion persistence, matching its existing pause coordination responsibility.

## Verification

- Repository tests prove default, persistence, and preference isolation.
- Overlay tests prove exact order, final action, and Skip.
- Menu/game integration tests prove first-run display, paused safety, completion resume, and returning-player bypass.

