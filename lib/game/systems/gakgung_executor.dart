import 'package:flame/components.dart';

import '../components/enemy_component.dart';
import '../content/weapon_level_definitions.dart';

class GakgungInput {
  const GakgungInput({
    required this.level,
    required this.origin,
    required this.enemies,
    required this.stats,
  });

  final int level;
  final Vector2 origin;
  final List<EnemyComponent> enemies;
  final WeaponLevelDefinition stats;
}

class GakgungShot {
  const GakgungShot({
    required this.target,
    required this.direction,
    required this.followUpIndex,
    required this.damageMultiplier,
    required this.visualScale,
    required this.isMasterLead,
  });

  final EnemyComponent target;
  final Vector2 direction;
  final int followUpIndex;
  final double damageMultiplier;
  final double visualScale;
  final bool isMasterLead;
}

class GakgungVolley {
  GakgungVolley(Iterable<GakgungShot> shots) : shots = List.unmodifiable(shots);

  final List<GakgungShot> shots;
}

class GakgungExecutor {
  const GakgungExecutor();

  GakgungVolley plan(GakgungInput input) {
    if (input.enemies.isEmpty || input.level <= 0) {
      return GakgungVolley(const []);
    }
    if (input.level >= 6) return _masterVolley(input);

    final nearest = input.enemies.reduce(
      (current, candidate) =>
          input.origin.distanceToSquared(candidate.position) <
              input.origin.distanceToSquared(current.position)
          ? candidate
          : current,
    );
    final baseDirection = _direction(input.origin, nearest.position);
    return GakgungVolley([
      for (var index = 0; index < input.stats.projectileCount; index += 1)
        GakgungShot(
          target: nearest,
          direction: baseDirection.clone()
            ..rotate((index - (input.stats.projectileCount - 1) / 2) * 0.10),
          followUpIndex: index,
          damageMultiplier: 1,
          visualScale: 1,
          isMasterLead: false,
        ),
    ]);
  }

  GakgungVolley _masterVolley(GakgungInput input) {
    final ordered = [...input.enemies]
      ..sort((left, right) {
        final health = right.currentHealth.compareTo(left.currentHealth);
        if (health != 0) return health;
        return input.origin
            .distanceToSquared(left.position)
            .compareTo(input.origin.distanceToSquared(right.position));
      });
    final lead = ordered.first;
    final targets = [
      lead,
      ordered.length > 1 ? ordered[1] : lead,
      ordered.length > 2 ? ordered[2] : lead,
    ];
    return GakgungVolley([
      for (var index = 0; index < targets.length; index += 1)
        GakgungShot(
          target: targets[index],
          direction: _direction(input.origin, targets[index].position),
          followUpIndex: index,
          damageMultiplier: index == 0 ? 1.35 : .82,
          visualScale: index == 0 ? 1.8 : 1.15,
          isMasterLead: index == 0,
        ),
    ]);
  }
}

Vector2 _direction(Vector2 from, Vector2 to) {
  final difference = to - from;
  if (difference.length2 == 0) return Vector2(1, 0);
  return difference.normalized();
}
