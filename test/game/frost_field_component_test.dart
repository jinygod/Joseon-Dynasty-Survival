import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/combat/combat_vfx_primitives.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/components/frost_field_component.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';

void main() {
  EnemyComponent enemyAt(double x) => EnemyComponent(
    enemyId: 'test_enemy',
    maxHealth: 20,
    moveSpeed: 50,
    damage: 1,
    position: Vector2(x, 0),
    size: Vector2.all(10),
  );

  test('ticks every half second and only damages enemies in range', () {
    final field = FrostFieldComponent(
      weaponId: frostFlask,
      damage: 4,
      radius: 30,
      durationSeconds: 2,
      tickSeconds: .5,
      slowFraction: .25,
      knockback: 12,
      position: Vector2.zero(),
    );
    final inside = enemyAt(20);
    final outside = enemyAt(40);

    field.update(.49);
    expect(field.collectDamageEvents([inside, outside]), isEmpty);
    field.update(.01);
    final events = field.collectDamageEvents([inside, outside]);

    expect(events, hasLength(1));
    expect(events.single.target, same(inside));
    expect(events.single.damage, 4);
    expect(events.single.weaponId, frostFlask);
  });

  test('catches up missed ticks and expires at its duration', () {
    final field = FrostFieldComponent(
      weaponId: frostFlask,
      damage: 3,
      radius: 30,
      durationSeconds: 1.5,
      tickSeconds: .5,
      slowFraction: .2,
      knockback: 0,
      position: Vector2.zero(),
    );
    final enemy = enemyAt(0);

    field.update(1.5);

    expect(field.collectDamageEvents([enemy]), hasLength(3));
    expect(field.isExpired, isTrue);
  });

  test('visual tiers leave the hit radius unchanged', () {
    FrostFieldComponent createField(CombatVfxTier tier) => FrostFieldComponent(
      weaponId: frostFlask,
      damage: 4,
      radius: 30,
      durationSeconds: 2,
      slowFraction: .25,
      knockback: 12,
      position: Vector2.zero(),
      tier: tier,
    );
    final normalField = createField(CombatVfxTier.normal);
    final masterField = createField(CombatVfxTier.master);
    final edgeEnemy = enemyAt(35);

    expect(masterField.visualTier, CombatVfxTier.master);
    expect(normalField.pulseProgress, 0);
    normalField.update(.125);
    expect(normalField.pulseProgress, .25);
    expect(masterField.radius, normalField.radius);
    expect(
      masterField.containsEnemy(edgeEnemy),
      normalField.containsEnemy(edgeEnemy),
    );
  });

  test('frost rune rotates slowly and deterministically from elapsed time', () {
    FrostFieldComponent createField() => FrostFieldComponent(
      weaponId: frostFlask,
      damage: 4,
      radius: 30,
      durationSeconds: 10,
      slowFraction: .25,
      knockback: 12,
      position: Vector2.zero(),
    );
    final singleStep = createField();
    final partitioned = createField();

    expect(singleStep.runeRotationRadians, 0);
    singleStep.update(2);
    partitioned
      ..update(.75)
      ..update(.75)
      ..update(.5);

    expect(singleStep.runeRotationRadians, closeTo(.30, 1e-10));
    expect(partitioned.runeRotationRadians, singleStep.runeRotationRadians);
    expect(singleStep.runeRotationRadians, lessThan(.4));
    expect(singleStep.radius, 30);
    expect(singleStep.size, Vector2.all(60));
  });
}
