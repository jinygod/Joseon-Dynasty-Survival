import 'dart:ui';

import 'ids.dart';
import 'weapon_definitions.dart';

class WeaponVisualTheme {
  const WeaponVisualTheme({
    required this.primary,
    required this.accent,
    required this.trailWidth,
    this.masterScale = 1.45,
  });

  final Color primary;
  final Color accent;
  final double trailWidth;
  final double masterScale;
}

const weaponVisualThemes = <WeaponId, WeaponVisualTheme>{
  hwandoSlash: WeaponVisualTheme(
    primary: Color(0xff83e8ff),
    accent: Color(0xffffffff),
    trailWidth: 5,
  ),
  gakgungShot: WeaponVisualTheme(
    primary: Color(0xffffd166),
    accent: Color(0xfffff1b8),
    trailWidth: 3,
  ),
  talismanThrow: WeaponVisualTheme(
    primary: Color(0xffff4d8d),
    accent: Color(0xffffd6e5),
    trailWidth: 3,
  ),
  thunderCrashBomb: WeaponVisualTheme(
    primary: Color(0xffff7b00),
    accent: Color(0xffffe066),
    trailWidth: 5,
  ),
  jangseungWard: WeaponVisualTheme(
    primary: Color(0xff52d273),
    accent: Color(0xffd8f3dc),
    trailWidth: 4,
  ),
  singijeonVolley: WeaponVisualTheme(
    primary: Color(0xffff334f),
    accent: Color(0xffffb3bf),
    trailWidth: 3,
  ),
  frostFlask: WeaponVisualTheme(
    primary: Color(0xff4cc9f0),
    accent: Color(0xffcaf0f8),
    trailWidth: 4,
  ),
  windThunderFan: WeaponVisualTheme(
    primary: Color(0xff9d4edd),
    accent: Color(0xffe0aaff),
    trailWidth: 5,
  ),
  matchlockCannon: WeaponVisualTheme(
    primary: Color(0xffff5d2e),
    accent: Color(0xffffc857),
    trailWidth: 7,
    masterScale: 1.7,
  ),
  shamanBells: WeaponVisualTheme(
    primary: Color(0xff00bfa6),
    accent: Color(0xffb8fff1),
    trailWidth: 4,
  ),
  dokkaebiChain: WeaponVisualTheme(
    primary: Color(0xffa7c957),
    accent: Color(0xfff2e8cf),
    trailWidth: 6,
  ),
  hawkSummon: WeaponVisualTheme(
    primary: Color(0xff3a86ff),
    accent: Color(0xffffbe0b),
    trailWidth: 5,
    masterScale: 1.6,
  ),
};

const fallbackWeaponVisualTheme = WeaponVisualTheme(
  primary: Color(0xfff4ead2),
  accent: Color(0xffffffff),
  trailWidth: 3,
);

WeaponVisualTheme weaponVisualThemeFor(WeaponId? weaponId) =>
    weaponVisualThemes[weaponId] ?? fallbackWeaponVisualTheme;
