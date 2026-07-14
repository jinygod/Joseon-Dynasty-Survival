# Korean Strings Unification Plan

**Goal:** Complete `UX-010` by making every player-facing menu, game, result, and content name Korean and routing shared copy through one resource class.

## Scope

- Main menu title, loading, and start action.
- HUD labels and generic boss/weapon fallbacks.
- Result navigation, telemetry actions, weapon metric labels, and status messages.
- Character, enemy, weapon, and augment display names.
- Existing internal IDs, telemetry field names, and JSON payload keys remain stable English identifiers.

## Steps

- [ ] Add tests that inspect rendered menu/HUD/result text and all content display names for Latin letters.
- [ ] Create `AppStrings` and move shared UI copy to it.
- [ ] Translate remaining content definition names and technical-looking result labels.
- [ ] Update existing exact-text tests.
- [ ] Run focused tests and the full web/Android release gate.
- [ ] Mark `UX-010`, update baseline/queue, merge, and clean worktree.

