# Local Playtest Checklist

This guide is for a Windows customer playtest of Joseon Dynasty Survival.

## Current Test Scope

- Automated validation is available with `flutter test`.
- A web build is available with `flutter build web`.
- `flutter run -d chrome` may hit a Flutter shader compilation issue when the
  Flutter SDK is loaded from a Korean user path. Use the ASCII `subst F:`
  mapping below before trying Chrome.

## Stable Windows Procedure

Open PowerShell and run:

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

If `F:` or `P:` is already in use, choose another unused ASCII drive letter and
update the commands consistently.

## Android Preparation

Android builds can be prepared on Windows. Install and configure:

- Android Studio
- Android SDK
- Android emulator, or a physical Android device with USB debugging enabled

Run `flutter doctor` and resolve Android toolchain warnings before relying on
Android test results.

## iOS Preparation

iOS builds require a MacBook or other Mac with Xcode installed. Clone the same
GitHub branch on the Mac, then use the same Flutter version as the Windows
environment before building.

## Customer Checklist

1. Pull the latest repository changes:

   ```powershell
   git pull --ff-only
   ```

2. Confirm the expected branch:

   ```powershell
   git branch --show-current
   ```

3. Run the stable Windows procedure above.
4. If anything fails, share the full command output and any generated Flutter
   log files.
