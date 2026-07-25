import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/game_settings_repository.dart';
import 'package:pixel_survivor/app/joseon_ui_theme.dart';
import 'package:pixel_survivor/app/lobby_controller.dart';
import 'package:pixel_survivor/app/lobby_screen.dart';
import 'package:pixel_survivor/game/audio/audio_settings.dart';
import 'package:pixel_survivor/game/audio/audio_settings_controller.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';

void main() {
  testWidgets('missing-glyph detector distinguishes medal and tofu paths', (
    tester,
  ) async {
    await tester.runAsync(_loadMaterialIconsFont);
    await tester.pumpWidget(
      const MaterialApp(
        home: RepaintBoundary(
          key: Key('icon-evidence-root'),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.military_tech_outlined,
                key: Key('medal-icon'),
                color: Color(0xff2b251d),
                size: 24,
              ),
              Icon(
                IconData(0xf0000, fontFamily: 'MaterialIcons'),
                key: Key('unsupported-icon'),
                color: Color(0xff2b251d),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    final pixels = await _captureRawPixels(
      tester,
      find.byKey(const Key('icon-evidence-root')),
    );
    final medal = _denseBandsForRect(
      pixels: pixels.pixels,
      imageWidth: pixels.width,
      rect: tester.getRect(find.byKey(const Key('medal-icon'))),
    );
    expect(
      _looksLikeMissingGlyphBox(
        denseRows: medal.rows,
        denseColumns: medal.columns,
        width: medal.width,
        height: medal.height,
      ),
      isFalse,
    );

    final unsupported = _denseBandsForRect(
      pixels: pixels.pixels,
      imageWidth: pixels.width,
      rect: tester.getRect(find.byKey(const Key('unsupported-icon'))),
    );
    final unsupportedLooksLikeTofu = _looksLikeMissingGlyphBox(
      denseRows: unsupported.rows,
      denseColumns: unsupported.columns,
      width: unsupported.width,
      height: unsupported.height,
    );
    if (unsupportedLooksLikeTofu) {
      expect(unsupportedLooksLikeTofu, isTrue);
    } else {
      final syntheticTofu = _denseBandsForRect(
        pixels: _thinTofuPixels(24),
        imageWidth: 24,
        rect: const Rect.fromLTWH(0, 0, 24, 24),
      );
      expect(
        _looksLikeMissingGlyphBox(
          denseRows: syntheticTofu.rows,
          denseColumns: syntheticTofu.columns,
          width: syntheticTofu.width,
          height: syntheticTofu.height,
        ),
        isTrue,
      );
    }
  });

  for (final size in const [Size(1280, 720), Size(1170, 540)]) {
    testWidgets(
      'lobby landscape ${size.width.toInt()}x${size.height.toInt()} golden',
      (tester) async {
        final controller = LobbyController(
          store: _MemorySaveStore(SaveState.defaults()),
        );
        await controller.load();
        await _expectMobileLobbyGolden(
          tester,
          size,
          LobbyScreen(
            controller: controller,
            audioSettingsController: _audioController(),
          ),
          goldenFile:
              'lobby_${size.width.toInt()}x${size.height.toInt()}.png',
          beforeCapture: (tester) async {
            if (size.width / size.height < 2) return;
            final character = tester.getRect(
              find.byKey(const Key('lobby-character-art')),
            );
            final deploy = tester.getRect(
              find.byKey(const Key('lobby-deploy')),
            );
            final stagePlaque = tester.getRect(
              find.byKey(const Key('lobby-stage-plaque')),
            );
            final stagePicker = tester.getRect(
              find.byKey(const Key('lobby-stage')),
            );
            expect(
              deploy.left,
              greaterThanOrEqualTo(size.width * .65),
              reason: 'ultra-wide staging must not cover the character',
            );
            expect(
              stagePicker,
              stagePlaque,
              reason: 'the ultra-wide stage picker must match the visible plaque',
            );
          },
        );
      },
    );
  }

  testWidgets('lobby feature notice 16:9 golden', (tester) async {
    final controller = LobbyController(
      store: _MemorySaveStore(SaveState.defaults()),
    );
    await controller.load();
    await _expectMobileLobbyGolden(
      tester,
      const Size(1280, 720),
      LobbyScreen(
        controller: controller,
        audioSettingsController: _audioController(),
      ),
      goldenFile: 'lobby_feature_notice.png',
      beforeCapture: (tester) async {
        await tester.tap(find.byKey(const Key('lobby-quick-crafting')));
        await tester.pumpAndSettle();
        for (var attempt = 0; attempt < 3; attempt++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pump();
        }
        expect(find.byKey(const Key('lobby-feature-notice')), findsOneWidget);
      },
    );
  });
}

Future<void> _expectMobileLobbyGolden(
  WidgetTester tester,
  Size size,
  Widget lobby,
  {
  required String goldenFile,
  Future<void> Function(WidgetTester tester)? beforeCapture,
}
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.runAsync(() async {
    await _loadBundledJoseonFonts();
    await _loadMaterialIconsFont();
  });
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: JoseonUiTheme.create(),
      builder: (context, child) => RepaintBoundary(
        key: const Key('golden-root'),
        child: child!,
      ),
      home: lobby,
    ),
  );
  for (var attempt = 0; attempt < 3; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }
  expect(tester.takeException(), isNull);
  await _expectLobbyVisualAssetsPainted(tester);
  await beforeCapture?.call(tester);
  await expectLater(
    find.byKey(const Key('golden-root')),
    matchesGoldenFile('goldens/$goldenFile'),
  );
  await tester.pumpWidget(const SizedBox.shrink());
}

Future<void> _expectLobbyVisualAssetsPainted(WidgetTester tester) async {
  final boundaryFinder = find.byKey(const Key('golden-root'));
  final boundaryRect = tester.getRect(boundaryFinder);
  final rendered = await _captureRawPixels(tester, boundaryFinder);
  final pixels = rendered.pixels;

  final iconFinder = find.byType(Icon);
  expect(iconFinder, findsWidgets);
  for (final icon in iconFinder.evaluate()) {
    final rect = tester.getRect(find.byWidget(icon.widget));
    final left = (rect.left - boundaryRect.left).floor();
    final top = (rect.top - boundaryRect.top).floor();
    final width = rect.width.ceil();
    final height = rect.height.ceil();
    final dense = _denseBandsInPixels(
      pixels: pixels,
      imageWidth: rendered.width,
      left: left,
      top: top,
      width: width,
      height: height,
    );
    expect(
      _looksLikeMissingGlyphBox(
        denseRows: dense.rows,
        denseColumns: dense.columns,
        width: width,
        height: height,
      ),
      isFalse,
      reason:
          'Material icon ${(icon.widget as Icon).icon} painted as a '
          'thin rectangular missing-glyph box',
    );
  }

  final characterRect = tester.getRect(
    find.byKey(const Key('lobby-character-art')),
  );
  final colors = <int>{};
  for (
    var y = (characterRect.top + characterRect.height * .25).floor();
    y < (characterRect.bottom - characterRect.height * .25).ceil();
    y++
  ) {
    for (
      var x = (characterRect.left + characterRect.width * .25).floor();
      x < (characterRect.right - characterRect.width * .25).ceil();
      x++
    ) {
      final pixel = (y * rendered.width + x) * 4;
      colors.add(
        pixels[pixel] << 24 |
            pixels[pixel + 1] << 16 |
            pixels[pixel + 2] << 8 |
            pixels[pixel + 3],
      );
    }
  }
  expect(
    colors.length,
    greaterThan(20),
    reason: 'character image did not paint inside its medallion',
  );
}

Future<({int width, Uint8List pixels})> _captureRawPixels(
  WidgetTester tester,
  Finder finder,
) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(finder);
  final rendered = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return (width: image.width, pixels: bytes?.buffer.asUint8List());
  });
  expect(rendered, isNotNull);
  expect(rendered!.pixels, isNotNull);
  return (width: rendered.width, pixels: rendered.pixels!);
}

({int width, int height, List<int> rows, List<int> columns})
_denseBandsForRect({
  required Uint8List pixels,
  required int imageWidth,
  required Rect rect,
}) => _denseBandsInPixels(
  pixels: pixels,
  imageWidth: imageWidth,
  left: rect.left.floor(),
  top: rect.top.floor(),
  width: rect.width.ceil(),
  height: rect.height.ceil(),
);

({int width, int height, List<int> rows, List<int> columns})
_denseBandsInPixels({
  required Uint8List pixels,
  required int imageWidth,
  required int left,
  required int top,
  required int width,
  required int height,
}) {
  final rows = <int>[];
  for (var y = 0; y < height; y++) {
    var inkPixels = 0;
    for (var x = 0; x < width; x++) {
      if (_isJoseonInk(pixels, ((top + y) * imageWidth + left + x) * 4)) {
        inkPixels += 1;
      }
    }
    if (inkPixels >= width * .6) rows.add(y);
  }
  final columns = <int>[];
  for (var x = 0; x < width; x++) {
    var inkPixels = 0;
    for (var y = 0; y < height; y++) {
      if (_isJoseonInk(pixels, ((top + y) * imageWidth + left + x) * 4)) {
        inkPixels += 1;
      }
    }
    if (inkPixels >= height * .6) columns.add(x);
  }
  return (width: width, height: height, rows: rows, columns: columns);
}

Uint8List _thinTofuPixels(int extent) {
  final pixels = Uint8List(extent * extent * 4);
  for (var index = 0; index < extent; index++) {
    for (final offset in const [0, 1, 22, 23]) {
      _setInk(pixels, extent, index, offset);
      _setInk(pixels, extent, offset, index);
    }
  }
  return pixels;
}

void _setInk(Uint8List pixels, int width, int x, int y) {
  final pixel = (y * width + x) * 4;
  pixels[pixel] = 43;
  pixels[pixel + 1] = 37;
  pixels[pixel + 2] = 29;
  pixels[pixel + 3] = 255;
}

bool _looksLikeMissingGlyphBox({
  required List<int> denseRows,
  required List<int> denseColumns,
  required int width,
  required int height,
}) {
  const maxBorderThickness = 4;
  return _hasThinOpposingEdgeBands(denseRows, height, maxBorderThickness) &&
      _hasThinOpposingEdgeBands(denseColumns, width, maxBorderThickness);
}

bool _hasThinOpposingEdgeBands(
  List<int> denseIndices,
  int extent,
  int maxThickness,
) {
  if (denseIndices.isEmpty || extent < maxThickness * 2 + 1) return false;
  final dense = denseIndices.toSet();
  var leadingThickness = 0;
  while (leadingThickness < extent && dense.contains(leadingThickness)) {
    leadingThickness += 1;
  }
  var trailingThickness = 0;
  while (trailingThickness < extent &&
      dense.contains(extent - 1 - trailingThickness)) {
    trailingThickness += 1;
  }
  return leadingThickness > 0 &&
      leadingThickness <= maxThickness &&
      trailingThickness > 0 &&
      trailingThickness <= maxThickness;
}

bool _isJoseonInk(Uint8List pixels, int pixel) =>
    (pixels[pixel] - 43).abs() <= 35 &&
    (pixels[pixel + 1] - 37).abs() <= 35 &&
    (pixels[pixel + 2] - 29).abs() <= 35 &&
    pixels[pixel + 3] > 220;

Future<void> _loadBundledJoseonFonts() async {
  final displayBytes = await File(
    'assets/fonts/SongMyung-Regular.ttf',
  ).readAsBytes();
  await (FontLoader(
    JoseonUiTheme.displayFontFamily,
  )..addFont(Future.value(ByteData.sublistView(displayBytes)))).load();
  final bodyBytes = await File(
    'assets/fonts/GowunBatang-Regular.ttf',
  ).readAsBytes();
  final boldBodyBytes = await File(
    'assets/fonts/GowunBatang-Bold.ttf',
  ).readAsBytes();
  await (FontLoader(JoseonUiTheme.bodyFontFamily)
        ..addFont(Future.value(ByteData.sublistView(bodyBytes)))
        ..addFont(Future.value(ByteData.sublistView(boldBodyBytes))))
      .load();
}

Future<void> _loadMaterialIconsFont() async {
  var directory = File(Platform.resolvedExecutable).parent;
  File? font;
  while (directory.parent.path != directory.path) {
    final candidate = File(
      '${directory.path}${Platform.pathSeparator}cache'
      '${Platform.pathSeparator}artifacts${Platform.pathSeparator}'
      'material_fonts${Platform.pathSeparator}MaterialIcons-Regular.otf',
    );
    if (candidate.existsSync()) {
      font = candidate;
      break;
    }
    directory = directory.parent;
  }
  if (font == null) {
    throw StateError('Flutter SDK Material Icons font is missing.');
  }
  final bytes = await font.readAsBytes();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
}

AudioSettingsController _audioController() =>
    AudioSettingsController(store: _MemoryAudioStore());

class _MemorySaveStore implements SaveStore {
  _MemorySaveStore(this.value);
  SaveState value;
  @override
  Future<SaveState> load() async => value;
  @override
  Future<void> save(SaveState state) async => value = state;
}

class _MemoryAudioStore implements GameSettingsStore {
  AudioSettings value = AudioSettings.defaults;
  @override
  Future<AudioSettings> load() async => value;
  @override
  Future<void> save(AudioSettings settings) async => value = settings;
}
