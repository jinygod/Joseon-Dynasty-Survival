import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/world_debug_overlay.dart';
import 'package:pixel_survivor/game/world/world_debug_snapshot.dart';

void main() {
  testWidgets('debug panel is collapsed and can be toggled on and off', (
    tester,
  ) async {
    final source = _FakeDebugSource();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: WorldDebugOverlay(source: source),
      ),
    );

    expect(find.byKey(const Key('world-debug-panel')), findsNothing);
    await tester.tap(find.byKey(const Key('world-debug-toggle')));
    await tester.pump();
    expect(source.worldDebugVisible, isTrue);
    expect(find.byKey(const Key('world-debug-panel')), findsOneWidget);
    expect(find.textContaining('p95 17.2ms'), findsOneWidget);

    await tester.tap(find.byKey(const Key('world-debug-toggle')));
    await tester.pump();
    expect(source.worldDebugVisible, isFalse);
    expect(find.byKey(const Key('world-debug-panel')), findsNothing);
  });
}

class _FakeDebugSource implements WorldDebugSource {
  bool _visible = false;

  @override
  bool get worldDebugVisible => _visible;

  @override
  void setWorldDebugVisible(bool visible) => _visible = visible;

  @override
  WorldDebugSnapshot get debugSnapshot => const WorldDebugSnapshot(
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
}
