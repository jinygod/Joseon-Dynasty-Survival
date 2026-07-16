# Sixteen Augment Roster Verification

- Branch: `codex/sixteen-augment-roster`
- Date: 2026-07-16
- Base commit for this completion task: `ada1710`
- Feature commits: `ad0342d`, `981c3ba`, `4f48ac0`, `ada1710`
- Scope: `CNT-005`, `CNT-006`

## Regression coverage

- Existing schema-2 saves union their stored augment IDs with every current
  `startsUnlocked` augment. The regression proves the newly starting
  `ironArmorTraining`, `scholarInsight`, `bloodOath`, and `ghostStep` IDs are
  restored while locked `lastStand` remains locked.
- Run-summary unlock labels continue to resolve through
  `augmentDefinitions`; `bloodOath` renders as `피의 맹세` without a manual
  new-ID label branch.
- Both regressions passed against the existing generic implementation, so no
  production save or label-lookup code changed and the schema remains version
  `2`.

## Successful checks

1. Targeted save and summary regression suite

   ```powershell
   $env:TEMP='C:\codex-temp'; $env:TMP='C:\codex-temp'; & 'S:\bin\flutter.bat' test test/game/save_system_test.dart test/game/run_summary_progression_test.dart
   ```

   Result: `28/28` tests passed.

2. Complete focused augment suite

   ```powershell
   $env:TEMP='C:\codex-temp'; $env:TMP='C:\codex-temp'; & 'S:\bin\flutter.bat' test test/game/content_definitions_test.dart test/game/augment_effect_resolver_test.dart test/game/level_up_system_test.dart test/game/run_progression_system_test.dart test/game/pixel_survivor_game_loop_test.dart test/game/save_system_test.dart test/game/run_summary_progression_test.dart
   ```

   Result: `76/76` tests passed.

3. Static analysis

   ```powershell
   $env:TEMP='C:\codex-temp'; $env:TMP='C:\codex-temp'; & 'S:\bin\flutter.bat' analyze
   ```

   Result: `No issues found!` (`0` analyzer issues).

4. Full test suite

   ```powershell
   $env:TEMP='C:\codex-temp'; $env:TMP='C:\codex-temp'; & 'S:\bin\flutter.bat' test
   ```

   Result: `310/310` tests passed.

## Environment note

The Flutter wrapper printed `The network path was not found.` after successful
test completion. Every command returned exit code `0`, and each test command
had already reported `All tests passed!`; this is non-blocking wrapper cleanup
noise rather than a test failure.
