# Character Roster and Horde Ramp Design

## Goal

Complete the first three-character playtest roster and replace the sparse, easy wave pacing with a dense horde that becomes continuously harder throughout the five-minute run.

This slice covers `CNT-001`, the character-side implementation needed for `CNT-002`, and a targeted pre-playtest wave rebalance. Audio polishing and final image replacement remain outside this scope.

## Approved direction

- Add the 산길 사냥꾼 as the third character, starting with 각궁 사격.
- Make all three current characters immediately selectable during development.
- Keep one central roster-availability policy so release unlock rules can be restored without changing the selection UI.
- Use a higher baseline enemy count plus a time-based continuous pressure ramp.
- Do not add a separate grace period or a player-strength-based adaptive difficulty system.
- Preserve the per-frame spawn limit so a large accumulated spawn budget cannot create a single-frame performance spike.

## Character roster

The three characters must have distinct starting weapons, base stats, and passive identities.

| Character | Role | Starting weapon | Base identity | Passive |
| --- | --- | --- | --- | --- |
| 신참 포졸 | 근접 생존형 | 환도 베기 | 105 health, 125 move speed | `순라의 끈기`: incoming contact damage is reduced by 12% |
| 퇴마 도사 | 마법 화력형 | 부적 투척 | 85 health, 115 move speed | `퇴마 서법`: magic-element weapon damage is increased by 15% |
| 산길 사냥꾼 | 기동 원거리형 | 각궁 사격 | 90 health, 140 move speed | `매의 눈`: critical-hit chance is increased by 10 percentage points |

Character passives are typed data on `CharacterDefinition`, not name-based branches in the game loop. The combat calculation reads resolved character modifiers at the authoritative damage or incoming-contact-damage boundary. The selection card shows the passive name and exact effect.

During development, the default and previously saved rosters resolve against the central playtest availability policy and expose all three character IDs. Existing progression data is preserved; opening the roster does not mark unrelated goals complete or delete prior unlock state.

## Continuous horde pressure

Each wave phase keeps its enemy pool and elite identity, but resolves spawn rate and active cap by linear interpolation between the phase's start and end values. This removes one-minute plateaus while keeping the data easy to tune.

| Time | Spawns per second | Active-enemy cap | Group size | Elite chance |
| --- | --- | --- | --- | --- |
| 0:00-1:00 | 1.0 -> 1.4 | 32 -> 40 | 3 | 0% -> 2% |
| 1:00-2:00 | 1.4 -> 1.9 | 40 -> 52 | 3 | 2% -> 4% |
| 2:00-3:00 | 1.9 -> 2.5 | 52 -> 66 | 4 | 4% -> 7% |
| 3:00-4:00 | 2.5 -> 3.2 | 66 -> 80 | 5 | 7% -> 11% |
| 4:00-4:30 | 3.2 -> 4.0 | 80 -> 92 | 6 | 11% -> 15% |
| 4:30-5:30 boss phase | 1.5 -> 2.2 | 48 -> 64 | 4 | 5% -> 8% |

The frame spawn cap remains eight. Spawn requests continue to respect the active cap, and unused budget remains bounded so returning from pause or a slow frame cannot dump an unlimited backlog. Boss spawning remains exactly once at 4:30, while normal enemies continue spawning during the fight.

Enemy health and contact damage are not reduced in this slice: the current build is too easy, and the requested difficulty should come primarily from space pressure and target volume. Spawn positions continue to distribute groups around multiple screen edges so density does not become one unreadable stack.

## Experience and progression pacing

More enemies must not create a runaway level advantage that cancels the new pressure. Recalculate the experience requirement curve from the denser wave data and keep every existing reference profile between 9 and 12 level-ups, inclusive, over five minutes. Enemy experience values remain integers and enemy-specific; the requirement curve is the single balancing lever for this slice.

The three starting weapons remain available through their selected character even if the general weapon-unlock pool changes later. Development-wide character access does not imply that every weapon or augment is globally unlocked.

## Failure handling and compatibility

- An unknown or removed character ID falls back to 신참 포졸 as it does today.
- Missing passive data resolves to neutral modifiers rather than crashing a run.
- Saved character IDs are unioned with the central development roster without overwriting telemetry or progression counters.
- The wave director clamps interpolation progress, spawn rate, active capacity, and accumulated budget to valid non-negative values.
- Asset loading remains on the existing safe fallback path; this feature does not require new final images.

## Verification

- Definition tests require exactly three unique characters, three valid starting weapons, and valid passive descriptions.
- Save and selection tests prove new and existing saves can select all three characters during development.
- Combat tests verify contact-damage reduction, magic-only damage amplification, and the hunter's critical bonus without affecting unrelated damage types.
- Wave boundary tests verify continuous interpolation, monotonic pressure inside every pre-boss phase, and exact phase transitions.
- Twenty fixed-seed five-minute simulations require every normal enemy pool to appear, exactly one boss request, no active-cap violation, no frame above eight spawn requests, and at least 400 total normal-enemy spawns per seed.
- Experience regression keeps the reference profile near 9-12 level-ups despite the larger horde.
- The full release gate runs formatting, static analysis, all Flutter tests, Web build, and Android debug APK build.

## Success criteria

- All three characters can be selected immediately in the current playtest build and feel mechanically distinct.
- Enemy presence is visibly denser from the opening minute and increases continuously with elapsed time.
- The final pre-boss minute is at least twice the opening spawn pressure, with the active-enemy cap rising from 80 to 92 during 4:00-4:30.
- The boss fight retains surrounding enemies, remains readable, and never spawns the boss more than once.
- The denser run does not violate spawn safety limits or inflate the reference level-up count beyond the agreed range.
