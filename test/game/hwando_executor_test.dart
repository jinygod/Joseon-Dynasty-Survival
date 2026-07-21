import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/combat/attack_spec.dart';
import 'package:pixel_survivor/game/combat/attack_geometry.dart';
import 'package:pixel_survivor/game/components/attack_effect_component.dart';
import 'package:pixel_survivor/game/systems/hwando_executor.dart';

void main() {
  HwandoTickInput input({
    required double dt,
    required int level,
    Vector2? aimDirection,
  }) => HwandoTickInput(
    dt: dt,
    level: level,
    origin: Vector2.zero(),
    aimDirection: aimDirection ?? Vector2(1, 0),
    damageMultiplier: 1,
    sizeMultiplier: 1,
  );

  test('level one emits one targeted sector slash', () {
    final attacks = HwandoExecutor().tick(
      input(dt: .02, level: 1, aimDirection: Vector2(0, -1)),
    );

    expect(attacks, hasLength(1));
    expect(attacks.single.spec.id, 'hwando_slash');
    expect(attacks.single.spec.shape, AttackShape.sector);
    expect(attacks.single.direction, Vector2(0, -1));
  });

  test('level three separates its two slashes in time', () {
    final executor = HwandoExecutor();

    expect(executor.tick(input(dt: .02, level: 3)).map((a) => a.spec.id), [
      'hwando_slash_left',
    ]);
    expect(executor.tick(input(dt: .05, level: 3)), isEmpty);
    expect(executor.tick(input(dt: .05, level: 3)).map((a) => a.spec.id), [
      'hwando_slash_right',
    ]);
  });

  test('level three opposite slashes freeze distinct coverage directions', () {
    final executor = HwandoExecutor();
    final first = executor.tick(input(dt: 0, level: 3)).single;
    executor.tick(input(dt: .05, level: 3));
    final second = executor.tick(input(dt: .05, level: 3)).single;

    expect(first.direction, isNot(second.direction));
    final firstOnly = first.direction * 45;
    expect(AttackGeometry.contains(first, firstOnly, 0), isTrue);
    expect(AttackGeometry.contains(second, firstOnly, 0), isFalse);
  });

  test('level four emits a line blade wave after the second slash', () {
    final executor = HwandoExecutor();
    final emitted = <AttackInstance>[];
    for (var frame = 0; frame < 12; frame += 1) {
      emitted.addAll(executor.tick(input(dt: .02, level: 4)));
    }

    expect(emitted.map((a) => a.spec.id), [
      'hwando_slash_left',
      'hwando_slash_right',
      'hwando_blade_wave',
    ]);
    expect(emitted.last.spec.shape, AttackShape.line);
  });

  test('cooldown progresses while scheduled stages remain', () {
    final executor = HwandoExecutor();
    final emitted = <AttackInstance>[];
    emitted.addAll(executor.tick(input(dt: 0, level: 4)));

    for (var frame = 0; frame < 32; frame += 1) {
      emitted.addAll(executor.tick(input(dt: .02, level: 4)));
    }

    expect(emitted.where((attack) => attack.sequenceIndex == 0), hasLength(2));
  });

  test('level five huge kill refund is capped at exactly point two four', () {
    expect(HwandoExecutor.maxKillRefundPerCycle, .24);
    final hugeRefund = HwandoExecutor();
    final cappedRefund = HwandoExecutor();
    final hugeEmitted = <AttackInstance>[];
    final cappedEmitted = <AttackInstance>[];
    hugeEmitted.addAll(hugeRefund.tick(input(dt: 0, level: 5)));
    cappedEmitted.addAll(cappedRefund.tick(input(dt: 0, level: 5)));
    hugeRefund.recordKill(count: 100);
    cappedRefund.recordKill(count: 4);

    for (var frame = 0; frame < 5; frame += 1) {
      hugeEmitted.addAll(hugeRefund.tick(input(dt: .05, level: 5)));
      cappedEmitted.addAll(cappedRefund.tick(input(dt: .05, level: 5)));
    }
    expect(
      hugeEmitted.where((attack) => attack.sequenceIndex == 0),
      hasLength(1),
    );

    hugeEmitted.addAll(hugeRefund.tick(input(dt: .05, level: 5)));
    cappedEmitted.addAll(cappedRefund.tick(input(dt: .05, level: 5)));
    expect(
      hugeEmitted.where((attack) => attack.sequenceIndex == 0),
      hasLength(2),
    );
    expect(
      hugeEmitted.map((attack) => attack.spec.id),
      cappedEmitted.map((attack) => attack.spec.id),
    );
  });

  test('a new level five cycle resets the kill refund allowance', () {
    final executor = HwandoExecutor();
    final emitted = <AttackInstance>[];
    emitted.addAll(executor.tick(input(dt: 0, level: 5)));
    executor.recordKill(count: 100);
    for (var frame = 0; frame < 6; frame += 1) {
      emitted.addAll(executor.tick(input(dt: .05, level: 5)));
    }
    expect(emitted.where((attack) => attack.sequenceIndex == 0), hasLength(2));

    executor.recordKill(count: 100);
    for (var frame = 0; frame < 5; frame += 1) {
      emitted.addAll(executor.tick(input(dt: .05, level: 5)));
    }
    expect(emitted.where((attack) => attack.sequenceIndex == 0), hasLength(2));

    emitted.addAll(executor.tick(input(dt: .05, level: 5)));
    expect(emitted.where((attack) => attack.sequenceIndex == 0), hasLength(3));
  });

  test('queued stages retain the direction frozen at cycle start', () {
    final executor = HwandoExecutor();
    final first = executor.tick(
      input(dt: 0, level: 3, aimDirection: Vector2(0, -1)),
    );
    executor.tick(input(dt: .05, level: 3, aimDirection: Vector2(1, 0)));
    final second = executor.tick(
      input(dt: .05, level: 3, aimDirection: Vector2(1, 0)),
    );

    expect(first.single.direction.x, closeTo(-sqrt1_2, 0.000001));
    expect(first.single.direction.y, closeTo(-sqrt1_2, 0.000001));
    expect(second.single.direction.x, closeTo(sqrt1_2, 0.000001));
    expect(second.single.direction.y, closeTo(-sqrt1_2, 0.000001));
  });

  test(
    'master queues targeted opener, two half sweeps, circle, and finisher',
    () {
      final executor = HwandoExecutor();
      final emitted = <AttackInstance>[];
      for (var frame = 0; frame < 24; frame++) {
        emitted.addAll(
          executor.tick(input(dt: .02, level: 6, aimDirection: Vector2(0, -1))),
        );
      }
      expect(emitted.map((a) => a.spec.id), [
        'hwando_master_opener',
        'hwando_master_left',
        'hwando_master_right',
        'hwando_master_circle',
        'hwando_master_finisher',
      ]);
      expect(
        emitted.every((a) => a.spec.traits.contains(AttackTrait.master)),
        isTrue,
      );
      expect(
        emitted.every((a) => a.spec.traits.contains(AttackTrait.melee)),
        isTrue,
      );
      expect(emitted[1].spec.angleRadians, pi);
      expect(emitted[2].spec.angleRadians, pi);
      expect(emitted[0].direction, isNot(emitted[1].direction));
      expect(
        emitted[1].direction.x,
        closeTo(-emitted[2].direction.x, 0.000001),
      );
      expect(
        emitted[1].direction.y,
        closeTo(-emitted[2].direction.y, 0.000001),
      );
      final leftOnly = emitted[1].direction * 45;
      expect(AttackGeometry.contains(emitted[1], leftOnly, 0), isTrue);
      expect(AttackGeometry.contains(emitted[2], leftOnly, 0), isFalse);
    },
  );

  test('renderer reflects the exact distinct level three instances', () async {
    final executor = HwandoExecutor();
    final first = executor.tick(input(dt: 0, level: 3)).single;
    executor.tick(input(dt: .05, level: 3));
    final second = executor.tick(input(dt: .05, level: 3)).single;

    expect(await _renderBytes(first), isNot(await _renderBytes(second)));
  });

  test('master starts its next cycle on configured cooldown', () {
    final executor = HwandoExecutor();
    final emitted = <AttackInstance>[];
    emitted.addAll(executor.tick(input(dt: 0, level: 6)));

    for (var frame = 0; frame < 30; frame += 1) {
      emitted.addAll(executor.tick(input(dt: .02, level: 6)));
    }

    expect(emitted.where((attack) => attack.sequenceIndex == 0), hasLength(2));
  });
}

Future<Uint8List> _renderBytes(AttackInstance instance) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)..translate(100, 100);
  AttackEffectComponent(instance: instance).render(canvas);
  final image = await recorder.endRecording().toImage(200, 200);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  return data!.buffer.asUint8List();
}
