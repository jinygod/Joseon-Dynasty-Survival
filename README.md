# Joseon Dynasty Survival

Joseon Dynasty Survival is a Flutter + Flame mobile auto-battler survival
roguelite with a Joseon folk-fantasy theme.

The MVP is landscape-first and focuses on short survival runs, unlockable
weapons and augments, AI-generated pixel art, and a progression path that can
later support same-device co-op.

## Development

Flutter is installed outside this repository. See `docs/setup.md` for the local
PATH setup and mobile release notes.

For a customer-ready Windows playtest checklist, see
`docs/testing/local-playtest.md`.

Useful commands:

```powershell
$env:Path = "$env:USERPROFILE\source\flutter\bin;$env:Path"
flutter pub get
dart analyze
flutter test
flutter build web
```

Run the complete local release gate from PowerShell with:

```powershell
.\tool\release_check.ps1
```

Add `-IncludeAndroid` when the Android SDK is installed and configured. The
script automatically maps the Flutter SDK and repository to temporary ASCII
drive letters on Windows when either path contains non-ASCII characters.

For changes that touch Supabase, authentication, cloud save, or Google Play
billing, run the stricter backend gate:

```powershell
.\tool\backend_check.ps1
```

It adds pinned Deno checks and local Supabase pgTAP/database lint, then always
builds web and an Android debug APK. Docker is mandatory; an unavailable Docker
daemon is reported as `BLOCKED` with a non-zero exit. Use `-DryRun` to inspect
the ordered gate list without executing tools.

Production setup and release operations are documented in:

- [`docs/backend/android-backend-operations.md`](docs/backend/android-backend-operations.md)
- [`docs/backend/google-play-console-setup.md`](docs/backend/google-play-console-setup.md)

Never commit Supabase service-role/database credentials, Google OAuth secrets,
service-account JSON, Pub/Sub credentials, keystores, or populated env files.

GitHub Actions runs formatting, analysis, all automated tests, a web release
build, and an Android debug APK build for pushes and pull requests.

App and save version rules are documented in `docs/release/versioning.md`.

On this Windows machine, Flutter tooling is more reliable when run through ASCII
`subst` paths because the Flutter SDK and workspace may be under Korean paths.
`flutter run -d chrome` can still hit shader compilation issues unless the SDK is
exposed through an ASCII path first.
