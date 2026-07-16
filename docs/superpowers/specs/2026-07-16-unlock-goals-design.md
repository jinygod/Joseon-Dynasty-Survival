# Unlock Goals Design

## Goal

Ship exactly 15 persistent goals that unlock the release roster through normal play: two non-starting characters, six non-starting weapons, six non-starting augments, and the second stage.

## Content contract

Existing goal IDs remain stable. `reach_level_10` keeps the `jangseung_ward` reward but no longer also grants `rapid_reload`; a new early-level goal grants that augment. The complete mapping is:

| Goal ID | Metric | Threshold | Reward |
| --- | --- | ---: | --- |
| `survive_3_minutes` | best survival | 180 | `talisman_throw` |
| `defeat_300_enemies` | total kills | 300 | `thunder_crash_bomb` |
| `reach_level_10` | best run level | 10 | `jangseung_ward` |
| `defeat_fallen_general` | total boss defeats | 1 | `exorcist_dosa` |
| `survive_5_minutes` | best survival | 300 | `goblin_fire` |
| `unlock_three_weapons` | unlocked weapon count | 3 | `powder_mastery` |
| `defeat_500_enemies` | total kills | 500 | `singijeon_volley` |
| `low_health_win` | low-health victories | 1 | `last_stand` |
| `defeat_two_bosses` | total boss defeats | 2 | `frost_flask` |
| `unlock_six_weapons` | unlocked weapon count | 6 | `wind_thunder_fan` |
| `reach_level_5` | best run level | 5 | `rapid_reload` |
| `defeat_50_elites` | total elite kills | 50 | `ritual_shortcut` |
| `reach_level_15` | best run level | 15 | `heavy_strike` |
| `defeat_three_bosses` | total boss defeats | 3 | `mountain_hunter` |
| `win_first_run` | total victories | 1 | `plague_market` |

Every goal has exactly one reward and every non-starting content ID has exactly one goal. The first stage, rookie constable, two starting weapons, and all `startsUnlocked` augments remain immediately available.

## Evaluation and API

Run settlement updates cumulative kills, elite kills, boss defeats, victories, low-health victories, best survival, and best level before evaluating goals. Evaluation is monotonic and idempotent: completed IDs and unlocked IDs are sets, so replaying a run or evaluating an already-complete save cannot duplicate a reward or remove progress.

`MetaProgressionService.loadUnlockProgress()` returns all 15 goals in definition order with current value, threshold, clamped 0..1 fraction, completion state, and typed reward metadata. UI is out of scope; this API is the UI-ready boundary.

## Save compatibility and safety

Schema v3 adds `unlockedStageIds`, `totalEliteKills`, and `victoryCount`. Versionless, v1, and v2 saves migrate in memory, preserve recognized unlocks/counters/completed goals, and initialize new fields safely. Previously granted `rapid_reload` remains in the saved unlock set even though its goal mapping is split.

Deserialization accepts only known character, weapon, augment, stage, and goal IDs, unions required starting content, rejects negative/non-integer counters, validates selections, and falls back to defaults for malformed JSON or unsupported schema versions. Dynamic claimed pickup/reward IDs remain string-filtered rather than catalog-filtered because they are generated per run.

## Verification

Tests prove the 15-goal/one-reward/full-roster contract, run and cumulative evaluation, progress reporting, idempotence, schema migration, round-trip persistence, and damaged-data sanitization. Final verification uses the repository ASCII-path release check for format, analysis, all tests, and Web build.
