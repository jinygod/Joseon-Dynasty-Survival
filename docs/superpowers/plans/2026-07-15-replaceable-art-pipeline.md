# Replaceable Art Pipeline Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every currently used sprite atlas replaceable by a same-contract PNG while keeping missing or broken art from stopping gameplay.

**Architecture:** A pure Dart `SpriteAtlasContract` registry owns paths, frame geometry, transparency requirements, and temporary/approved state. A small shared loader converts image-loading exceptions into `null`; existing renderers retain their procedural fallbacks. Automated tests inspect real PNG headers and registry/catalog consistency without approving any current artwork.

**Tech Stack:** Dart 3.12.2, Flutter 3.44.4, Flame 1.18, `flutter_test`

## Global Constraints

- Current character, monster, boss, effect, and stage artwork remains temporary and is not visually approved by this work.
- Final art direction is cute, chibi-like Joseon folk fantasy with no realistic gore or body horror.
- Runtime art replacement means replacing a local PNG with the same path and atlas geometry for the next build; remote downloads and user mods are out of scope.
- Missing or invalid art must not block game startup or the combat loop.
- `VIS-008` through `VIS-010` remain incomplete until user-reviewed final artwork exists.

---

## File Structure

- Create `lib/game/content/sprite_atlas_contract.dart`: atlas metadata, PNG-header validation, frame bounds, and the current replaceable-atlas registry.
- Create `lib/game/content/safe_asset_loader.dart`: one exception boundary for non-blocking image loads.
- Modify `lib/game/content/asset_catalog.dart`: expose a flattened set of registered runtime paths for consistency checks.
- Modify `lib/game/content/weapon_effect_atlas.dart`: use the shared safe loader.
- Modify `lib/game/content/combat_effect_atlas.dart`: use the shared safe loader.
- Modify `lib/game/components/player_component.dart`: use the shared safe loader and retain procedural rendering when loading returns `null`.
- Modify `lib/game/components/enemy_component.dart`: use the shared safe loader and retain procedural rendering when loading returns `null`.
- Create `test/game/sprite_atlas_contract_test.dart`: contract, catalog, bounds, and real PNG validation.
- Create `test/game/safe_asset_loader_test.dart`: success, silent release fallback, and explicit development diagnostics.
- Modify `docs/master-development-todo.md`: record the changed art approval state and verified `VIS-011`/`VIS-012` evidence.

---

### Task 1: Atlas contract and registry

**Files:**
- Create: `lib/game/content/sprite_atlas_contract.dart`
- Modify: `lib/game/content/asset_catalog.dart`
- Test: `test/game/sprite_atlas_contract_test.dart`

**Interfaces:**
- Consumes: existing `AssetCatalog` runtime paths.
- Produces: `ArtAssetStatus`, `SpriteAtlasContract`, `ReplaceableArtCatalog.atlases`, `ReplaceableArtCatalog.byId`, and `AssetCatalog.allPaths`.

- [x] **Step 1: Write failing metadata and catalog-consistency tests**

```dart
test('replaceable atlases are temporary and registered in AssetCatalog', () {
  expect(ReplaceableArtCatalog.atlases, isNotEmpty);
  for (final contract in ReplaceableArtCatalog.atlases) {
    expect(contract.status, ArtAssetStatus.temporary);
    expect(AssetCatalog.allPaths, contains(contract.runtimePath));
    expect(contract.assetKey, contract.runtimePath.replaceFirst('assets/', ''));
  }
});

test('frame lookup rejects coordinates outside the atlas contract', () {
  const contract = SpriteAtlasContract(
    id: 'sample',
    runtimePath: 'assets/images/sample.png',
    frameWidth: 32,
    frameHeight: 32,
    columns: 4,
    rows: 4,
    requiresTransparency: true,
    status: ArtAssetStatus.temporary,
  );
  expect(() => contract.frameIndex(column: 4, row: 0), throwsRangeError);
  expect(() => contract.frameIndex(column: 0, row: -1), throwsRangeError);
});
```

- [x] **Step 2: Run tests and verify RED**

Run: `flutter test test/game/sprite_atlas_contract_test.dart`

Expected: compilation fails because `sprite_atlas_contract.dart`, `SpriteAtlasContract`, and `AssetCatalog.allPaths` do not exist.

- [x] **Step 3: Implement the minimal contract API and current registry**

```dart
enum ArtAssetStatus { temporary, approved }

class SpriteAtlasContract {
  const SpriteAtlasContract({
    required this.id,
    required this.runtimePath,
    required this.frameWidth,
    required this.frameHeight,
    required this.columns,
    required this.rows,
    required this.requiresTransparency,
    required this.status,
  });

  final String id;
  final String runtimePath;
  final int frameWidth;
  final int frameHeight;
  final int columns;
  final int rows;
  final bool requiresTransparency;
  final ArtAssetStatus status;

  String get assetKey => runtimePath.replaceFirst('assets/', '');
  int get pixelWidth => frameWidth * columns;
  int get pixelHeight => frameHeight * rows;

  int frameIndex({required int column, required int row}) {
    RangeError.checkValidIndex(column, List<void>.filled(columns, null), 'column');
    RangeError.checkValidIndex(row, List<void>.filled(rows, null), 'row');
    return row * columns + column;
  }
}
```

Register the player 4x4/32px sheet, four normal-enemy 4x4 sheets, the boss 4x4/64px sheet, weapon effects 4x4/64px, and combat effects 4x5/64px, all with `ArtAssetStatus.temporary`.

Add `AssetCatalog.allPaths` by flattening the existing category maps into an unmodifiable set literal.

- [x] **Step 4: Run tests and verify GREEN**

Run: `flutter test test/game/sprite_atlas_contract_test.dart`

Expected: metadata and frame-bound tests pass.

- [x] **Step 5: Commit**

```powershell
git add lib/game/content/sprite_atlas_contract.dart lib/game/content/asset_catalog.dart test/game/sprite_atlas_contract_test.dart
git commit -m "feat: define replaceable sprite atlas contracts"
```

### Task 2: Automated PNG contract validation

**Files:**
- Modify: `lib/game/content/sprite_atlas_contract.dart`
- Modify: `test/game/sprite_atlas_contract_test.dart`

**Interfaces:**
- Consumes: `Uint8List` PNG file bytes and `SpriteAtlasContract` geometry.
- Produces: `List<String> validatePngHeader(Uint8List bytes)` with an empty list for valid files and explicit messages for invalid signature, dimensions, or color type.

- [x] **Step 1: Write failing real-file and corrupt-header tests**

```dart
test('every replaceable atlas matches its PNG contract', () {
  for (final contract in ReplaceableArtCatalog.atlases) {
    final file = File(contract.runtimePath);
    expect(file.existsSync(), isTrue, reason: contract.id);
    expect(contract.validatePngHeader(file.readAsBytesSync()), isEmpty,
        reason: contract.id);
  }
});

test('PNG validation reports malformed files without throwing', () {
  final errors = ReplaceableArtCatalog.atlases.first
      .validatePngHeader(Uint8List.fromList([1, 2, 3]));
  expect(errors, contains('invalid PNG signature'));
});
```

- [x] **Step 2: Run tests and verify RED**

Run: `flutter test test/game/sprite_atlas_contract_test.dart`

Expected: compilation fails because `validatePngHeader` does not exist.

- [x] **Step 3: Implement bounded PNG IHDR validation**

```dart
List<String> validatePngHeader(Uint8List bytes) {
  const signature = <int>[137, 80, 78, 71, 13, 10, 26, 10];
  if (bytes.length < 26 ||
      !List.generate(8, (index) => bytes[index]).every(
        (value) => value == signature[List.generate(8, (i) => i)
            .firstWhere((i) => bytes[i] == value, orElse: () => -1)],
      )) {
    return const ['invalid PNG signature'];
  }
  int uint32(int offset) => ByteData.sublistView(bytes)
      .getUint32(offset, Endian.big);
  final errors = <String>[];
  if (uint32(16) != pixelWidth || uint32(20) != pixelHeight) {
    errors.add('expected ${pixelWidth}x$pixelHeight PNG');
  }
  if (requiresTransparency && bytes[25] != 6) {
    errors.add('expected RGBA PNG color type 6');
  }
  return errors;
}
```

Use a direct indexed signature loop in the final implementation so repeated byte values cannot produce a false match.

- [x] **Step 4: Run tests and verify GREEN**

Run: `flutter test test/game/sprite_atlas_contract_test.dart`

Expected: all registered current atlases exist and match exact width, height, and RGBA requirements; malformed input returns a diagnostic instead of throwing.

- [x] **Step 5: Commit**

```powershell
git add lib/game/content/sprite_atlas_contract.dart test/game/sprite_atlas_contract_test.dart
git commit -m "test: validate replaceable atlas PNG contracts"
```

### Task 3: Shared safe asset loading

**Files:**
- Create: `lib/game/content/safe_asset_loader.dart`
- Modify: `lib/game/content/weapon_effect_atlas.dart`
- Modify: `lib/game/content/combat_effect_atlas.dart`
- Modify: `lib/game/components/player_component.dart`
- Modify: `lib/game/components/enemy_component.dart`
- Test: `test/game/safe_asset_loader_test.dart`

**Interfaces:**
- Consumes: `Future<T> Function() load`, diagnostic library name, asset key, and optional diagnostic callback.
- Produces: `Future<T?> SafeAssetLoader.load<T>(...)`; successful values pass through, failures return `null`, development mode reports one `FlutterErrorDetails`.

- [x] **Step 1: Write failing loader behavior tests**

```dart
test('safe loader returns a successfully loaded value', () async {
  final value = await SafeAssetLoader.load<int>(
    load: () async => 7,
    library: 'test',
    assetKey: 'images/test.png',
  );
  expect(value, 7);
});

test('safe loader returns null silently in release-like mode', () async {
  final value = await SafeAssetLoader.load<int>(
    load: () async => throw StateError('missing'),
    library: 'test',
    assetKey: 'images/missing.png',
    reportErrors: false,
  );
  expect(value, isNull);
});

test('safe loader reports one explicit development diagnostic', () async {
  final details = <FlutterErrorDetails>[];
  final value = await SafeAssetLoader.load<int>(
    load: () async => throw StateError('broken'),
    library: 'test',
    assetKey: 'images/broken.png',
    reportErrors: true,
    reportError: details.add,
  );
  expect(value, isNull);
  expect(details, hasLength(1));
  expect(details.single.context.toString(), contains('images/broken.png'));
});
```

- [x] **Step 2: Run tests and verify RED**

Run: `flutter test test/game/safe_asset_loader_test.dart`

Expected: compilation fails because `SafeAssetLoader` does not exist.

- [x] **Step 3: Implement the minimal shared loader**

```dart
abstract final class SafeAssetLoader {
  static Future<T?> load<T>({
    required Future<T> Function() load,
    required String library,
    required String assetKey,
    bool reportErrors = !kReleaseMode,
    void Function(FlutterErrorDetails) reportError = FlutterError.reportError,
  }) async {
    try {
      return await load();
    } catch (error, stackTrace) {
      if (reportErrors) {
        reportError(FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: library,
          context: ErrorDescription('loading $assetKey'),
        ));
      }
      return null;
    }
  }
}
```

Replace the four duplicated `try/catch` blocks with `SafeAssetLoader.load`. Player and enemy components return early on `null`; their existing procedural `render` branches remain unchanged. Weapon and combat effect loaders return the nullable shared-loader result.

- [x] **Step 4: Run targeted fallback and component tests**

Run: `flutter test test/game/safe_asset_loader_test.dart test/game/player_component_test.dart test/game/enemy_component_test.dart test/game/weapon_effect_atlas_test.dart test/game/combat_effect_atlas_test.dart`

Expected: loader tests pass and all existing procedural fallback/component tests remain green.

- [x] **Step 5: Commit**

```powershell
git add lib/game/content/safe_asset_loader.dart lib/game/content/weapon_effect_atlas.dart lib/game/content/combat_effect_atlas.dart lib/game/components/player_component.dart lib/game/components/enemy_component.dart test/game/safe_asset_loader_test.dart
git commit -m "refactor: centralize safe sprite loading"
```

### Task 4: Release evidence and master tracking

**Files:**
- Modify: `docs/master-development-todo.md`
- Modify: `docs/superpowers/plans/2026-07-15-replaceable-art-pipeline.md`

**Interfaces:**
- Consumes: fresh format, analysis, test, web-build, and Android-debug-build output.
- Produces: checked plan steps and auditable `VIS-003` through `VIS-012` status text.

- [x] **Step 1: Mark prior generated art as technically integrated but visually temporary**

Keep `VIS-003` through `VIS-007` checked because their code and provenance milestones remain complete, but append that visual approval was withdrawn on 2026-07-15 and final cute/chibi replacements are required before `VIS-013` and release.

- [x] **Step 2: Run the complete release gate**

Run: `powershell -ExecutionPolicy Bypass -File tool/release_check.ps1 -IncludeAndroid`

Expected: formatting unchanged, Dart analysis has zero issues, all tests pass, web build succeeds, Android debug APK build succeeds, and the script exits 0.

- [x] **Step 3: Update `VIS-011` and `VIS-012` with exact evidence**

Mark both items complete only after Step 2 succeeds. Record the shared safe loader, development diagnostic/release fallback tests, eight atlas contracts, exact PNG dimensions/transparency checks, total test count from the fresh run, and successful web/Android builds.

- [x] **Step 4: Check the plan against the approved design**

Confirm that no image was generated or visually approved, all registered art is `temporary`, same-contract PNG replacement requires no component change, and `VIS-008` through `VIS-010` remain unchecked.

- [x] **Step 5: Commit release evidence**

```powershell
git add docs/master-development-todo.md docs/superpowers/plans/2026-07-15-replaceable-art-pipeline.md
git commit -m "docs: complete replaceable art pipeline milestone"
```
