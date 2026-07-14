# Versioning Policy

## App version

The project uses `MAJOR.MINOR.PATCH+BUILD` in `pubspec.yaml`.

- `MAJOR`: incompatible public release or save-policy change requiring an explicit product decision.
- `MINOR`: backward-compatible content or feature release.
- `PATCH`: backward-compatible bug fix or balance release.
- `BUILD`: monotonically increasing Google Play build number for every uploaded artifact.

The current alpha line is `0.1.x`. Android 1.0 starts at `1.0.0` only after every release gate in `docs/master-development-todo.md` passes.

## Save schema

`SaveState.currentSchemaVersion` is independent from the app version.

- Schema `0`: versionless alpha saves.
- Schema `1`: first explicit schema; current.
- Missing schema values migrate from schema 0 to schema 1.
- Negative, malformed, or future schema values load defaults without crashing.
- A schema increment requires migration tests from every previously shipped schema.
- The shared-preferences key remains `save_state` until a reviewed migration changes it.

## Release checklist

1. Increment the app build number for every uploaded APK or AAB.
2. Increment PATCH, MINOR, or MAJOR according to the rules above.
3. Add save migration tests before incrementing `SaveState.currentSchemaVersion`.
4. Run `.\tool\release_check.ps1`.
5. Run `.\tool\release_check.ps1 -IncludeAndroid` on an Android-ready machine.
6. Record user-visible changes in the release notes before upload.
