# Enemy and Elite Roster Verification

- Branch: `codex/enemy-elite-roster`
- Date: 2026-07-16
- Scope: `CNT-007`, `CNT-008`
- Feature commits: `cb3955b`, `09c8734`, `2143b65`, `3442c2a`, `439932a`, `1d92f90`

## Implemented contract

- Eight normal enemies, three authored elites, and the existing boss have explicit faction, rank, and behavior profile data.
- Normal and elite wave pools are selected independently; an empty elite pool safely falls back to an unscaled normal request.
- Telegraphs lock direction or area before activation. Enemy projectiles were not introduced.
- Poison zones are capped at 12 and non-poison enemy attack effects at 24.
- Haste and slow auras select the strongest in-range value without stacking.
- Unique elite kills continue through the existing `eliteKills`, coin, and spirit-jade reward paths.

## Successful checks

1. Focused roster, wave, behavior, hazard, component, loop, balance, and reward suites passed during each TDD cycle.
2. `C:\codex-flutter-sdk\bin\cache\dart-sdk\bin\dart.exe analyze`: `No issues found!`
3. Full Flutter suite with ASCII temp path: `336/336` tests passed.
4. `flutter build web`: built `build\web`; Wasm dry run succeeded.
5. Android debug build from the ASCII `R:` worktree mapping: built `R:\build\app\outputs\flutter-apk\app-debug.apk`.
6. `git diff --check`: no whitespace errors.

## Windows environment note

Flutter 3.44.4 could not create its built-in Material shader outputs in a clean Unicode worktree. The two generated shader artifacts were copied from the already verified baseline build into the ignored worktree `build/` cache. Tests then passed without source changes. Android Gradle also rejects Unicode project paths, so the same worktree was exposed as temporary drive `R:` for the APK build; `kotlin.incremental=false` already prevents cross-drive Kotlin cache relativization errors.
