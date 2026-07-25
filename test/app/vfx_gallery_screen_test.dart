import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/pixel_survivor_app.dart';
import 'package:pixel_survivor/app/vfx_gallery_screen.dart';
import 'package:pixel_survivor/game/combat/attack_timeline.dart';
import 'package:pixel_survivor/game/components/hwando_vfx_component.dart';
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
      'vfx-step',
      'vfx-background-moonlit',
      'vfx-background-plague',
      'vfx-background-neutral',
      'vfx-actor-toggle',
      'vfx-visual-bounds-toggle',
      'vfx-hitbox-toggle',
      'vfx-hurtbox-toggle',
      'vfx-contact-point-toggle',
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
    final horizontalFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.right,
    );
    await tester.drag(horizontalFinder, const Offset(-240, 0));
    await tester.pump();
    expect(
      tester.state<ScrollableState>(horizontalFinder).position.pixels,
      greaterThan(0),
    );
    await tester.ensureVisible(find.byKey(const Key('vfx-anchor-toggle')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('resize publishes frame zero and the live production count', (
    tester,
  ) async {
    final game = VfxGalleryGame(loadVisualAssets: false);
    addTearDown(game.onDispose);
    await tester.pumpWidget(MaterialApp(home: VfxGalleryScreen(game: game)));

    game.update(.5);
    expect(game.status.value.currentFrame, greaterThan(0));
    game.onGameResize(Vector2(800, 480));
    await tester.pump();

    expect(game.status.value.currentFrame, 0);
    expect(game.status.value.activeProductionComponentCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('playback publishes frame changes after the Flutter frame', (
    tester,
  ) async {
    final game = VfxGalleryGame(loadVisualAssets: false);
    addTearDown(game.onDispose);
    await tester.pumpWidget(MaterialApp(home: VfxGalleryScreen(game: game)));

    for (var frame = 0; frame < 4; frame += 1) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull);
    }

    expect(game.status.value.currentFrame, greaterThanOrEqualTo(0));
  });

  testWidgets('step control advances Hwando into its active phase', (
    tester,
  ) async {
    final game = VfxGalleryGame(loadVisualAssets: false);
    addTearDown(game.onDispose);
    await tester.pumpWidget(MaterialApp(home: VfxGalleryScreen(game: game)));
    game.selectEffect('hwando_slash');
    await tester.pump();

    for (var step = 0; step < 4; step += 1) {
      await tester.tap(find.byKey(const Key('vfx-step')));
      await tester.pump();
    }

    expect(
      (game.activeProductionComponent! as HwandoVfxComponent).phase,
      AttackPhase.active,
    );
    expect(game.status.value.currentFrame, greaterThanOrEqualTo(4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('debug entry navigates to the gallery route', (tester) async {
    final game = VfxGalleryGame(loadVisualAssets: false);
    addTearDown(game.onDispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          splashFactory: NoSplash.splashFactory,
          useMaterial3: false,
        ),
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

    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('vfx-gallery-entry')));
    await tester.pump();
    await tester.pump();
    expect(find.byType(VfxGalleryScreen), findsOneWidget);
  });
}
