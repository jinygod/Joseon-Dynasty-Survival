# Real Audio Playback Design

## Goal

Make the current Chrome and Android builds audibly playable while keeping every temporary sound replaceable without changing gameplay code.

## Approved direction

- Use `flame_audio` for Web and Android playback.
- Use temporary CC0 Kenney audio with exact source and license records.
- Keep images and audio independent; this change does not alter the visual style.
- Respect persisted music and effects volumes.
- Begin playback only after a player gesture on Web; the first menu/start interaction unlocks audio.
- Map typed `AudioCue` values to asset paths in one catalog so final audio can be swapped centrally.

## Runtime architecture

`PixelSurvivorApp` owns one settings controller and one `GameAudioService`. The service uses `FlameAudioBackend` in production and remains injectable in widget/game tests. Screens receive the service explicitly. `PixelSurvivorGame` emits typed cues through a callback and never imports a platform audio player.

Music transitions stop the previous track before starting the next. Short effects use pooled/cached Flame playback where useful, and all active players are paused, resumed, stopped, and disposed through the existing backend contract.

## Cue coverage

- Music: battle, boss, victory, defeat; menu remains gesture-gated and starts after the first menu interaction.
- Weapons: hwando, bow, talisman, bomb.
- Combat: player hit, critical hit, enemy death, experience pickup, level up, boss warning.
- UI: confirm and back on the main navigation path.

## Temporary asset policy

Assets live below `assets/audio/{music,sfx,ui}`. `AudioAssetCatalog` is the only cue-to-path mapping. `docs/assets/audio-rights-ledger.csv` records source page, creator, CC0 license, original filename, local path, and temporary status. Replacements preserve the local path or update only the catalog.

## Verification

Unit tests cover total cue mapping, music replacement, backend adapter commands, weapon cue emission, and game/UI cue emission. The release gate runs formatting, analysis, all Flutter tests, Web build, and Android build. The static Chrome build is refreshed for a manual audible checkpoint.
