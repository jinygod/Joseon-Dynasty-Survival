import 'dart:ui';

import '../combat/attack_spec.dart';
import '../combat/combat_vfx_primitives.dart';
import 'ids.dart';
import 'weapon_definitions.dart';

enum WeaponVfxFamily {
  neutral,
  hwandoBlade,
  gakgungArrow,
  talismanSeal,
  thunderBomb,
  jangseungGuardian,
  singijeonRocket,
  frostCrystal,
  windThunderGale,
  matchlockShot,
  shamanBell,
  dokkaebiChain,
  hawkFlight,
}

class WeaponVisualTheme {
  const WeaponVisualTheme({
    required this.primary,
    required this.accent,
    required this.trailWidth,
    required this.family,
    this.masterScale = 1.45,
  });

  final Color primary;
  final Color accent;
  final double trailWidth;
  final WeaponVfxFamily family;
  final double masterScale;

  CombatVfxPalette get palette => CombatVfxPalette(
    core: accent,
    edge: primary,
    accent: const Color(0xffffffff),
    smoke: Color.lerp(primary, const Color(0xff2f3440), .66)!,
  );

  int trailCountFor(CombatVfxTier tier) => switch (tier) {
    CombatVfxTier.normal => 1,
    CombatVfxTier.strong => 2,
    CombatVfxTier.master => CombatVfxPrimitives.maxTrailSegments,
  };

  double scaleFor(CombatVfxTier tier) => switch (tier) {
    CombatVfxTier.normal => 1,
    CombatVfxTier.strong => 1 + (masterScale - 1) * .52,
    CombatVfxTier.master => masterScale,
  };
}

const weaponVisualThemes = <WeaponId, WeaponVisualTheme>{
  hwandoSlash: WeaponVisualTheme(
    primary: Color(0xff83e8ff),
    accent: Color(0xffffffff),
    trailWidth: 5,
    family: WeaponVfxFamily.hwandoBlade,
  ),
  gakgungShot: WeaponVisualTheme(
    primary: Color(0xffffd166),
    accent: Color(0xfffff1b8),
    trailWidth: 3,
    family: WeaponVfxFamily.gakgungArrow,
  ),
  talismanThrow: WeaponVisualTheme(
    primary: Color(0xffff4d8d),
    accent: Color(0xffffd6e5),
    trailWidth: 3,
    family: WeaponVfxFamily.talismanSeal,
  ),
  thunderCrashBomb: WeaponVisualTheme(
    primary: Color(0xffff7b00),
    accent: Color(0xffffe066),
    trailWidth: 5,
    family: WeaponVfxFamily.thunderBomb,
  ),
  jangseungWard: WeaponVisualTheme(
    primary: Color(0xff52d273),
    accent: Color(0xffd8f3dc),
    trailWidth: 4,
    family: WeaponVfxFamily.jangseungGuardian,
  ),
  singijeonVolley: WeaponVisualTheme(
    primary: Color(0xffff334f),
    accent: Color(0xffffb3bf),
    trailWidth: 3,
    family: WeaponVfxFamily.singijeonRocket,
  ),
  frostFlask: WeaponVisualTheme(
    primary: Color(0xff4cc9f0),
    accent: Color(0xffcaf0f8),
    trailWidth: 4,
    family: WeaponVfxFamily.frostCrystal,
  ),
  windThunderFan: WeaponVisualTheme(
    primary: Color(0xff9d4edd),
    accent: Color(0xffe0aaff),
    trailWidth: 5,
    family: WeaponVfxFamily.windThunderGale,
  ),
  matchlockCannon: WeaponVisualTheme(
    primary: Color(0xffff5d2e),
    accent: Color(0xffffc857),
    trailWidth: 7,
    family: WeaponVfxFamily.matchlockShot,
    masterScale: 1.7,
  ),
  shamanBells: WeaponVisualTheme(
    primary: Color(0xff00bfa6),
    accent: Color(0xffb8fff1),
    trailWidth: 4,
    family: WeaponVfxFamily.shamanBell,
  ),
  dokkaebiChain: WeaponVisualTheme(
    primary: Color(0xffa7c957),
    accent: Color(0xfff2e8cf),
    trailWidth: 6,
    family: WeaponVfxFamily.dokkaebiChain,
  ),
  hawkSummon: WeaponVisualTheme(
    primary: Color(0xff3a86ff),
    accent: Color(0xffffbe0b),
    trailWidth: 5,
    family: WeaponVfxFamily.hawkFlight,
    masterScale: 1.6,
  ),
};

const fallbackWeaponVisualTheme = WeaponVisualTheme(
  primary: Color(0xfff4ead2),
  accent: Color(0xffffffff),
  trailWidth: 3,
  family: WeaponVfxFamily.neutral,
);

WeaponVisualTheme weaponVisualThemeFor(WeaponId? weaponId) =>
    weaponVisualThemes[weaponId] ?? fallbackWeaponVisualTheme;

CombatVfxTier combatVfxTierForLevel(int level) => switch (level) {
  >= 6 => CombatVfxTier.master,
  >= 4 => CombatVfxTier.strong,
  _ => CombatVfxTier.normal,
};

CombatVfxTier combatVfxTierForPresentation(AttackPresentation presentation) =>
    switch (presentation) {
      AttackPresentation.normal => CombatVfxTier.normal,
      AttackPresentation.strong => CombatVfxTier.strong,
      AttackPresentation.master ||
      AttackPresentation.synergy => CombatVfxTier.master,
    };

WeaponVfxFamily weaponVfxFamilyForAttackId(String attackId) {
  if (attackId.startsWith('hwando_') || attackId == 'sealing_slash') {
    return WeaponVfxFamily.hwandoBlade;
  }
  if (attackId.startsWith('talisman_')) {
    return WeaponVfxFamily.talismanSeal;
  }
  return WeaponVfxFamily.neutral;
}
