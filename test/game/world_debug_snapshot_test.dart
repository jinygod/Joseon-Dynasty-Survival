import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/world/world_debug_snapshot.dart';

void main() {
  test('snapshot preserves world geometry and population metrics', () {
    const snapshot = WorldDebugSnapshot(
      worldBounds: Rect.fromLTWH(0, 0, 2048, 5120),
      cameraRect: Rect.fromLTWH(700, 2100, 600, 1000),
      visibleRect: Rect.fromLTWH(700, 2100, 600, 1000),
      activeRect: Rect.fromLTWH(250, 1350, 1500, 2500),
      sleepingRect: Rect.fromLTWH(0, 0, 2048, 5120),
      chunkSize: 512,
      activeEnemies: 31,
      sleepingEnemies: 17,
      activeExperienceGems: 42,
      compressedExperience: 91,
      activeProjectiles: 23,
      activeVfx: 8,
      mountedComponents: 144,
      componentCreatesPerSecond: 12.5,
      componentRemovesPerSecond: 9.5,
      fps: 58.7,
      frameTimeP95Ms: 17.2,
      cameraZoom: .9,
    );

    expect(snapshot.worldBounds.size, const Size(2048, 5120));
    expect(snapshot.sleepingEnemies, 17);
    expect(snapshot.compressedExperience, 91);
    expect(snapshot.frameTimeP95Ms, 17.2);
    expect(snapshot.cameraZoom, .9);
  });
}
