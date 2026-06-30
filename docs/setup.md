# Development Setup

## Flutter SDK

Flutter for Windows stable was installed outside the repository:

```powershell
$env:USERPROFILE\source\flutter
```

For a new PowerShell session, expose Flutter with:

```powershell
$env:Path = "$env:USERPROFILE\source\flutter\bin;$env:Path"
flutter --version
flutter doctor
```

If Flutter web run/build crashes while compiling `ink_sparkle.frag`, expose the
Flutter SDK through an ASCII drive letter before running Flutter commands:

```powershell
subst F: "$env:USERPROFILE\source\flutter"
$env:Path = "F:\bin;$env:Path"
```

The workspace path also contains Korean characters. For the most reliable local
test/build commands on this Windows machine, map both the Flutter SDK and the
worktree to ASCII drive letters, and use an ASCII temp directory:

```powershell
New-Item -ItemType Directory -Force -Path C:\codex-tmp | Out-Null
$env:TEMP = "C:\codex-tmp"
$env:TMP = "C:\codex-tmp"

subst F: "$env:USERPROFILE\source\flutter"
$env:Path = "F:\bin;$env:Path"

subst P: "C:\Users\전성진\Documents\뱀서라이크게임\.worktrees\pixel-survivor-mvp"
Push-Location P:\

flutter pub get
dart analyze
flutter test
flutter build web

Pop-Location
subst P: /D
subst F: /D
```

Current local test coverage:

- `flutter test` can run the automated test suite.
- `flutter build web` can produce a web build.
- `flutter run -d chrome` may fail during shader compilation when the Flutter
  SDK is accessed through a Korean user path. Use the `subst F:` SDK mapping
  above before attempting Chrome runs.

Verified on 2026-06-30:

- Flutter 3.44.4 stable
- Dart 3.12.2

`flutter doctor` runs successfully. Current non-blocking warnings:

- Android SDK is not installed or not configured.
- Visual Studio is missing Windows desktop C++ components.

## Mobile Release Notes

The MVP is landscape-first. Flutter should lock runtime orientation with
`SystemChrome.setPreferredOrientations`, and the platform projects should also
declare landscape support for Android and iOS.

Android builds can be prepared on Windows after Android Studio, the Android SDK,
an Android emulator or USB debugging on a physical device, and release signing
keys are configured. Resolve Android toolchain issues reported by
`flutter doctor` before treating Android tests as ready.

iOS App Store and TestFlight builds require a MacBook or other Mac with Xcode;
Docker does not replace that requirement. For repeatable iOS builds, clone the
same GitHub branch on the Mac and match the Flutter version used on Windows.

For a customer-facing local checklist, see `docs/testing/local-playtest.md`.
