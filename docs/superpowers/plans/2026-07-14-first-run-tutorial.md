# First-run Tutorial Implementation Plan

**Goal:** Complete `UX-005` with a persisted five-step tutorial that safely pauses the first run.

**Architecture:** Main menu performs the completion lookup, the overlay owns only page presentation, and GameScreen owns Flame state plus persistence on completion.

**Tech Stack:** Flutter, Flame overlays, SharedPreferences, Flutter test.

### Task 1: Tutorial progress persistence

- [ ] Write RED tests for unseen default and completion persistence.
- [ ] Implement `TutorialProgressRepository` with an isolated preference key.
- [ ] Run focused tests and commit.

### Task 2: Five-step tutorial overlay

- [ ] Write RED tests for movement → auto attack → experience → level-up → boss ordering.
- [ ] Test Skip and final Start callbacks.
- [ ] Implement the compact landscape-safe overlay with stable keys.
- [ ] Run focused tests and commit.

### Task 3: First-run integration

- [ ] Write RED menu/game tests for new and returning players.
- [ ] Make MainMenuScreen resolve tutorial state before navigation.
- [ ] Pause the first run, prioritize the tutorial overlay, persist completion, then explicitly resume.
- [ ] Run focused tests and the full release gate.
- [ ] Mark `UX-005`, update baseline/queue, and commit.

