import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/combat/attack_spec.dart';
import 'package:pixel_survivor/game/combat/combat_vfx_primitives.dart';
import 'package:pixel_survivor/game/components/attack_effect_component.dart';
import 'package:pixel_survivor/game/components/area_attack_component.dart';
import 'package:pixel_survivor/game/components/melee_arc_component.dart';
import 'package:pixel_survivor/game/components/projectile_component.dart';
import 'package:pixel_survivor/game/components/ward_aura_component.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_visual_theme.dart';

void main() {
  test('attack presentation selects tier without changing frozen geometry', () {
    final normal = AttackEffectComponent(
      instance: _attack(AttackPresentation.normal),
    );
    final master = AttackEffectComponent(
      instance: _attack(AttackPresentation.master),
    );

    expect(normal.visualTier, CombatVfxTier.normal);
    expect(master.visualTier, CombatVfxTier.master);
    expect(master.vfxFamily, WeaponVfxFamily.hwandoBlade);
    expect(master.visualGeometry.range, normal.visualGeometry.range);
    expect(
      master.visualGeometry.angleRadians,
      normal.visualGeometry.angleRadians,
    );
    expect(master.visualGeometry.width, normal.visualGeometry.width);
  });

  test('component tiers only alter bounded presentation metadata', () {
    final normalArc = MeleeArcComponent(
      weaponId: dokkaebiChain,
      damage: 12,
      knockback: 20,
      position: Vector2.zero(),
      direction: Vector2(1, 0),
      range: 90,
      angleRadians: math.pi / 2,
    );
    final masterArc = MeleeArcComponent(
      weaponId: dokkaebiChain,
      damage: 12,
      knockback: 20,
      position: Vector2.zero(),
      direction: Vector2(1, 0),
      range: 90,
      angleRadians: math.pi / 2,
      tier: CombatVfxTier.master,
    );
    final masterProjectile = ProjectileComponent(
      weaponId: hawkSummon,
      damage: 9,
      position: Vector2.zero(),
      velocity: Vector2(300, 0),
      tier: CombatVfxTier.master,
    );
    final masterArea = AreaAttackComponent(
      weaponId: thunderCrashBomb,
      damage: 30,
      radius: 72,
      delaySeconds: .4,
      knockback: 16,
      position: Vector2.zero(),
      tier: CombatVfxTier.master,
    );

    expect(normalArc.visualTier, CombatVfxTier.normal);
    expect(masterArc.visualTier, CombatVfxTier.master);
    expect(masterArc.damage, normalArc.damage);
    expect(masterArc.range, normalArc.range);
    expect(masterArc.angleRadians, normalArc.angleRadians);
    expect(masterArc.visualAfterimageCount, lessThanOrEqualTo(3));
    expect(
      masterArc.visualAfterimageCount,
      greaterThan(normalArc.visualAfterimageCount),
    );
    expect(masterProjectile.vfxFamily, WeaponVfxFamily.hawkFlight);
    expect(masterProjectile.visualTier, CombatVfxTier.master);
    expect(masterArea.vfxFamily, WeaponVfxFamily.thunderBomb);
    expect(masterArea.visualTier, CombatVfxTier.master);
  });

  test('ward guardians are evenly distributed around the full aura', () {
    final normal = WardAuraComponent(
      positionProvider: Vector2.zero,
      radiusProvider: () => 80,
    );
    final master = WardAuraComponent(
      positionProvider: Vector2.zero,
      radiusProvider: () => 80,
      tierProvider: () => CombatVfxTier.master,
    );

    expect(normal.guardianAngles, [0, math.pi / 2, math.pi, math.pi * 1.5]);
    expect(master.guardianAngles, hasLength(8));
    expect(master.guardianAngles.last, closeTo(math.pi * 1.75, 1e-10));
  });
}

AttackInstance _attack(AttackPresentation presentation) => AttackInstance(
  spec: AttackSpec(
    id: 'hwando_test',
    shape: AttackShape.sector,
    damage: 99,
    range: 84,
    angleRadians: math.pi * .7,
    radius: 0,
    width: 13,
    windupSeconds: 0,
    activeSeconds: .08,
    lingerSeconds: .12,
    knockback: 24,
    slowFraction: 0,
    traits: const {},
    presentation: presentation,
  ),
  origin: Vector2(4, 8),
  direction: Vector2(1, 0),
  sequenceIndex: 0,
);
