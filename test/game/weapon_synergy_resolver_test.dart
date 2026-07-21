import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/combat/attack_spec.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/systems/weapon_synergy_resolver.dart';

void main() {
  test(
    'second hwando hit consumes mark, explodes, and transfers bounded marks',
    () {
      final center = enemy('center', Vector2.zero());
      final enemies = <EnemyComponent>[
        center,
        for (var index = 0; index < 5; index += 1)
          enemy('nearby_$index', Vector2(10.0 + index, 0)),
      ];
      final resolver = WeaponSynergyResolver();

      final first = resolver.onHwandoHit(
        target: center,
        nearby: enemies,
        now: 1,
        originatingAttackId: 1,
      );
      final result = resolver.onHwandoHit(
        target: center,
        nearby: enemies,
        now: 2,
        originatingAttackId: 2,
      );

      expect(first.attack, isNull);
      expect(first.markedTargets, [center]);
      expect(result.attack?.spec.id, sealingSlash);
      expect(result.attack?.spec.presentation, AttackPresentation.synergy);
      expect(result.attack?.spec.traits, contains(AttackTrait.synergy));
      expect(result.markedTargets, hasLength(3));
      expect(result.showFirstActivationNotice, isTrue);
      expect(
        resolver
            .onHwandoHit(
              target: center,
              nearby: enemies,
              now: 3,
              originatingAttackId: 3,
            )
            .showFirstActivationNotice,
        isFalse,
      );
    },
  );

  test('dead and removed marked targets are cleaned before resolving hits', () {
    final dead = enemy('dead', Vector2.zero());
    final removed = enemy('removed', Vector2(5, 0));
    final resolver = WeaponSynergyResolver();
    resolver.onHwandoHit(
      target: dead,
      nearby: [dead, removed],
      now: 1,
      originatingAttackId: 1,
    );
    resolver.onHwandoHit(
      target: removed,
      nearby: [dead, removed],
      now: 1,
      originatingAttackId: 1,
    );
    dead.takeDamage(dead.maxHealth);
    removed.takeDamage(removed.maxHealth);

    final result = resolver.onHwandoHit(
      target: dead,
      nearby: [dead, removed],
      now: 2,
      originatingAttackId: 2,
    );

    expect(result.attack, isNull);
    expect(resolver.markedTargets, isEmpty);
  });

  test('one originating attack cannot detonate the same target twice', () {
    final center = enemy('center', Vector2.zero());
    final resolver = WeaponSynergyResolver();
    resolver.onHwandoHit(
      target: center,
      nearby: [center],
      now: 1,
      originatingAttackId: 1,
    );

    final first = resolver.onHwandoHit(
      target: center,
      nearby: [center],
      now: 2,
      originatingAttackId: 2,
    );
    final duplicate = resolver.onHwandoHit(
      target: center,
      nearby: [center],
      now: 2,
      originatingAttackId: 2,
    );

    expect(first.attack, isNotNull);
    expect(duplicate.attack, isNull);
    expect(resolver.markedTargets, isEmpty);
  });

  test(
    'marks transferred by an attack wait for a later originating attack',
    () {
      final center = enemy('center', Vector2.zero());
      final transfer = enemy('transfer', Vector2(10, 0));
      final resolver = WeaponSynergyResolver();
      resolver.onHwandoHit(
        target: center,
        nearby: [center, transfer],
        now: 1,
        originatingAttackId: 1,
      );
      resolver.onHwandoHit(
        target: center,
        nearby: [center, transfer],
        now: 2,
        originatingAttackId: 2,
      );

      final sameAttack = resolver.onHwandoHit(
        target: transfer,
        nearby: [center, transfer],
        now: 2,
        originatingAttackId: 2,
      );
      final laterAttack = resolver.onHwandoHit(
        target: transfer,
        nearby: [center, transfer],
        now: 3,
        originatingAttackId: 3,
      );

      expect(sameAttack.attack, isNull);
      expect(laterAttack.attack?.spec.id, sealingSlash);
    },
  );

  test('detonation freezes shared geometry at the marked target position', () {
    final center = enemy('center', Vector2(20, 30));
    final resolver = WeaponSynergyResolver();
    resolver.onHwandoHit(
      target: center,
      nearby: [center],
      now: 1,
      originatingAttackId: 1,
    );
    final attack = resolver
        .onHwandoHit(
          target: center,
          nearby: [center],
          now: 2,
          originatingAttackId: 2,
        )
        .attack!;

    center.position.setValues(90, 100);

    expect(attack.origin, Vector2(20, 30));
  });
}

EnemyComponent enemy(String id, Vector2 position) => EnemyComponent(
  enemyId: id,
  maxHealth: 100,
  moveSpeed: 0,
  damage: 0,
  position: position,
);
