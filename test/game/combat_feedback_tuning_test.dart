import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/enemy_component.dart';
import 'package:pixel_survivor/game/components/player_component.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';
import 'package:pixel_survivor/game/game_performance_budget.dart';
import 'package:pixel_survivor/game/systems/combat_feedback_tuning.dart';
import 'package:pixel_survivor/game/systems/combat_system.dart';

void main() {
  test('different enemies cannot stack contact damage during immunity', () {
    final combat = CombatSystem();
    final player = _player();
    final first = _enemy();
    final second = _enemy();

    expect(
      combat.applyContactDamage(player: player, enemy: first, now: 1),
      isTrue,
    );
    expect(
      combat.applyContactDamage(player: player, enemy: second, now: 1.1),
      isFalse,
    );
    expect(player.currentHealth, 92);
    expect(
      combat.applyContactDamage(
        player: player,
        enemy: second,
        now: 1 + CombatFeedbackTuning.playerInvulnerabilitySeconds,
      ),
      isTrue,
    );
    expect(player.currentHealth, 84);
  });

  test('repeated knockback impulses cannot exceed the tuning cap', () {
    final enemy = _enemy();
    enemy.applyKnockback(Vector2(100, 0));
    enemy.applyKnockback(Vector2(100, 0));

    expect(
      enemy.knockbackVelocity.length,
      closeTo(CombatFeedbackTuning.maxEnemyKnockbackSpeed, 0.001),
    );
  });

  test('mobile feedback limits stay inside readability targets', () {
    expect(CombatFeedbackTuning.playerInvulnerabilitySeconds, 0.35);
    expect(GamePerformanceBudget.standard.maxDamageNumbers, 24);
    expect(CombatFeedbackTuning.screenShakeDurationSeconds, 0.12);
    expect(CombatFeedbackTuning.maxScreenShakeMagnitude, 4);
  });
}

PlayerComponent _player() => PlayerComponent(
  slotIndex: 0,
  maxHealth: 100,
  moveSpeed: 80,
  position: Vector2.zero(),
);

EnemyComponent _enemy() => EnemyComponent(
  enemyId: bandit,
  maxHealth: 18,
  moveSpeed: 0,
  damage: 8,
  position: Vector2.zero(),
);
