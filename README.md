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

On this Windows machine, Flutter tooling is more reliable when run through ASCII
`subst` paths because the Flutter SDK and workspace may be under Korean paths.
`flutter run -d chrome` can still hit shader compilation issues unless the SDK is
exposed through an ASCII path first.
