# Three Boss Roster Verification

## Scope

- `CNT-011`: three bosses, each with three combat patterns and a declared
  enrage rule.
- `CNT-012`: two new bosses connected to real stage-run selection, shared state
  machine, readable warnings, attacks, fallback visuals, and automated tests.

## TDD evidence

The first focused run failed at compile time because
`boss_definitions.dart`, `BossController(definition:)`, the generic warning and
execute actions, `PixelSurvivorGame.bossRoll`, and `bossId` did not exist.

After the minimum implementation:

```powershell
flutter test test/game/boss_definition_test.dart `
  test/game/boss_controller_test.dart `
  test/game/boss_component_patterns_test.dart `
  test/game/boss_component_visual_test.dart `
  test/game/boss_stage_runtime_test.dart `
  test/game/boss_balance_baseline_test.dart -r compact
```

Result: 20 tests passed, 0 failed.

## Full verification

Flutter 3.44.4 initially crashed its shader compiler on the Korean checkout
path. The Flutter SDK and worktree were mapped to ASCII-only `subst` drives.
An interrupted parallel mapping then left stale generated shader assets, so
`flutter clean` was run before the final gate.

```powershell
dart format --output=none --set-exit-if-changed lib test
dart analyze
flutter clean
flutter pub get
flutter test -r compact
flutter build web
```

Final results:

- Format: 168 Dart files checked; only normalized line endings were reported,
  with no Git source diff.
- Analyze: `No issues found!`
- Full tests: 358 passed, 0 failed.
- Web build: `Built B:\build\web` (exit 0); WebAssembly dry run also succeeded.

## Requirement checks

- Boss roster contains unique IDs for Fallen General, Plague Magistrate, and
  Masked Executioner.
- Every boss has three distinct pattern kinds and warning windows of at least
  0.60 seconds before execution.
- Fallen General keeps the tuned 900-health baseline and one health-gated
  summon at 40% health.
- Per-boss enrage thresholds and movement/pattern multipliers are asserted.
- Moonlit Office can select Fallen General or Masked Executioner; Plague Market
  selects Plague Magistrate.
- New bosses have no sprite dependency and render through the existing
  geometric enemy and attack-warning fallbacks.

## Remaining risks

- Pattern damage and enrage timings have automated contract coverage but still
  need device playtesting for perceived fairness and five-minute-build DPS.
- The two Moonlit Office bosses use a 60/40 run roll; telemetry should confirm
  that the rarer Masked Executioner is encountered often enough in practice.
