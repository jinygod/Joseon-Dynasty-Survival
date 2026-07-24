import 'dart:math' as math;
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/hwando_contact_vfx_component.dart';

void main() {
  test('contact VFX has no primitive or runtime-loading fallback', () {
    final source = File(
      'lib/game/components/hwando_contact_vfx_component.dart',
    ).readAsStringSync();

    for (final forbidden in [
      'drawCircle',
      'drawRect',
      'drawPath',
      'images.load',
      'void onLoad',
    ]) {
      expect(source, isNot(contains(forbidden)), reason: forbidden);
    }
  });

  test('contact VFX keeps its contact pivot and expires once', () async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawRect(
      const ui.Rect.fromLTWH(0, 0, 768, 128),
      ui.Paint()..color = const ui.Color(0xffffffff),
    );
    final image = await recorder.endRecording().toImage(768, 128);
    addTearDown(image.dispose);
    var expired = 0;
    final component = HwandoContactVfxComponent(
      position: Vector2(30, 40),
      direction: Vector2(0, 1),
      image: image,
      onExpired: () => expired += 1,
    );

    expect(component.position, Vector2(30, 40));
    expect(component.size, Vector2.all(36));
    expect(component.facingAngle, closeTo(math.pi / 2, .0001));
    component.update(.149);
    expect(component.isRemoving, isFalse);
    component.update(.001);
    component.update(1);
    expect(component.isRemoving, isTrue);
    expect(expired, 1);
  });
}
