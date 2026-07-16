# Accessibility, Credits, and Migration Design

## Scope

META-005/006/009/010 add non-color status semantics, large-text layout safety, in-app asset/audio attribution, and versionless through schema-v3 migration regression coverage. The master TODO, QA surfaces, and Android files remain unchanged.

## UI Architecture

`AccessibleStatusBadge` is the shared visual contract for a state: every instance carries an icon, explicit Korean label, high-contrast foreground/background pair, and outlined shape. Compendium lock/new states use it instead of color-only copy. Existing records and settings surfaces retain icons and gain wrapping/scroll behavior where fixed rows can overflow.

Large-text tests combine UI scale 1.15 with system text scale 2.0. HUD text is bounded with ellipsis and flexible width; compendium and records cards use Wrap/flexible children and vertical scrolling. The goal is no Flutter layout exception on a 320x568 screen and on the supported landscape HUD.

## Credits and Licenses

`CreditsLedger` is a pure read model that parses the repository's asset and audio CSV ledgers supplied as strings. It exposes normalized credit rows containing runtime path, creator/provider, source URL, license/terms, and status. `CreditsLicensesScreen` renders separate bundled art and audio sections and falls back to a Korean empty/error state. Settings links to the screen and injects ledger text through `DefaultAssetBundle`; tests may inject a model directly.

## Migration Contract

Fixture-driven tests load versionless, schema 1, 2, and 3 payloads through `SaveState.fromJson`. Every fixture asserts the fields available in that generation survive: unlock sets, wallet, selected content, counters, character victory records, and compendium seen records. Unified and legacy settings are loaded alongside the save fixture through `GameSettingsRepository`; no schema bump is introduced.

## Verification

TDD records RED for missing badge/credits APIs, large-text overflow, and incomplete migration assertions. Final gates are focused tests, full analyze/test, release web build, formatting, and `git diff --check`.
