import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/combat/attack_spec.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/components/five_color_ward_component.dart';
import 'package:pixel_survivor/game/content/combat_visual_factory.dart';

void main() {
  EnemyComponent enemyAt(double x) => EnemyComponent(
    enemyId: 'target',
    maxHealth: 100,
    moveSpeed: 50,
    damage: 1,
    position: Vector2(x, 0),
    size: Vector2.all(10),
  );

  AttackInstance attack() => AttackInstance(
    spec: AttackSpec(
      id: 'talisman_ward',
      shape: AttackShape.circle,
      damage: 4,
      range: 0,
      angleRadians: 0,
      radius: 30,
      width: 0,
      windupSeconds: 0,
      activeSeconds: .1,
      lingerSeconds: 1.5,
      knockback: 2,
      slowFraction: .25,
      traits: const {AttackTrait.explosion},
      presentation: AttackPresentation.strong,
    ),
    origin: Vector2.zero(),
    direction: Vector2(1, 0),
    sequenceIndex: 0,
  );

  test('ticks damage in range and exposes its slow only in range', () {
    final ward = FiveColorWardComponent(attack: attack(), tickSeconds: .5);
    final inside = enemyAt(20);
    final outside = enemyAt(40);

    ward.update(.5);
    final events = ward.collectDamageEvents([inside, outside]);

    expect(events, hasLength(1));
    expect(events.single.target, same(inside));
    expect(events.single.damage, 4);
    expect(ward.slowFor(inside), .25);
    expect(ward.slowFor(outside), 0);
  });

  test('catches up ticks and expires at the attack linger duration', () {
    final ward = FiveColorWardComponent(attack: attack(), tickSeconds: .5);
    final target = enemyAt(0);

    ward.update(1.5);

    expect(ward.collectDamageEvents([target]), hasLength(3));
    expect(ward.isExpired, isTrue);
  });

  test('critical ward damage and spirit bonus are applied per target', () {
    final criticalAttack = AttackInstance(
      spec: attack().spec,
      origin: Vector2.zero(),
      direction: Vector2(1, 0),
      sequenceIndex: 0,
      isCritical: true,
    );
    final ward = FiveColorWardComponent(
      attack: criticalAttack,
      tickSeconds: .5,
    );
    final ordinary = enemyAt(10);
    final spirit = EnemyComponent(
      enemyId: 'vengeful_spirit',
      maxHealth: 100,
      moveSpeed: 0,
      damage: 1,
      position: Vector2(15, 0),
      size: Vector2.all(10),
    );

    ward.update(.5);
    final events = ward.collectDamageEvents([ordinary, spirit]);

    expect(
      events.singleWhere((event) => identical(event.target, ordinary)).damage,
      8,
    );
    expect(
      events.singleWhere((event) => identical(event.target, spirit)).damage,
      10,
    );
    expect(events.every((event) => event.isCritical), isTrue);
  });

  test('master ward selects a cached registry presentation', () {
    final masterAttack = AttackInstance(
      spec: AttackSpec(
        id: 'talisman_ward',
        shape: AttackShape.circle,
        damage: 4,
        range: 0,
        angleRadians: 0,
        radius: 30,
        width: 0,
        windupSeconds: 0,
        activeSeconds: .1,
        lingerSeconds: 1.5,
        knockback: 2,
        slowFraction: .25,
        traits: const {AttackTrait.explosion},
        presentation: AttackPresentation.master,
      ),
      origin: Vector2.zero(),
      direction: Vector2(1, 0),
      sequenceIndex: 0,
    );
    final ward = FiveColorWardComponent(
      attack: masterAttack,
      visualFactory: const CombatVisualFactory(images: {}),
    );

    expect(ward.visualEffectId, 'talisman_master_ward');
    expect(ward.usesRegistryVisual, isTrue);
    expect(ward.startsImageLoadOnMount, isFalse);
    expect(ward.ownsDamageResolution, isFalse);
    expect(ward.gameplayOwnsDamageResolution, isTrue);
    expect(ward.registryVisualLocalPosition, Vector2(30, 30));
    expect(ward.registryVisualScale, Vector2.all(60 / 128));
  });
}
