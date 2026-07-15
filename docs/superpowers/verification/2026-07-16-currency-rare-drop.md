# Currency and Rare Drop Verification

- Branch: `codex/lobby-meta-save-foundation`
- Feature commits: `a1c1e6e`, `c4dc298`, `09b1c61`
- Date: 2026-07-16

## Successful checks

- `dart analyze`
  - Result: `No issues found!`
- `git diff --check`
  - Result: no whitespace errors
- `$env:TEMP='C:\codex-temp'; $env:TMP='C:\codex-temp'; flutter test --concurrency=2`
  - Result: `300` tests passed.
- `C:\codex-flutter-sdk\bin\flutter.bat build web`
  - Result: `√ Built build\web`
  - Wasm dry run also succeeded.
- `$env:PUB_CACHE='C:\codex-pub-cache'; $env:ANDROID_HOME='C:\codex-android-sdk'; C:\codex-flutter-sdk\bin\flutter.bat build apk --debug`
  - Result: `√ Built build\app\outputs\flutter-apk\app-debug.apk`

## Flutter tester resolution

Windows Error Reporting showed `flutter_tester.exe` terminating before the
test suite loaded with `0xc0000409` / `FAST_FAIL_INVALID_ARG`. The executable
path and software rendering settings were ruled out independently. Verbose
test output showed that the compiled test dill and font configuration were
still created below the Korean user temp path.

- Root cause: Flutter 3.44.4's Windows test shell crashes when its generated
  test inputs are supplied through the non-ASCII user temp path.
- Fix: created `C:\codex-temp` and set the user-level `TEMP` and `TMP`
  environment variables to that path.
- Confirmation: the smallest reproduction passed `3/3`, the reward-focused
  suite passed `30/30`, and the complete suite passed `300/300`.

The first successful full run exposed seven previously hidden test failures.
They were resolved by using the existing combat-effect atlas for spirit jade,
adding a safe lobby background fallback, separating the character label from
the record label, and initializing SharedPreferences in the async lobby test.

## Tool path notes

- Direct Web build through the Korean Flutter SDK path reached application compilation and Wasm validation, then `impellerc` crashed while compiling `ink_sparkle.frag`.
- Re-running through the English junction `C:\codex-flutter-sdk` succeeded.
- Android's native `jni` dependency similarly required `C:\codex-android-sdk` and the English Pub cache to keep NDK/CMake paths ASCII-only.
