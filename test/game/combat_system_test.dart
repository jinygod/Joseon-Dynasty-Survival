import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/components/player_component.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';
import 'package:pixel_survivor/game/systems/combat_system.dart';

void main() {
  test('same enemy cannot deal contact damage during cooldown', () {
    final combat = CombatSystem();
    final player = PlayerComponent(
      slotIndex: 0,
      maxHealth: 100,
      moveSpeed: 80,
      position: Vector2.zero(),
    );
    final enemy = EnemyComponent(
      enemyId: bandit,
      maxHealth: 18,
      moveSpeed: 0,
      damage: 8,
      position: Vector2.zero(),
    );

    expect(
      combat.applyContactDamage(player: player, enemy: enemy, now: 1),
      isTrue,
    );
    expect(player.currentHealth, 92);
    expect(
      combat.applyContactDamage(player: player, enemy: enemy, now: 1.2),
      isFalse,
    );
    expect(player.currentHealth, 92);
    expect(
      combat.applyContactDamage(player: player, enemy: enemy, now: 1.6),
      isTrue,
    );
    expect(player.currentHealth, 84);
  });

  test('contact damage requires overlap', () {
    final combat = CombatSystem();
    final player = PlayerComponent(
      slotIndex: 0,
      maxHealth: 100,
      moveSpeed: 80,
      position: Vector2.zero(),
    );
    final enemy = EnemyComponent(
      enemyId: bandit,
      maxHealth: 18,
      moveSpeed: 0,
      damage: 8,
      position: Vector2(100, 0),
    );

    expect(
      combat.applyContactDamage(player: player, enemy: enemy, now: 1),
      isFalse,
    );
    expect(player.currentHealth, 100);
  });
}
