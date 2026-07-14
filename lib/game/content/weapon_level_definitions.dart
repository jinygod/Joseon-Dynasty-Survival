import 'ids.dart';
import 'weapon_definitions.dart';

class WeaponLevelDefinition {
  const WeaponLevelDefinition({
    required this.damage,
    required this.cooldownSeconds,
    required this.range,
    required this.projectileCount,
    required this.pierce,
    required this.chainCount,
    required this.knockback,
    required this.displayEffect,
  });

  final double damage;
  final double cooldownSeconds;
  final double range;
  final int projectileCount;
  final int pierce;
  final int chainCount;
  final double knockback;
  final String displayEffect;
}

const weaponLevels = <WeaponId, List<WeaponLevelDefinition>>{
  hwandoSlash: [
    WeaponLevelDefinition(
      damage: 8,
      cooldownSeconds: 0.72,
      range: 58,
      projectileCount: 1,
      pierce: 0,
      chainCount: 0,
      knockback: 45,
      displayEffect: '피해 8, 범위 58',
    ),
    WeaponLevelDefinition(
      damage: 10,
      cooldownSeconds: 0.72,
      range: 68,
      projectileCount: 1,
      pierce: 0,
      chainCount: 0,
      knockback: 50,
      displayEffect: '피해 10, 범위 +10',
    ),
    WeaponLevelDefinition(
      damage: 12,
      cooldownSeconds: 0.60,
      range: 68,
      projectileCount: 1,
      pierce: 0,
      chainCount: 0,
      knockback: 55,
      displayEffect: '재사용 시간 0.60초',
    ),
    WeaponLevelDefinition(
      damage: 15,
      cooldownSeconds: 0.60,
      range: 82,
      projectileCount: 1,
      pierce: 0,
      chainCount: 0,
      knockback: 65,
      displayEffect: '피해 15, 범위 +14',
    ),
    WeaponLevelDefinition(
      damage: 18,
      cooldownSeconds: 0.52,
      range: 88,
      projectileCount: 2,
      pierce: 0,
      chainCount: 0,
      knockback: 75,
      displayEffect: '좌우 연속 베기 2회',
    ),
  ],
  gakgungShot: [
    WeaponLevelDefinition(
      damage: 7,
      cooldownSeconds: 1.05,
      range: 420,
      projectileCount: 1,
      pierce: 0,
      chainCount: 0,
      knockback: 10,
      displayEffect: '화살 1발, 피해 7',
    ),
    WeaponLevelDefinition(
      damage: 9,
      cooldownSeconds: 0.95,
      range: 420,
      projectileCount: 1,
      pierce: 0,
      chainCount: 0,
      knockback: 10,
      displayEffect: '피해 9, 재사용 시간 0.95초',
    ),
    WeaponLevelDefinition(
      damage: 10,
      cooldownSeconds: 0.95,
      range: 440,
      projectileCount: 1,
      pierce: 1,
      chainCount: 0,
      knockback: 12,
      displayEffect: '관통 +1',
    ),
    WeaponLevelDefinition(
      damage: 12,
      cooldownSeconds: 0.82,
      range: 460,
      projectileCount: 2,
      pierce: 1,
      chainCount: 0,
      knockback: 12,
      displayEffect: '화살 +1',
    ),
    WeaponLevelDefinition(
      damage: 15,
      cooldownSeconds: 0.72,
      range: 480,
      projectileCount: 2,
      pierce: 2,
      chainCount: 0,
      knockback: 15,
      displayEffect: '관통 +1, 첫 대상 추가 피해',
    ),
  ],
  talismanThrow: [
    WeaponLevelDefinition(
      damage: 8,
      cooldownSeconds: 1.40,
      range: 220,
      projectileCount: 1,
      pierce: 0,
      chainCount: 1,
      knockback: 8,
      displayEffect: '연쇄 1회, 원혼 추가 피해',
    ),
    WeaponLevelDefinition(
      damage: 10,
      cooldownSeconds: 1.30,
      range: 230,
      projectileCount: 1,
      pierce: 0,
      chainCount: 2,
      knockback: 8,
      displayEffect: '연쇄 +1',
    ),
    WeaponLevelDefinition(
      damage: 12,
      cooldownSeconds: 1.20,
      range: 240,
      projectileCount: 1,
      pierce: 0,
      chainCount: 3,
      knockback: 10,
      displayEffect: '연쇄 +1, 피해 12',
    ),
    WeaponLevelDefinition(
      damage: 14,
      cooldownSeconds: 1.10,
      range: 255,
      projectileCount: 1,
      pierce: 0,
      chainCount: 4,
      knockback: 10,
      displayEffect: '연쇄 +1, 탐색 범위 +15',
    ),
    WeaponLevelDefinition(
      damage: 17,
      cooldownSeconds: 1.00,
      range: 270,
      projectileCount: 2,
      pierce: 0,
      chainCount: 5,
      knockback: 12,
      displayEffect: '부적 +1, 연쇄 +1',
    ),
  ],
  thunderCrashBomb: [
    WeaponLevelDefinition(
      damage: 14,
      cooldownSeconds: 2.60,
      range: 70,
      projectileCount: 1,
      pierce: 0,
      chainCount: 0,
      knockback: 35,
      displayEffect: '폭발 범위 70, 피해 14',
    ),
    WeaponLevelDefinition(
      damage: 18,
      cooldownSeconds: 2.40,
      range: 82,
      projectileCount: 1,
      pierce: 0,
      chainCount: 0,
      knockback: 45,
      displayEffect: '폭발 범위 +12',
    ),
    WeaponLevelDefinition(
      damage: 22,
      cooldownSeconds: 2.20,
      range: 94,
      projectileCount: 1,
      pierce: 0,
      chainCount: 0,
      knockback: 55,
      displayEffect: '피해 22, 재사용 시간 2.20초',
    ),
    WeaponLevelDefinition(
      damage: 26,
      cooldownSeconds: 2.00,
      range: 106,
      projectileCount: 2,
      pierce: 0,
      chainCount: 0,
      knockback: 65,
      displayEffect: '폭발 +1',
    ),
    WeaponLevelDefinition(
      damage: 32,
      cooldownSeconds: 1.80,
      range: 120,
      projectileCount: 2,
      pierce: 0,
      chainCount: 0,
      knockback: 80,
      displayEffect: '피해 32, 폭발 범위 120',
    ),
  ],
};

WeaponLevelDefinition weaponLevelFor(WeaponId id, int level) {
  final levels = weaponLevels[id];
  if (levels == null) {
    throw ArgumentError.value(id, 'id', 'Unknown weapon');
  }
  if (level < 1 || level > levels.length) {
    throw RangeError.range(level, 1, levels.length, 'level');
  }

  return levels[level - 1];
}
