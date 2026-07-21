# Final integration fixes report

Date: 2026-07-22

## Scope completed

- Hwando level 3 now freezes two opposite diagonal sector directions. Level 6 freezes a targeted opener plus genuinely opposite left/right half-circle directions. Hit geometry and `AttackEffectComponent` both consume those same immutable `AttackInstance` values; geometry and pixel-render contract regressions cover the distinction.
- Level 3+ talismans now create anchored, readable seal marks. Executor-reported transfers create a 0.2-second source-to-target cue only; neither presentation component owns damage geometry. Seal marks are bounded by `TalismanExecutor.maxAttachedSeals` (24), and transfer cues share the existing combat-effect budget. Live-loop tests cover attach, transfer, stale-target cleanup, and cap rejection.
- Tank enemies render an explicit shield arc aligned to their frozen facing. A reduced frontal hit emits a distinct short shield-block effect, while explosion and synergy traits still bypass defense and do not emit block feedback. Normal, boss-charge, boss-summon, cone, and radial warnings render through priority-120 warning surfaces; enemy bodies remain at their default priority below attack effects.
- Selecting level 6 records mastery achievement time and mastered status immediately. The first actual mastery activation is retained separately inside `CombatPlaytestTracker` and alone starts the ten-second kill window. Schema 2 field names and encoding remain unchanged; `docs/telemetry/run-telemetry-schema.md` documents the exact semantics and legacy activation fallback. An aggregate regression covers a run ending after selection but before the next weapon fire.

## TDD evidence

- Hwando regressions failed because L3/L6 stage directions and rendered pixels were identical, then passed after per-stage immutable direction offsets were added.
- Talisman executor and presentation regressions failed for missing transfer output/components, then passed after bounded runtime presentation was integrated.
- Shield/overlay regressions failed for missing shield state, block feedback, and warning overlay classes, then passed after the dedicated presentation path was added.
- Telemetry regressions failed with activation times (`191`/`200`) instead of selection time (`190`) and an empty end-before-fire aggregate, then passed after achievement/use timestamps were separated.
- The first combined focused gate found two integration regressions: a stale raw-aim assertion and child removal during Flame iteration. The assertion now checks stage offsets, and game-owned post-update cleanup removes warning/attachment owners safely.

## Verification

- Focused Flutter gate: 174 tests passed across attack geometry, hwando, talisman executor/components, weapon system, enemy/boss presentation, tracker/schema/export, and the live game loop.
- `flutter analyze --no-pub`: `No issues found!` from an ASCII non-root junction with the existing ASCII Flutter SDK mapping. The temporary junction was removed afterward.
- `git diff --check`: clean before report generation; rerun before commit.

Per instruction, no manual checklist cells were filled, no long full build/test gates were rerun, and nothing was merged or pushed.
