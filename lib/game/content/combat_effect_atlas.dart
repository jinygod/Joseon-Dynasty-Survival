import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/services.dart';

import 'safe_asset_loader.dart';

enum CombatEffectKind { experience, hit, critical, death, warning }

abstract final class CombatEffectAtlas {
  static const assetKey = 'effects/combat_effects_atlas_64.png';
  static const frameSize = 64.0;
  static const framesPerEffect = 4;

  static int rowFor(CombatEffectKind kind) => kind.index;

  static int frameForProgress(double progress) {
    final normalized = progress.clamp(0, 1).toDouble();
    return (normalized * framesPerEffect).floor().clamp(0, framesPerEffect - 1);
  }

  static Sprite sprite(
    Image image, {
    required CombatEffectKind kind,
    required int frame,
  }) {
    return Sprite(
      image,
      srcPosition: Vector2(frame * frameSize, rowFor(kind) * frameSize),
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
      library: 'pixel_survivor combat effects',
      assetKey: assetKey,
    );
  }
}
