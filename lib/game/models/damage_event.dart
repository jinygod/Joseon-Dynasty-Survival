import 'package:flame/components.dart';

import '../components/enemy_component.dart';
import '../content/ids.dart';

class DamageEvent {
  const DamageEvent({
    required this.target,
    required this.damage,
    required this.knockback,
    required this.direction,
    this.weaponId,
    this.isCritical = false,
  });

  final EnemyComponent target;
  final double damage;
  final double knockback;
  final Vector2 direction;
  final WeaponId? weaponId;
  final bool isCritical;
}
