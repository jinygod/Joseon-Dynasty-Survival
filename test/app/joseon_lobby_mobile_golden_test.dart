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
  test('missing-glyph border detector rejects medal-like dense masks', () {
    expect(
      _looksLikeMissingGlyphBox(
        denseRows: const [0, 1, 16, 17],
        denseColumns: const [0, 1, 16, 17],
        width: 18,
        height: 18,
      ),
      isTrue,
    );
    expect(
      _looksLikeMissingGlyphBox(
        denseRows: List<int>.generate(18, (index) => index),
        denseColumns: List<int>.generate(18, (index) => index),
        width: 18,
        height: 18,
      ),
      isFalse,
    );
  });

  for (final size in const [
    Size(390, 844),
    Size(375, 667),
    Size(430, 932),
  ]) {
    testWidgets('lobby mobile ${size.width.toInt()}x${size.height.toInt()} golden', (
      tester,
    ) async {
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
      );
    });
  }
}

Future<void> _expectMobileLobbyGolden(
  WidgetTester tester,
  Size size,
  Widget lobby,
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
      home: RepaintBoundary(key: const Key('golden-root'), child: lobby),
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
  await expectLater(
    find.byKey(const Key('golden-root')),
    matchesGoldenFile(
      'goldens/lobby_mobile_${size.width.toInt()}x${size.height.toInt()}.png',
    ),
  );
  await tester.pumpWidget(const SizedBox.shrink());
}

Future<void> _expectLobbyVisualAssetsPainted(WidgetTester tester) async {
  final boundaryFinder = find.byKey(const Key('golden-root'));
  final boundary = tester.renderObject<RenderRepaintBoundary>(boundaryFinder);
  final boundaryRect = tester.getRect(boundaryFinder);
  final rendered = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return (width: image.width, pixels: bytes?.buffer.asUint8List());
  });
  expect(rendered, isNotNull);
  expect(rendered!.pixels, isNotNull);
  final pixels = rendered.pixels!;

  final iconFinder = find.byType(Icon);
  expect(iconFinder, findsWidgets);
  for (final icon in iconFinder.evaluate()) {
    final rect = tester.getRect(find.byWidget(icon.widget));
    final left = (rect.left - boundaryRect.left).floor();
    final top = (rect.top - boundaryRect.top).floor();
    final width = rect.width.ceil();
    final height = rect.height.ceil();
    final denseRows = <int>[];
    for (var y = 0; y < height; y++) {
      var inkPixels = 0;
      for (var x = 0; x < width; x++) {
        final pixel = ((top + y) * rendered.width + left + x) * 4;
        if (_isJoseonInk(pixels, pixel)) {
          inkPixels += 1;
        }
      }
      if (inkPixels >= width * .6) {
        denseRows.add(y);
      }
    }
    final denseColumns = <int>[];
    for (var x = 0; x < width; x++) {
      var inkPixels = 0;
      for (var y = 0; y < height; y++) {
        final pixel = ((top + y) * rendered.width + left + x) * 4;
        if (_isJoseonInk(pixels, pixel)) {
          inkPixels += 1;
        }
      }
      if (inkPixels >= height * .6) {
        denseColumns.add(x);
      }
    }
    expect(
      _looksLikeMissingGlyphBox(
        denseRows: denseRows,
        denseColumns: denseColumns,
        width: width,
        height: height,
      ),
      isFalse,
      reason: 'Material icon ${(icon.widget as Icon).icon} painted as a '
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
