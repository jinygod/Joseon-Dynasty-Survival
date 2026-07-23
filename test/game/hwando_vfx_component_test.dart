import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/combat/attack_spec.dart';
import 'package:pixel_survivor/game/combat/attack_visual_event.dart';
import 'package:pixel_survivor/game/components/hwando_vfx_component.dart';
import 'package:pixel_survivor/game/content/attack_visual_registry.dart';

void main() {
  late ui.Image onePixelImage;

  setUpAll(() async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(
      recorder,
    ).drawRect(const ui.Rect.fromLTWH(0, 0, 1, 1), ui.Paint());
    onePixelImage = await recorder.endRecording().toImage(1, 1);
  });

  tearDownAll(() => onePixelImage.dispose());

  final hwandoAttack = AttackInstance(
    spec: AttackSpec(
      id: 'hwando_slash',
      shape: AttackShape.sector,
      damage: 10,
      range: 80,
      angleRadians: math.pi * .7,
      radius: 0,
      width: 0,
      windupSeconds: .05,
      activeSeconds: .12,
      lingerSeconds: .08,
      knockback: 10,
      slowFraction: 0,
      traits: const {AttackTrait.melee},
      presentation: AttackPresentation.normal,
    ),
    origin: Vector2(10, 20),
    direction: Vector2(1, 0),
    sequenceIndex: 0,
  );

  test('Hwando VFX freezes direction and expires once', () {
    var expired = 0;
    final images = <String, ui.Image>{
      for (final layer in AttackVisualRegistry.byId('hwando_slash').layers)
        layer.assetKey: onePixelImage,
    };
    final component = HwandoVfxComponent(
      event: AttackVisualEvent.fromAttack(hwandoAttack),
      images: images,
      onExpired: () => expired += 1,
    );

    expect(component.facingAngle, closeTo(0, 1e-9));
    component.update(component.event.duration + .001);
    component.update(1);

    expect(component.isRemoving, isTrue);
    expect(expired, 1);
  });
}
