import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/attack_visual_registry.dart';
import 'package:pixel_survivor/game/content/combat_asset_preloader.dart';
import 'package:pixel_survivor/game/content/weapon_effect_atlas.dart';

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

      final keys = [
        ...AttackVisualRegistry.requiredAssetKeys,
        WeaponEffectAtlas.assetKey,
        WeaponEffectAtlas.assetKey,
      ];
      final result = await CombatAssetPreloader.loadWith(keys, (key) async {
        loaded.add(key);
        return fakeImage;
      });

      expect(loaded.toSet(), {
        ...AttackVisualRegistry.requiredAssetKeys,
        WeaponEffectAtlas.assetKey,
      });
      expect(
        loaded,
        hasLength(AttackVisualRegistry.requiredAssetKeys.length + 1),
      );
      expect(result.keys, loaded);
      expect(() => result.clear(), throwsUnsupportedError);
    },
  );
}
