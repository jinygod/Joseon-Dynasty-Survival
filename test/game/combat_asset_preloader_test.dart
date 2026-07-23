import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/combat_asset_preloader.dart';

void main() {
  test(
    'preloader deduplicates registry keys into an immutable cache',
    () async {
      final loaded = <String>[];
      final recorder = ui.PictureRecorder();
      ui.Canvas(
        recorder,
      ).drawRect(const ui.Rect.fromLTWH(0, 0, 1, 1), ui.Paint());
      final fakeImage = await recorder.endRecording().toImage(1, 1);
      addTearDown(fakeImage.dispose);

      final result = await CombatAssetPreloader.loadWith(
        const ['vfx/a.png', 'vfx/a.png', 'vfx/b.png'],
        (key) async {
          loaded.add(key);
          return fakeImage;
        },
      );

      expect(loaded, ['vfx/a.png', 'vfx/b.png']);
      expect(result.keys, {'vfx/a.png', 'vfx/b.png'});
      expect(() => result.clear(), throwsUnsupportedError);
    },
  );
}
