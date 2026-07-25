import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/combat/projectile_sweep_geometry.dart';
import 'package:pixel_survivor/game/components/projectile_component.dart';
import 'package:pixel_survivor/game/components/projectile_contact_vfx_component.dart';
import 'package:pixel_survivor/game/components/projectile_geometry_debug_component.dart';
import 'package:pixel_survivor/game/content/projectile_presentation_spec.dart';

void main() {
  testWidgets('release projectile families at 960x540 landscape', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(960, 540);
    addTearDown(tester.view.reset);

    final game = _ProjectileReleaseGalleryGame();
    addTearDown(game.onDispose);
    game.onGameResize(Vector2(960, 540));
    await tester.runAsync(game.onLoad);
    game.processLifecycleEvents();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: const Key('projectile-release-surface'),
          child: GameWidget(game: game),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      game.children.whereType<ProjectileComponent>(),
      hasLength(4),
    );
    expect(
      game.children.whereType<ProjectileGeometryDebugComponent>(),
      hasLength(1),
    );

    await expectLater(
      find.byKey(const Key('projectile-release-surface')),
      matchesGoldenFile('goldens/projectile_release_landscape_16_9.png'),
    );
  });
}

class _ProjectileReleaseGalleryGame extends FlameGame {
  final Map<String, ui.Image> _images = {};
  bool _loaded = false;
  bool _disposed = false;

  @override
  ui.Color backgroundColor() => const ui.Color(0xff172b3a);

  @override
  Future<void> onLoad() async {
    if (_loaded) return;
    _loaded = true;
    await super.onLoad();
    add(_ReviewBackdrop());
    final positions = [
      Vector2(150, 150),
      Vector2(370, 150),
      Vector2(590, 150),
      Vector2(810, 150),
    ];
    for (var index = 0; index < positions.length; index += 1) {
      final spec = ProjectilePresentationSpecs.byWeapon.values.elementAt(index);
      final image = await _load(spec.assetKey);
      add(
        ProjectileComponent(
          weaponId: spec.weaponId,
          damage: 0,
          position: positions[index].clone(),
          velocity: Vector2(1, 0),
          lifetime: 100,
          sizeMultiplier: 2,
          visualImage: image,
        ),
      );
    }

    final spec = ProjectilePresentationSpecs.byWeapon.values.elementAt(1);
    final previous = Vector2(150, 365);
    final current = Vector2(640, 365);
    final hurtCenter = Vector2(470, 365);
    final contact = ProjectileSweepGeometry.firstContact(
      previousCenter: previous,
      currentCenter: current,
      direction: Vector2(1, 0),
      hitBodySize: spec.hitBodySize,
      hurtCenter: hurtCenter,
      hurtRadius: 24,
    )!;
    add(
      ProjectileGeometryDebugComponent(
        weaponId: spec.weaponId,
        previousCenter: previous,
        currentCenter: current,
        direction: Vector2(1, 0),
        visualBodySize: spec.bodySize,
        hitBodySize: spec.hitBodySize,
        hurtCenter: hurtCenter,
        hurtRadius: 24,
        contact: contact,
        autoExpire: false,
      )..showWeaponId = false,
    );
    add(
      ProjectileContactVfxComponent(
        position: contact.point,
        direction: contact.normal,
        image: await _load(ProjectileContactVfxComponent.assetKey),
      ),
    );
  }

  Future<ui.Image> _load(String key) async {
    final cached = _images[key];
    if (cached != null) return cached;
    final bytes = await File('assets/images/$key').readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final image = (await codec.getNextFrame()).image;
    codec.dispose();
    _images[key] = image;
    return image;
  }

  @override
  void onDispose() {
    if (_disposed) return;
    _disposed = true;
    for (final image in _images.values) {
      image.dispose();
    }
    super.onDispose();
  }
}

class _ReviewBackdrop extends Component {
  _ReviewBackdrop() : super(priority: -1000);

  @override
  void render(ui.Canvas canvas) {
    canvas.drawRect(
      const ui.Rect.fromLTWH(36, 54, 888, 190),
      ui.Paint()..color = const ui.Color(0xff223e50),
    );
    canvas.drawRect(
      const ui.Rect.fromLTWH(36, 282, 888, 190),
      ui.Paint()..color = const ui.Color(0xff10212d),
    );
    final divider = ui.Paint()
      ..color = const ui.Color(0xffd8bd77)
      ..strokeWidth = 2;
    for (final x in const [260.0, 480.0, 700.0]) {
      canvas.drawLine(ui.Offset(x, 78), ui.Offset(x, 220), divider);
    }
  }
}
