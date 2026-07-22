import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/combat/combat_vfx_primitives.dart';

void main() {
  test('master tier has a larger visual scale than normal', () {
    expect(CombatVfxTier.master.scale, greaterThan(CombatVfxTier.normal.scale));
  });

  test('radial samples are capped and deterministic', () {
    expect(
      radialSamples(count: 99).length,
      CombatVfxPrimitives.maxBurstSamples,
    );
    expect(radialSamples(count: 8), radialSamples(count: 8));
  });

  test(
    'canvas helpers accept exact geometry with bounded decoration counts',
    () {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const center = Offset(40, 40);
      const palette = CombatVfxPalette(
        core: Color(0xffeafcff),
        edge: Color(0xff7bdff2),
        accent: Color(0xffffd166),
        smoke: Color(0xff263849),
      );

      expect(() {
        CombatVfxPrimitives.drawTaperedTrail(
          canvas,
          start: const Offset(8, 32),
          end: const Offset(72, 48),
          startWidth: 14,
          endWidth: 3,
          palette: palette,
          progress: .4,
          count: 99,
          tier: CombatVfxTier.strong,
        );
        CombatVfxPrimitives.drawRadialBurst(
          canvas,
          center: center,
          radius: 28,
          palette: palette,
          progress: .4,
          count: 99,
          tier: CombatVfxTier.master,
        );
        CombatVfxPrimitives.drawRuneRing(
          canvas,
          center: center,
          radius: 24,
          palette: palette,
          progress: .4,
          count: 99,
        );
        CombatVfxPrimitives.drawCrystal(
          canvas,
          center: center,
          radius: 12,
          palette: palette,
          progress: .4,
          count: 99,
        );
        CombatVfxPrimitives.drawChevronLane(
          canvas,
          start: const Offset(8, 40),
          end: const Offset(72, 40),
          halfWidth: 10,
          palette: palette,
          progress: .4,
          count: 99,
        );
        CombatVfxPrimitives.drawSmokePuff(
          canvas,
          center: center,
          radius: 20,
          palette: palette,
          progress: .4,
          count: 99,
        );
      }, returnsNormally);

      recorder.endRecording();
    },
  );
}
