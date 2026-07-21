import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/combat/attack_spec.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/systems/talisman_executor.dart';

void main() {
  EnemyComponent enemy(String id, double x, [double y = 0]) => EnemyComponent(
    enemyId: id,
    maxHealth: 100,
    moveSpeed: 0,
    damage: 1,
    position: Vector2(x, y),
  );

  TalismanTickInput input({
    required double now,
    required int level,
    required List<EnemyComponent> enemies,
    double dt = 0,
  }) => TalismanTickInput(
    dt: dt,
    level: level,
    now: now,
    origin: Vector2.zero(),
    enemies: enemies,
    damageMultiplier: 1,
    sizeMultiplier: 1,
  );

  test('level three attaches first and explodes after its delay', () {
    final target = enemy('target', 20);
    final executor = TalismanExecutor();

    final attached = executor.tick(
      input(now: 0, level: 3, enemies: [target], dt: 2),
    );
    expect(attached.attached.single.target, same(target));
    expect(attached.attacks, isEmpty);

    final early = executor.tick(input(now: .59, level: 3, enemies: [target]));
    expect(early.attacks, isEmpty);
    final exploded = executor.tick(input(now: .6, level: 3, enemies: [target]));
    expect(exploded.attacks.single.spec.shape, AttackShape.circle);
    expect(exploded.attached, isEmpty);
  });

  test('level four transfer chooses an unmarked living target', () {
    final first = enemy('first', 20);
    final alreadyMarked = enemy('marked', 24);
    final next = enemy('next', 28);
    final executor = TalismanExecutor();
    executor.tick(input(now: 0, level: 4, enemies: [first], dt: 2));
    executor.tick(
      input(now: .1, level: 4, enemies: [first, alreadyMarked], dt: 2),
    );
    alreadyMarked.takeDamage(alreadyMarked.maxHealth);

    final result = executor.tick(
      input(now: .6, level: 4, enemies: [first, alreadyMarked, next]),
    );

    expect(result.attached.map((seal) => seal.target), contains(next));
    expect(
      result.attached.map((seal) => seal.target),
      isNot(contains(alreadyMarked)),
    );
  });

  test('level five explosion requests a small ward', () {
    final target = enemy('target', 20);
    final executor = TalismanExecutor();
    executor.tick(input(now: 0, level: 5, enemies: [target], dt: 2));

    final result = executor.tick(input(now: .6, level: 5, enemies: [target]));

    expect(result.wards, hasLength(1));
    expect(result.wards.single.presentation, AttackPresentation.strong);
  });

  test('attached seals and transfer depth stay bounded', () {
    final enemies = List.generate(
      30,
      (index) => enemy('enemy_$index', 10.0 + index),
    );
    final executor = TalismanExecutor();
    for (var index = 0; index < enemies.length; index += 1) {
      executor.tick(
        TalismanTickInput(
          dt: 2,
          level: 4,
          now: index * .01,
          origin: enemies[index].position,
          enemies: enemies,
          damageMultiplier: 1,
          sizeMultiplier: 1,
        ),
      );
    }

    expect(executor.attached, hasLength(TalismanExecutor.maxAttachedSeals));

    var now = 1.0;
    for (var cycle = 0; cycle < 4; cycle += 1) {
      final result = executor.tick(input(now: now, level: 4, enemies: enemies));
      expect(
        result.attached.every(
          (seal) => seal.transferDepth <= TalismanExecutor.maxTransferDepth,
        ),
        isTrue,
      );
      now += 1;
    }
  });

  test('level six creates at most three distinct master wards', () {
    final clustered = <EnemyComponent>[
      for (var group = 0; group < 4; group += 1)
        for (var index = 0; index < 3; index += 1)
          enemy('g${group}_$index', group * 120.0 + index * 3, index * 2),
    ];

    final result = TalismanExecutor().tick(
      input(now: 2, level: 6, enemies: clustered, dt: 2),
    );

    expect(result.wards, hasLength(3));
    expect(
      result.wards.map((ward) => ward.position.toString()).toSet(),
      hasLength(3),
    );
    expect(
      result.wards.every(
        (ward) => ward.presentation == AttackPresentation.master,
      ),
      isTrue,
    );
  });

  test('dead attached targets are cleaned up and reported', () {
    final target = enemy('target', 20);
    final executor = TalismanExecutor();
    executor.tick(input(now: 0, level: 3, enemies: [target], dt: 2));
    target.takeDamage(target.maxHealth);

    final result = executor.tick(input(now: .1, level: 3, enemies: [target]));

    expect(result.attached, isEmpty);
    expect(result.removedTargetIds, contains('target'));
  });

  test('critical roll is frozen while a talisman remains attached', () {
    final target = enemy('target', 20);
    final executor = TalismanExecutor(random: Random(1));
    executor.tick(
      TalismanTickInput(
        dt: 2,
        level: 3,
        now: 0,
        origin: Vector2.zero(),
        enemies: [target],
        damageMultiplier: 1,
        sizeMultiplier: 1,
        criticalChance: 1,
      ),
    );

    final result = executor.tick(
      TalismanTickInput(
        dt: 0,
        level: 3,
        now: .6,
        origin: Vector2.zero(),
        enemies: [target],
        damageMultiplier: 1,
        sizeMultiplier: 1,
        criticalChance: 0,
      ),
    );

    expect(result.attacks.single.isCritical, isTrue);
    expect(result.attacks.single.spec.damage, 12);
  });

  test('level six seal explosions remain ordinary strong attacks', () {
    final targets = [enemy('a', 20), enemy('b', 25)];
    final executor = TalismanExecutor();
    executor.tick(input(now: 0, level: 6, enemies: targets, dt: 2));

    final result = executor.tick(input(now: .6, level: 6, enemies: targets));

    expect(result.attacks, isNotEmpty);
    expect(
      result.attacks.every(
        (attack) =>
            attack.spec.presentation == AttackPresentation.strong &&
            !attack.spec.traits.contains(AttackTrait.master),
      ),
      isTrue,
    );
  });
}
