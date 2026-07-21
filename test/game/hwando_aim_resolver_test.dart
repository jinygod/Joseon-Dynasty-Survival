import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/content/ids.dart';
import 'package:pixel_survivor/game/systems/hwando_aim_resolver.dart';

void main() {
  group('HwandoAimResolver', () {
    test('selects the nearest alive actor across every enemy rank', () {
      final normal = _enemy('normal', Vector2(30, 0));
      final elite = _enemy('elite', Vector2(20, 0), rank: EnemyRank.elite);
      final boss = _enemy('boss', Vector2(10, 0), rank: EnemyRank.boss);

      final decision = HwandoAimResolver.resolve(
        origin: Vector2.zero(),
        enemies: [normal, elite, boss],
        maxRange: 50,
        fallbackDirection: Vector2(-1, 0),
      );

      expect(decision.target, same(boss));
      expect(decision.direction, Vector2(1, 0));
    });

    test('excludes dead enemies and candidates outside attack range', () {
      final dead = _enemy('dead', Vector2(2, 0))..takeDamage(100);
      final outside = _enemy('outside', Vector2(21, 0));
      final valid = _enemy('valid', Vector2(0, -20));

      final decision = HwandoAimResolver.resolve(
        origin: Vector2.zero(),
        enemies: [dead, outside, valid],
        maxRange: 20,
        fallbackDirection: Vector2(-1, 0),
      );

      expect(decision.target, same(valid));
      expect(decision.direction, Vector2(0, -1));
    });

    test('breaks equal-distance ties by id then stable input order', () {
      final zeta = _enemy('zeta', Vector2(-10, 0));
      final alphaFirst = _enemy('alpha', Vector2(10, 0));
      final alphaSecond = _enemy('alpha', Vector2(0, 10));

      final decision = HwandoAimResolver.resolve(
        origin: Vector2.zero(),
        enemies: [zeta, alphaFirst, alphaSecond],
        maxRange: 20,
        fallbackDirection: Vector2(0, -1),
      );

      expect(decision.target, same(alphaFirst));
      expect(decision.direction, Vector2(1, 0));
    });

    test('normalizes fallback and replaces a zero fallback with right', () {
      final upward = HwandoAimResolver.resolve(
        origin: Vector2.zero(),
        enemies: const [],
        maxRange: 20,
        fallbackDirection: Vector2(0, -4),
      );
      final defaultRight = HwandoAimResolver.resolve(
        origin: Vector2.zero(),
        enemies: const [],
        maxRange: 20,
        fallbackDirection: Vector2.zero(),
      );

      expect(upward.target, isNull);
      expect(upward.direction, Vector2(0, -1));
      expect(defaultRight.direction, Vector2(1, 0));
    });
  });

  flameGame.testGameWidget(
    'excludes an enemy that is scheduled for removal',
    setUp: (game, _) async {
      final removing = _enemy('removing', Vector2(5, 0));
      await game.ensureAdd(removing);
      removing.removeFromParent();
      expect(removing.isRemoving, isTrue);

      final decision = HwandoAimResolver.resolve(
        origin: Vector2.zero(),
        enemies: [removing],
        maxRange: 20,
        fallbackDirection: Vector2(0, 1),
      );

      expect(decision.target, isNull);
      expect(decision.direction, Vector2(0, 1));
    },
  );
}

EnemyComponent _enemy(
  String id,
  Vector2 position, {
  EnemyRank rank = EnemyRank.normal,
}) => EnemyComponent(
  enemyId: id,
  maxHealth: 10,
  moveSpeed: 0,
  damage: 1,
  position: position,
  rank: rank,
);
