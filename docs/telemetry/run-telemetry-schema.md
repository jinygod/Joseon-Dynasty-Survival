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

All fields are required in schema 1. Unknown or malformed schemas throw `FormatException`; the later telemetry repository boundary must isolate that failure from progression saving and the result screen. Future tasks extend this model with weapon damage, choice history, received damage, and optional playtest feedback.
