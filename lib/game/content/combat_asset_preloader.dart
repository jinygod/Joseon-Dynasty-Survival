import 'dart:ui';

import 'package:flame/cache.dart';

abstract final class CombatAssetPreloader {
  static Future<Map<String, Image>> load(
    Images images,
    Iterable<String> keys,
  ) => loadWith(keys, images.load);

  static Future<Map<String, Image>> loadWith(
    Iterable<String> keys,
    Future<Image> Function(String key) loader,
  ) async {
    final images = <String, Image>{};
    for (final key in keys.toSet().toList()..sort()) {
      images[key] = await loader(key);
    }
    return Map.unmodifiable(images);
  }
}
