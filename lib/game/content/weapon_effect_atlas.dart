import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';

import 'ids.dart';
import 'safe_asset_loader.dart';

abstract final class WeaponEffectAtlas {
  static const assetKey = 'effects/weapon_effects_atlas_64.png';
  static const frameSize = 64.0;
  static const framesPerEffect = 4;
  static const hwandoRow = 0;
  static const bowRow = 1;
  static const talismanRow = 2;
  static const bombRow = 3;

  static int? rowForWeapon(WeaponId? weaponId) => switch (weaponId) {
    'hwando_slash' => hwandoRow,
    'gakgung_shot' => bowRow,
    'talisman_throw' => talismanRow,
    'thunder_crash_bomb' => bombRow,
    _ => null,
  };

  static int frameForProgress(double progress) {
    final normalized = progress.clamp(0, 1).toDouble();
    return (normalized * framesPerEffect).floor().clamp(0, framesPerEffect - 1);
  }

  static Sprite sprite(Image image, {required int row, required int frame}) {
    return Sprite(
      image,
      srcPosition: Vector2(frame * frameSize, row * frameSize),
      srcSize: Vector2.all(frameSize),
    );
  }

  static Future<Image?> load(PositionComponent component) async {
    try {
      ServicesBinding.instance;
    } on AssertionError {
      return null;
    }
    return SafeAssetLoader.load(
      load: () => component.findGame()!.images.load(assetKey),
      library: 'pixel_survivor weapon effects',
      assetKey: assetKey,
    );
  }
}
