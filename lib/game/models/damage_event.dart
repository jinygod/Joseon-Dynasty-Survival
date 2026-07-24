import 'package:flame/components.dart';

import '../components/enemy_component.dart';
import '../combat/attack_spec.dart';
import '../content/ids.dart';

class DamageEvent {
  DamageEvent({
    required this.target,
    required this.damage,
    required this.knockback,
    required this.direction,
    this.weaponId,
    this.isCritical = false,
    this.sourceId,
    Vector2? contactPoint,
    Set<AttackTrait> traits = const {},
  }) : _contactPoint = contactPoint?.clone(),
       traits = Set<AttackTrait>.unmodifiable(traits);

  final EnemyComponent target;
  final double damage;
  final double knockback;
  final Vector2 direction;
  final WeaponId? weaponId;
  final bool isCritical;
  final String? sourceId;
  final Vector2? _contactPoint;
  final Set<AttackTrait> traits;

  Vector2? get contactPoint => _contactPoint?.clone();
}
