import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/combat/attack_spec.dart';
import 'package:pixel_survivor/game/combat/combat_vfx_primitives.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_visual_theme.dart';

void main() {
  test('all twelve base weapons have authored readable visual themes', () {
    final ids = weaponDefinitions.map((weapon) => weapon.id).toSet();

    expect(weaponVisualThemes.keys.toSet(), ids);
    expect(
      weaponVisualThemes.values.map((theme) => theme.family).toSet(),
      hasLength(12),
    );
    for (final weapon in weaponDefinitions) {
      final theme = weaponVisualThemeFor(weapon.id);
      expect(theme.family, isNot(WeaponVfxFamily.neutral), reason: weapon.id);
      expect(theme.masterScale, greaterThan(1), reason: weapon.id);
      expect(
        theme.trailCountFor(CombatVfxTier.master),
        greaterThan(theme.trailCountFor(CombatVfxTier.normal)),
        reason: weapon.id,
      );
      expect(
        theme.trailCountFor(CombatVfxTier.master),
        lessThanOrEqualTo(CombatVfxPrimitives.maxTrailSegments),
        reason: weapon.id,
      );
    }
    expect(
      weaponVisualThemes.values.map((theme) => theme.primary).toSet(),
      hasLength(12),
    );
    expect(
      weaponVisualThemes.values.every(
        (theme) => theme.masterScale > 1 && theme.trailWidth >= 2,
      ),
      isTrue,
    );
  });

  test('weapon levels and authored presentations resolve visual tiers', () {
    expect(combatVfxTierForLevel(1), CombatVfxTier.normal);
    expect(combatVfxTierForLevel(4), CombatVfxTier.strong);
    expect(combatVfxTierForLevel(6), CombatVfxTier.master);
    expect(
      combatVfxTierForPresentation(AttackPresentation.normal),
      CombatVfxTier.normal,
    );
    expect(
      combatVfxTierForPresentation(AttackPresentation.strong),
      CombatVfxTier.strong,
    );
    expect(
      combatVfxTierForPresentation(AttackPresentation.master),
      CombatVfxTier.master,
    );
  });
}
