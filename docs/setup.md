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
