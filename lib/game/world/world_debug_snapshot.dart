import 'dart:ui';

import 'package:flutter/foundation.dart';

@immutable
class WorldDebugSnapshot {
  const WorldDebugSnapshot({
    required this.worldBounds,
    required this.cameraRect,
    required this.visibleRect,
    required this.activeRect,
    required this.sleepingRect,
    required this.chunkSize,
    required this.activeEnemies,
    required this.sleepingEnemies,
    required this.activeExperienceGems,
    required this.compressedExperience,
    required this.activeProjectiles,
    required this.activeVfx,
    required this.mountedComponents,
    required this.componentCreatesPerSecond,
    required this.componentRemovesPerSecond,
    required this.fps,
    required this.frameTimeP95Ms,
    required this.cameraZoom,
  });

  final Rect worldBounds;
  final Rect cameraRect;
  final Rect visibleRect;
  final Rect activeRect;
  final Rect sleepingRect;
  final double chunkSize;
  final int activeEnemies;
  final int sleepingEnemies;
  final int activeExperienceGems;
  final int compressedExperience;
  final int activeProjectiles;
  final int activeVfx;
  final int mountedComponents;
  final double componentCreatesPerSecond;
  final double componentRemovesPerSecond;
  final double fps;
  final double frameTimeP95Ms;
  final double cameraZoom;
}

abstract interface class WorldDebugSource {
  bool get worldDebugVisible;
  WorldDebugSnapshot get debugSnapshot;
  void setWorldDebugVisible(bool visible);
}
