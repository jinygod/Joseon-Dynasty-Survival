# Content Integrity and Build Viability Design

## Goal

CNT-015 must turn the shipped content roster into one deterministic integrity report. The report covers three characters, eight five-level weapons, sixteen augments, eight normal enemies, three elites, two stages, three bosses, and fifteen unlock goals. CNT-016 must additionally prove that three distinct, playable builds can be reached and levelled through the production progression and level-up rules.

## Architecture

Add `lib/game/content/content_integrity.dart` as a pure validation module. It reads immutable definition collections and returns a `ContentIntegrityReport` containing stable, human-readable issue strings; it performs no file I/O and is not called during game boot. Tests and future development diagnostics may call it explicitly.

The validator owns cross-catalog checks that individual definition validators cannot express cleanly:

- exact roster cardinalities and unique IDs;
- character starting-weapon references;
- one five-entry level table per weapon and positive, finite level tuning;
- augment effect validity;
- normal, elite, and boss rank counts;
- stage-to-wave coverage, continuous stage wave rosters, valid enemy ranks, and stage boss reachability;
- unique unlock goals, valid single rewards, and exactly-once coverage of every non-starting character, weapon, augment, and stage;
- complete image-catalog key coverage with safe bundled paths;
- complete audio-cue mappings with channel-consistent paths.

Existing specialized enemy, wave, and boss validators remain the source of detailed tuning diagnostics and are included in the aggregate report.

## Asset and Audio Contract

Every roster item has an `AssetCatalog` entry. Because final bespoke art is intentionally incomplete, missing art slots resolve to an already bundled replaceable atlas or compatible placeholder rather than a nonexistent path. The integrity validator checks key coverage, safe relative paths, approved image suffixes, and a caller-provided set of bundled image paths; the default production report can therefore stay pure while tests supply paths discovered from the repository.

Every `AudioCue` must have exactly one `AudioAssetCatalog` definition. Music cues must use `audio/music/`, UI cues `audio/ui/`, and all other cues `audio/sfx/`. Tests additionally verify that referenced files exist and their directories are registered by `pubspec.yaml`.

## Minimum Valid Builds

The build viability test begins from `SaveState.defaults()`, advances a deterministic fully-qualified progression snapshot through `ProgressionSystem.evaluate`, and confirms all selected character, weapon, augment, and stage IDs are genuinely unlocked. It then drives `LevelUpSystem.choices` repeatedly with fixed seeds and applies only offered choices until each target weapon and augment reaches its requested level. `WeaponSystem.upgrade` independently confirms production weapon caps and unlock gating.

The three build roles are:

1. **Frontline control**: Rookie Constable with max-level hwando and jangseung ward plus defensive/sustain augments.
2. **Ranged focus**: Mountain Hunter with max-level gakgung and singijeon plus attack-speed and critical support.
3. **Area attrition**: Exorcist Dosa with max-level talisman and frost flask plus magic/size or acquisition support.

Role assertions derive combat signatures from weapon definitions and level-five tuning (range, projectile/chain behavior, knockback, persistent duration, and elements). They do not pass by comparing three hard-coded ID lists alone.

## Error Handling and Determinism

Validation accumulates all issues instead of throwing on the first problem. Issue order follows catalog order so CI output is stable. Build construction uses fixed random seeds and a bounded selection loop; inability to receive or apply a required production choice is a test failure with the missing ID and current levels.

## Verification

TDD requires an observed RED failure before production validation code. Focused tests cover the aggregate report, malformed injected catalogs, repository asset/audio viability, and all three rule-driven builds. Final verification runs formatting, static analysis, the focused suite, the full Flutter suite, and a web build from ASCII-mapped paths. `docs/master-development-todo.md` and unrelated app, settings, or QA files remain untouched.
