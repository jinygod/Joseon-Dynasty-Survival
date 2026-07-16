import 'package:flame/components.dart';

abstract interface class VisualAssetLoadPolicy {
  bool get loadVisualAssets;
}

bool shouldLoadVisualAssets(Component component) {
  final game = component.findGame();
  return game is! VisualAssetLoadPolicy ||
      (game as VisualAssetLoadPolicy).loadVisualAssets;
}
