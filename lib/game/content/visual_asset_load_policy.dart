import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract interface class VisualAssetLoadPolicy {
  bool get loadVisualAssets;
}

bool shouldLoadVisualAssets(Component component) {
  try {
    ServicesBinding.instance;
  } on FlutterError {
    return false;
  }
  final game = component.findGame();
  return game is! VisualAssetLoadPolicy ||
      (game as VisualAssetLoadPolicy).loadVisualAssets;
}
