import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/combat/attack_spec.dart';
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

  test('level five kill refund cannot exceed its per-cycle cap', () {
    final executor = HwandoExecutor();
    executor.tick(input(dt: 0, level: 5));
    executor.recordKill(count: 100);

    for (var frame = 0; frame < 9; frame += 1) {
      expect(
        executor.tick(input(dt: .05, level: 5)),
        isNot(
          contains(
            isA<AttackInstance>().having(
              (a) => a.sequenceIndex,
              'sequenceIndex',
              0,
            ),
          ),
        ),
      );
    }
    expect(
      executor.tick(input(dt: .05, level: 5)).map((a) => a.sequenceIndex),
      contains(0),
    );
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

    expect(first.single.direction, Vector2(0, -1));
    expect(second.single.direction, Vector2(0, -1));
  });

  test(
    'master queues targeted opener, two half sweeps, circle, and finisher',
    () {
      final executor = HwandoExecutor();
      final emitted = <AttackInstance>[];
      for (var frame = 0; frame < 40; frame++) {
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
    },
  );
}
