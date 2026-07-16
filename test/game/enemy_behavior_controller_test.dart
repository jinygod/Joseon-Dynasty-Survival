import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/enemy_behavior_definitions.dart';
import 'package:pixel_survivor/game/content/ids.dart';
import 'package:pixel_survivor/game/systems/enemy_behavior_controller.dart';

void main() {
  test('warning locks target direction before thrust activation', () {
    final controller = EnemyBehaviorController(
      profile: enemyBehaviorProfiles['spear_thrust']!,
    );
    for (var i = 0; i < 45; i++) {
      controller.tick(dt: .05, origin: Vector2.zero(), target: Vector2(10, 0));
    }
    expect(controller.phase, EnemyBehaviorPhase.warning);

    EnemyAttackRequest? attack;
    for (var i = 0; i < 12 && attack == null; i++) {
      attack = controller
          .tick(dt: .05, origin: Vector2.zero(), target: Vector2(0, 10))
          .attack;
    }

    expect(attack, isNotNull);
    expect(attack!.kind, EnemyAttackKind.thrust);
    expect(attack.direction.x, closeTo(1, .001));
    expect(attack.direction.y, closeTo(0, .001));
  });

  test('assassin emits exactly two locked dashes before cooldown', () {
    final controller = EnemyBehaviorController(
      profile: enemyBehaviorProfiles['assassin_double_dash']!,
    );
    final attacks = <EnemyAttackRequest>[];
    var reachedCooldown = false;
    for (var i = 0; i < 500; i++) {
      final result = controller.tick(
        dt: .02,
        origin: Vector2.zero(),
        target: Vector2(100, 0),
      );
      if (result.attack != null) attacks.add(result.attack!);
      if (result.phase == EnemyBehaviorPhase.cooldown) {
        reachedCooldown = true;
        break;
      }
    }

    expect(reachedCooldown, isTrue);
    expect(
      attacks.where((attack) => attack.kind == EnemyAttackKind.dash),
      hasLength(2),
    );
    expect(attacks.every((attack) => attack.direction.x > .99), isTrue);
  });

  test('non-finite negative and oversized deltas are safely bounded', () {
    final controller = EnemyBehaviorController(
      profile: enemyBehaviorProfiles['spear_thrust']!,
    );
    controller.tick(
      dt: double.nan,
      origin: Vector2.zero(),
      target: Vector2.zero(),
    );
    controller.tick(dt: -1, origin: Vector2.zero(), target: Vector2.zero());
    final before = controller.phaseElapsed;
    controller.tick(dt: 10, origin: Vector2.zero(), target: Vector2.zero());
    expect(controller.phaseElapsed - before, closeTo(.05, .001));
  });
}
