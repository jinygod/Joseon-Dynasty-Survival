import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_level_definitions.dart';
import 'package:pixel_survivor/game/systems/gakgung_executor.dart';

void main() {
  test('관월추성 aims its lead arrow at the strongest enemy', () {
    final weak = _enemy('weak', health: 20, x: 30);
    final strongest = _enemy('strongest', health: 90, x: 80);
    final medium = _enemy('medium', health: 50, x: 60);

    final volley = const GakgungExecutor().plan(
      GakgungInput(
        level: 6,
        origin: Vector2.zero(),
        enemies: [weak, strongest, medium],
        stats: weaponLevelFor(gakgungShot, 6),
      ),
    );

    expect(volley.shots, hasLength(3));
    expect(volley.shots.first.target, same(strongest));
    expect(volley.shots.first.followUpIndex, 0);
    expect(volley.shots.first.isMasterLead, isTrue);
    expect(
      volley.shots.skip(1).map((shot) => shot.followUpIndex),
      orderedEquals([1, 2]),
    );
    expect(volley.shots.skip(1).every((shot) => !shot.isMasterLead), isTrue);
  });

  test('ordinary gakgung keeps nearest-target spread behavior', () {
    final nearest = _enemy('nearest', health: 20, x: 30);
    final far = _enemy('far', health: 90, x: 80);

    final volley = const GakgungExecutor().plan(
      GakgungInput(
        level: 5,
        origin: Vector2.zero(),
        enemies: [far, nearest],
        stats: weaponLevelFor(gakgungShot, 5),
      ),
    );

    expect(volley.shots, hasLength(2));
    expect(volley.shots.every((shot) => shot.target == nearest), isTrue);
    expect(volley.shots.every((shot) => !shot.isMasterLead), isTrue);
  });
}

EnemyComponent _enemy(String id, {required double health, required double x}) =>
    EnemyComponent(
      enemyId: id,
      maxHealth: health,
      moveSpeed: 0,
      damage: 1,
      position: Vector2(x, 0),
    );
