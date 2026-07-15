import '../components/enemy_component.dart';
import '../components/player_component.dart';

class CombatSystem {
  static const contactCooldownSeconds = 0.5;

  final Map<EnemyComponent, double> _nextContactAt = {};

  bool applyContactDamage({
    required PlayerComponent player,
    required EnemyComponent enemy,
    required double now,
    double incomingDamageMultiplier = 1,
  }) {
    if (now < (_nextContactAt[enemy] ?? 0) ||
        enemy.isDead ||
        !player.isAlive ||
        !enemy.overlapsPlayer(player)) {
      return false;
    }

    final safeDamageMultiplier = incomingDamageMultiplier.isFinite
        ? incomingDamageMultiplier.clamp(0, double.infinity).toDouble()
        : 1.0;
    if (!player.takeDamage(enemy.damage * safeDamageMultiplier, now: now)) {
      return false;
    }
    enemy.playAttack();
    _nextContactAt[enemy] = now + contactCooldownSeconds;
    return true;
  }

  void forget(EnemyComponent enemy) => _nextContactAt.remove(enemy);

  void reset() => _nextContactAt.clear();
}
