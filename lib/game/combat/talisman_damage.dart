import '../components/enemy_component.dart';
import '../content/enemy_definitions.dart';
import 'attack_spec.dart';

double talismanDamageForTarget(AttackInstance attack, EnemyComponent target) =>
    attack.spec.damage *
    (attack.isCritical ? 2 : 1) *
    (target.enemyId == vengefulSpirit ? 1.25 : 1);
