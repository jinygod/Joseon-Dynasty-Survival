import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/enemy_hazard_component.dart';
import 'package:pixel_survivor/game/components/player_component.dart';

void main() {
  test('poison damages once per interval and expires', () {
    final hazard = EnemyHazardComponent.poison(
      position: Vector2.zero(),
      damage: 4,
      sourceId: 'herbalist',
    );
    final player = PlayerComponent(
      slotIndex: 0,
      maxHealth: 100,
      moveSpeed: 100,
      position: Vector2.zero(),
    );

    expect(hazard.damageFor(player), 4);
    expect(hazard.damageFor(player), 0);
    hazard.update(.5);
    expect(hazard.damageFor(player), 4);
    hazard.update(3.5);
    expect(hazard.isExpired, isTrue);
    expect(hazard.damageFor(player), 0);
  });

  test('hazard does not damage players outside its radius', () {
    final hazard = EnemyHazardComponent.shockwave(
      position: Vector2.zero(),
      radius: 20,
      damage: 10,
      sourceId: 'jangseung',
    );
    final player = PlayerComponent(
      slotIndex: 0,
      maxHealth: 100,
      moveSpeed: 100,
      position: Vector2(100, 0),
    );

    expect(hazard.damageFor(player), 0);
  });

  test('hazard visual boundary exceeds gameplay damage boundary', () {
    final hazard = EnemyHazardComponent.poison(
      position: Vector2.zero(),
      damage: 1,
      sourceId: 'test',
    );
    expect(hazard.damageRadius, hazard.radius);
    expect(hazard.visualRadius, greaterThanOrEqualTo(hazard.damageRadius + 12));
    expect(
      hazard.visualScale * EnemyHazardComponent.reviewedActiveDiameter,
      greaterThanOrEqualTo(hazard.visualRadius * 2),
    );
    expect(hazard.ownsDamageResolution, isFalse);
    expect(hazard.startsImageLoadOnMount, isFalse);
  });
}
