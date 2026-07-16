# Three Boss Roster Design

## Goal

Complete `CNT-011` and `CNT-012` with three playable bosses. Every boss has
three named combat patterns, a readable warning before damage, and an explicit
enrage rule. The two new bosses must be selected by real stage runs without
requiring new image assets.

## Chosen approach

Use a data-driven boss roster in `lib/game/content/boss_definitions.dart`.
`BossDefinition` owns the enemy stats, ordered pattern list, enrage timing and
enrage multipliers. One `BossController` executes every roster through the same
approach -> warning -> attack -> recovery state machine. `BossComponent`
translates controller actions into movement, delayed `AreaAttackComponent`
attacks, summoning, and fallback telegraphs.

This is preferred over adding boss-specific branches to the current controller,
which would mix timing and combat rules, and over three component subclasses,
which would duplicate state-machine behavior for a roster of this size.

## Stage selection

- `moonlit_abandoned_office`: a run roll below `0.60` selects the existing
  Fallen General; a roll at or above `0.60` selects the Masked Executioner.
- `plague_market`: selects the Plague Magistrate.
- Unknown stage IDs fall back to the Fallen General.
- Tests inject the roll so every selection path is deterministic. Production
  runs use the existing run random source.

## Boss specifications

### Fallen General (`fallen_general`)

- Stats remain 900 health, 26 speed, 20 contact damage, 20 experience.
- Cavalry charge: 0.75 second line warning, then a 0.35 second charge.
- Commander's sweep: 0.60 second 90-degree cone warning, then 1.5x damage in a
  130-unit cone.
- Call vengeful spirits: a 0.70 second warning, then summon up to three
  `vengeful_spirit` enemies, once per encounter when health is at or below 40%.
- Enrage at 25 seconds: movement and pattern clock become 1.25x.

### Plague Magistrate (`plague_magistrate`)

- 820 health, 30 speed, 18 contact damage, 22 experience.
- Pestilent decree: 0.80 second full-circle warning, then 1.2x damage in a
  145-unit radius.
- Infected rush: 0.70 second line warning, then a 0.30 second charge.
- Carrion sentence: 0.65 second 55-degree cone warning, then 1.4x damage in a
  175-unit cone.
- Enrage at 22 seconds: movement and pattern clock become 1.30x.

### Masked Executioner (`masked_executioner`)

- 980 health, 24 speed, 22 contact damage, 24 experience.
- Headsman's rush: 0.65 second line warning, then a 0.40 second charge.
- Execution corridor: 0.70 second narrow 28-degree warning, then 1.8x damage
  along a 210-unit corridor.
- Blood ring: 0.75 second full-circle warning, then 1.35x damage in a 120-unit
  radius.
- Enrage at 20 seconds: movement and pattern clock become 1.35x.

## Runtime and warning behavior

The controller emits `warning` and `execute` actions carrying the selected
pattern. Area warnings are represented by delayed boss `AreaAttackComponent`s;
the existing fallback renderer draws their red circle or sector even when no
sprite is available. Charge warnings are rendered by `BossComponent` as a
gold-to-red directional line for the full warning duration. Damage is applied
only after the declared warning window. Summoning respects the current enemy
cap.

Negative or non-finite `dt` contributes no state time. A defeated boss emits no
new actions. Large ticks are consumed in bounded steps so warnings cannot be
skipped and action ordering remains deterministic.

## Testing

- Content tests assert three unique bosses, three distinct patterns per boss,
  valid warning windows, and exact enrage data.
- Controller tests observe warning-before-execute ordering for every pattern,
  the health-gated one-time summon, defeat behavior, and each enrage threshold.
- Component tests assert area attacks, charges, summons, and visible charge
  warning state are produced from real definitions.
- Game-loop tests inject boss selection rolls and prove the existing and both
  new bosses can be spawned by their actual stages.

## Scope

No unlock, meta-progression, settings, stage UI, new sprite, or audio work is
included. Existing sprite loading remains only for the Fallen General; both new
bosses use the current geometric fallback art.
