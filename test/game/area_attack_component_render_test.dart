import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/area_attack_component.dart';
import 'package:pixel_survivor/game/content/combat_effect_atlas.dart';
import 'package:pixel_survivor/game/content/visual_asset_load_policy.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final loadWarningAtlas in [false, true]) {
    final assetState = loadWarningAtlas ? 'loaded' : 'missing';

    test(
      'boss radial warning preserves its radius with atlas $assetState',
      () async {
        final pixels = await _renderBossWarning(
          loadWarningAtlas: loadWarningAtlas,
          angleRadians: math.pi * 2,
        );

        expect(pixels.visibleCount, greaterThan(0));
        expect(
          pixels.visibleOutside(radius: _radius, angleRadians: math.pi * 2),
          0,
        );
      },
    );

    test('boss cone warning stays a cone with atlas $assetState', () async {
      final pixels = await _renderBossWarning(
        loadWarningAtlas: loadWarningAtlas,
        angleRadians: math.pi / 2,
      );

      expect(pixels.visibleCount, greaterThan(0));
      expect(
        pixels.visibleOutside(radius: _radius, angleRadians: math.pi / 2),
        lessThanOrEqualTo(24),
        reason: 'a loaded radial atlas must not replace sector geometry',
      );
    });
  }
}

const _radius = 48.0;

Future<_RenderedPixels> _renderBossWarning({
  required bool loadWarningAtlas,
  required double angleRadians,
}) async {
  final game = _VisualGame(loadVisualAssets: loadWarningAtlas);
  game.onGameResize(Vector2.all(_radius * 2));
  await game.onLoad();
  if (loadWarningAtlas) {
    await game.images.load(CombatEffectAtlas.assetKey);
  }
  final warning = AreaAttackComponent(
    damage: 1,
    radius: _radius,
    delaySeconds: 1,
    knockback: 0,
    position: Vector2.zero(),
    direction: Vector2(1, 0),
    angleRadians: angleRadians,
    isBossAttack: true,
  );
  await game.add(warning);
  await warning.loaded;
  await Future<void>.delayed(Duration.zero);

  final recorder = ui.PictureRecorder();
  warning.render(ui.Canvas(recorder));
  final image = await recorder.endRecording().toImage(
    (_radius * 2).round(),
    (_radius * 2).round(),
  );
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  return _RenderedPixels(data!);
}

class _VisualGame extends FlameGame implements VisualAssetLoadPolicy {
  _VisualGame({required this.loadVisualAssets});

  @override
  final bool loadVisualAssets;
}

class _RenderedPixels {
  const _RenderedPixels(this.data);

  final ByteData data;

  int get visibleCount {
    var count = 0;
    for (var offset = 3; offset < data.lengthInBytes; offset += 4) {
      if (data.getUint8(offset) > 0) count += 1;
    }
    return count;
  }

  int visibleOutside({required double radius, required double angleRadians}) {
    final width = (radius * 2).round();
    var count = 0;
    for (var y = 0; y < width; y += 1) {
      for (var x = 0; x < width; x += 1) {
        if (data.getUint8((y * width + x) * 4 + 3) == 0) continue;
        final dx = x + .5 - radius;
        final dy = y + .5 - radius;
        final distance = math.sqrt(dx * dx + dy * dy);
        // The two-pixel warning stroke and antialiasing may cover one extra
        // pixel beyond the mathematical boundary.
        final withinRadius = distance <= radius + 2.5;
        final angle = math.atan2(dy, dx).abs();
        final withinAngle =
            angleRadians >= math.pi * 2 ||
            distance <= 3 ||
            angle <= angleRadians / 2 + .12;
        if (!withinRadius || !withinAngle) count += 1;
      }
    }
    return count;
  }
}
