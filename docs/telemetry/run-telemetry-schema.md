# Run telemetry JSON schema

Run telemetry is local playtest data. It is separate from `SaveState`, does not affect unlock progression, and is not uploaded to a server.

## Schema 2

| Field | JSON type | Meaning |
| --- | --- | --- |
| `schemaVersion` | integer | Exact telemetry schema version; currently `2`. |
| `runId` | string | Unique identifier for one run. |
| `appVersion` | string | App version and build number used for the run. |
| `startedAtUtc` | ISO-8601 string | Run start time normalized to UTC. |
| `endedAtUtc` | ISO-8601 string | Run end time normalized to UTC. |
| `outcome` | string | `inProgress`, `victory`, or `defeat`. |
| `survivalSeconds` | integer | Whole seconds survived. |
| `level` | integer | Final player level. |
| `kills` | integer | Total enemies defeated. |
| `bossDefeated` | boolean | Whether the boss was defeated. |
| `weaponKillCounts` | object | Weapon ID to kill count map. |
| `weaponDamageTotals` | object | Weapon ID to effective damage total map. |
| `choices` | array | Ordered weapon/augment selections with time and selected level. |
| `totalDamageTaken` | number | Effective player health lost during the run. |
| `lastDamageSource` | string or null | Enemy/content ID responsible for the latest damage. |
| `deathAtSeconds` | integer or null | First lethal-damage time, or null for a surviving player. |
| `feedback` | object or null | Fun and difficulty ratings, retry intent, and an optional comment up to 200 characters. |
| `combatMetrics` | object | Required immutable combat-playtest measurements described below. |

Every schema 2 field is required, including nullable fields. Unknown versions and malformed or incomplete schema 2 payloads throw `FormatException`; the telemetry repository boundary isolates that failure from progression saving and the result screen.

### `combatMetrics`

| Field | JSON type | Meaning |
| --- | --- | --- |
| `weaponOfferCounts` | object | Weapon ID to number of generated level-up offers. |
| `weaponSelectionCounts` | object | Weapon ID to number of selected weapon levels. |
| `weaponLevelTimes` | object | Weapon ID to an object mapping level numbers to first selection time in seconds. |
| `firstMasterAtSeconds` | object | Weapon ID to first mastery attack activation time. |
| `masterKillsInTenSeconds` | object | Weapon ID to kills attributed during the ten seconds following a mastery activation. |
| `firstSynergyAtSeconds` | object | Synergy ID to first effective-damage time. |
| `synergyDamageTotals` | object | Synergy ID to total effective damage. |
| `enemyRoleDamageToPlayer` | object | Enemy behavior-profile ID to effective player damage. |
| `enemyRoleDeathCauses` | object | Enemy behavior-profile ID to lethal-hit count. |
| `averageEnemyCount` | number | Mean live-enemy count sampled once per game update. |
| `maxEnemyCount` | integer | Maximum sampled live-enemy count. |
| `lateAverageFps` | number | Mean FPS from raw frame durations at or after 240 seconds. |
| `lateMinFps` | number | Minimum FPS from raw frame durations at or after 240 seconds. |
| `masteredWeaponIds` | array | Weapon IDs that activated a mastery attack. |
| `isRepeatRun` | boolean | Whether the playtest session marked the run as a repeat run. Task 10 defaults this to false; session injection is handled separately. |

Frame durations are recorded before combat simulation clamps `dt`, so late FPS represents delivered frame pacing rather than the capped simulation step. Map keys and mastered weapon IDs are written in stable ascending order.

## Schema 1 compatibility

Schema 1 remains readable. Its core fields through `weaponKillCounts` are required. Its extended fields are backward-compatible additions: absent maps/lists decode empty, absent damage decodes to zero, and absent nullable fields decode to null. Because schema 1 has no `combatMetrics`, it always loads as `CombatPlaytestMetrics.empty`.

Feedback is local-only and must not contain personal information. It is added to the matching stored `runId` after the tester submits the result-screen form.
