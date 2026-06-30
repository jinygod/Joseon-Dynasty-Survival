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

Verified on 2026-06-30:

- Flutter 3.44.4 stable
- Dart 3.12.2

`flutter doctor` runs successfully. Current non-blocking warnings:

- Android SDK is not installed or not configured.
- Visual Studio is missing Windows desktop C++ components.

## Mobile Release Notes

The MVP is landscape-first. Flutter should lock runtime orientation with `SystemChrome.setPreferredOrientations`, and the platform projects should also declare landscape support for Android and iOS.

Android builds can be prepared on Windows after Android Studio, the Android SDK, and release signing keys are configured. iOS App Store and TestFlight builds require a Mac with Xcode; Docker does not replace that requirement. For repeatable mobile releases, keep the Flutter version fixed and synchronize GitHub branches before building.
