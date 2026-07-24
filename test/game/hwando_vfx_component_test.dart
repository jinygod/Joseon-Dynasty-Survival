import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/combat/attack_timeline.dart';
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

  Future<Map<String, ui.Image>> phaseImages() async {
    final result = <String, ui.Image>{};
    for (final layer in AttackVisualRegistry.byId('hwando_slash').layers) {
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawRect(
        ui.Rect.fromLTWH(
          0,
          0,
          layer.frameSize * layer.frameCount,
          layer.frameSize,
        ),
        ui.Paint()..color = const ui.Color(0xffffffff),
      );
      result[layer.assetKey] = await recorder.endRecording().toImage(
        (layer.frameSize * layer.frameCount).round(),
        layer.frameSize.round(),
      );
    }
    return result;
  }

  final hwandoAttack = AttackInstance(
    spec: AttackSpec(
      id: 'hwando_slash',
      shape: AttackShape.sector,
      damage: 10,
      range: 80,
      angleRadians: math.pi * .7,
      radius: 0,
      width: 0,
      windupSeconds: .06,
      activeSeconds: .08,
      lingerSeconds: .10,
      knockback: 10,
      slowFraction: 0,
      traits: const {AttackTrait.melee},
      presentation: AttackPresentation.normal,
    ),
    origin: Vector2(10, 20),
    direction: Vector2(1, 0),
    sequenceIndex: 0,
  );

  test(
    'Hwando VFX follows authored phases and frozen visual geometry',
    () async {
      final images = await phaseImages();
      addTearDown(() => images.values.forEach((image) => image.dispose()));
      final upwardAttack = AttackInstance(
        spec: hwandoAttack.spec,
        origin: Vector2(10, 20),
        direction: Vector2(0, 1),
        sequenceIndex: 0,
      );
      final component = HwandoVfxComponent(
        event: AttackVisualEvent.fromAttack(upwardAttack),
        images: images,
      );

      expect(component.phase, AttackPhase.windup);
      expect(component.visualRadius, 80);
      expect(component.size, Vector2.all(160));
      expect(component.facingAngle, closeTo(math.pi / 2, .0001));

      component.update(.06);
      expect(component.phase, AttackPhase.active);
      component.update(.08);
      expect(component.phase, AttackPhase.recovery);
      component.update(.10);
      expect(component.phase, AttackPhase.complete);
    },
  );

  test('Hwando VFX requires every authored phase image up front', () {
    expect(
      () => HwandoVfxComponent(
        event: AttackVisualEvent.fromAttack(hwandoAttack),
        images: const {},
      ),
      throwsStateError,
    );
  });

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

  test(
    'Hwando VFX safely renders a zero-duration event at terminal progress',
    () async {
      final sheetRecorder = ui.PictureRecorder();
      ui.Canvas(sheetRecorder).drawRect(
        const ui.Rect.fromLTWH(0, 0, 768, 128),
        ui.Paint()..color = const ui.Color(0xffffffff),
      );
      final sheet = await sheetRecorder.endRecording().toImage(768, 128);
      addTearDown(sheet.dispose);
      final zeroDurationAttack = AttackInstance(
        spec: AttackSpec(
          id: 'hwando_slash',
          shape: AttackShape.sector,
          damage: 10,
          range: 80,
          angleRadians: math.pi * .7,
          radius: 0,
          width: 0,
          windupSeconds: 0,
          activeSeconds: 0,
          lingerSeconds: 0,
          knockback: 10,
          slowFraction: 0,
          traits: const {AttackTrait.melee},
          presentation: AttackPresentation.normal,
        ),
        origin: Vector2.zero(),
        direction: Vector2(1, 0),
        sequenceIndex: 0,
      );
      var expired = 0;
      final event = AttackVisualEvent.fromAttack(zeroDurationAttack);
      final component = HwandoVfxComponent(
        event: event,
        images: {
          for (final layer in AttackVisualRegistry.byId(event.effectId).layers)
            layer.assetKey: sheet,
        },
        onExpired: () => expired += 1,
      );
      final renderRecorder = ui.PictureRecorder();
      final canvas = ui.Canvas(renderRecorder);

      expect(component.progress, 1);
      expect(() => component.render(canvas), returnsNormally);
      component.update(0);
      component.update(1);
      expect(() => component.render(canvas), returnsNormally);

      expect(component.isRemoving, isTrue);
      expect(expired, 1);
    },
  );

  for (final invalidDuration in [double.nan, double.infinity]) {
    test('Hwando VFX expires once for a non-finite duration', () async {
      final sheetRecorder = ui.PictureRecorder();
      ui.Canvas(sheetRecorder).drawRect(
        const ui.Rect.fromLTWH(0, 0, 768, 128),
        ui.Paint()..color = const ui.Color(0xffffffff),
      );
      final sheet = await sheetRecorder.endRecording().toImage(768, 128);
      addTearDown(sheet.dispose);
      final attack = AttackInstance(
        spec: AttackSpec(
          id: 'hwando_slash',
          shape: AttackShape.sector,
          damage: 10,
          range: 80,
          angleRadians: math.pi * .7,
          radius: 0,
          width: 0,
          windupSeconds: invalidDuration,
          activeSeconds: 0,
          lingerSeconds: 0,
          knockback: 10,
          slowFraction: 0,
          traits: const {AttackTrait.melee},
          presentation: AttackPresentation.normal,
        ),
        origin: Vector2.zero(),
        direction: Vector2(1, 0),
        sequenceIndex: 0,
      );
      var expired = 0;
      final event = AttackVisualEvent.fromAttack(attack);
      final component = HwandoVfxComponent(
        event: event,
        images: {
          for (final layer in AttackVisualRegistry.byId(event.effectId).layers)
            layer.assetKey: sheet,
        },
        onExpired: () => expired += 1,
      );
      final renderRecorder = ui.PictureRecorder();
      final canvas = ui.Canvas(renderRecorder);

      expect(() => component.render(canvas), returnsNormally);
      component.update(0);
      component.update(1);

      expect(component.isRemoving, isTrue);
      expect(expired, 1);
    });
  }
}
