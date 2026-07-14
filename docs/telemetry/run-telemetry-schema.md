# Run telemetry JSON schema

Run telemetry is local playtest data. It is separate from `SaveState`, does not affect unlock progression, and is not uploaded to a server.

## Schema 1

| Field | JSON type | Meaning |
| --- | --- | --- |
| `schemaVersion` | integer | Exact telemetry schema version; currently `1`. |
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
| `feedback` | object or null | Fun 1–5, difficulty 1–5, retry intent, and an optional comment up to 200 characters. |

Core fields through `weaponKillCounts` are required. Extended playtest fields are backward-compatible additions: absent maps/lists decode empty, absent damage decodes to zero, and absent nullable fields decode to null. Unknown or malformed schemas throw `FormatException`; the telemetry repository boundary isolates that failure from progression saving and the result screen.

Feedback is local-only and must not contain personal information. It is added to the matching stored `runId` after the tester submits the result-screen form.
