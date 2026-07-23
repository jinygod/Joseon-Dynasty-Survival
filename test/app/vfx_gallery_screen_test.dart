import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/pixel_survivor_app.dart';
import 'package:pixel_survivor/app/vfx_gallery_screen.dart';
import 'package:pixel_survivor/game/vfx_gallery_game.dart';

void main() {
  test('release debug helpers expose no gallery route or entry', () {
    expect(debugVfxGalleryRoutes(isDebug: false), isEmpty);
    expect(debugVfxGalleryEntry(isDebug: false), isNull);
  });

  testWidgets('gallery exposes the required debug controls', (tester) async {
    final game = VfxGalleryGame(loadVisualAssets: false);
    addTearDown(game.onDispose);
    await tester.pumpWidget(MaterialApp(home: VfxGalleryScreen(game: game)));

    for (final key in [
      'vfx-speed-025',
      'vfx-speed-050',
      'vfx-speed-100',
      'vfx-loop-toggle',
      'vfx-background-moonlit',
      'vfx-background-plague',
      'vfx-actor-toggle',
      'vfx-hitbox-toggle',
      'vfx-anchor-toggle',
    ]) {
      expect(find.byKey(Key(key)), findsOneWidget);
    }
    for (var direction = 0; direction < 8; direction += 1) {
      expect(find.byKey(Key('vfx-direction-$direction')), findsOneWidget);
    }
    expect(find.byKey(const Key('vfx-effect-selector')), findsOneWidget);
    expect(find.byKey(const Key('vfx-current-frame')), findsOneWidget);
    expect(find.byKey(const Key('vfx-active-component-count')), findsOneWidget);
  });

  testWidgets('gallery remains usable at a narrow debug width', (tester) async {
    tester.view.physicalSize = const Size(400, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final game = VfxGalleryGame(loadVisualAssets: false);
    addTearDown(game.onDispose);

    await tester.pumpWidget(MaterialApp(home: VfxGalleryScreen(game: game)));

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('vfx-effect-selector')), findsOneWidget);
  });

  testWidgets('debug entry navigates to the gallery route', (tester) async {
    final game = VfxGalleryGame(loadVisualAssets: false);
    addTearDown(game.onDispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        routes: debugVfxGalleryRoutes(
          isDebug: true,
          galleryBuilder: (_) => VfxGalleryScreen(game: game),
        ),
        home: Stack(
          children: [
            const SizedBox.expand(),
            debugVfxGalleryEntry(isDebug: true)!,
          ],
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('vfx-gallery-entry')));
    await tester.pump();
    await tester.pump();
    expect(find.byType(VfxGalleryScreen), findsOneWidget);
  });
}
