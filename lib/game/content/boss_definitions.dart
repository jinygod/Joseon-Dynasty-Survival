import 'dart:math' as math;

import 'enemy_definitions.dart';
import 'ids.dart';
import 'stage_definitions.dart';

const plagueMagistrate = 'plague_magistrate';
const maskedExecutioner = 'masked_executioner';

enum BossPatternKind { charge, cone, radial, summon }

class BossPatternDefinition {
  const BossPatternDefinition({
    required this.id,
    required this.name,
    required this.kind,
    required this.warningSeconds,
    this.recoverySeconds = 0.45,
    this.damageMultiplier = 1,
    this.radius = 0,
    this.angleRadians = math.pi * 2,
    this.knockback = 0,
    this.chargeSeconds = 0,
    this.chargeSpeedMultiplier = 0,
    this.healthThreshold,
    this.summonEnemyIds = const [],
  });

  final String id;
  final String name;
  final BossPatternKind kind;
  final double warningSeconds;
  final double recoverySeconds;
  final double damageMultiplier;
  final double radius;
  final double angleRadians;
  final double knockback;
  final double chargeSeconds;
  final double chargeSpeedMultiplier;
  final double? healthThreshold;
  final List<EnemyId> summonEnemyIds;
}

class BossEnrageDefinition {
  const BossEnrageDefinition({
    required this.afterSeconds,
    required this.movementMultiplier,
    required this.patternTimeMultiplier,
  });

  final double afterSeconds;
  final double movementMultiplier;
  final double patternTimeMultiplier;
}

class BossDefinition {
  const BossDefinition({
    required this.enemy,
    required this.patterns,
    required this.enrage,
  });

  final EnemyDefinition enemy;
  final List<BossPatternDefinition> patterns;
  final BossEnrageDefinition enrage;

  EnemyId get id => enemy.id;
  String get name => enemy.name;
}

const fallenGeneralBossDefinition = BossDefinition(
  enemy: EnemyDefinition(
    id: fallenGeneral,
    name: '타락한 관군 대장',
    maxHealth: 900,
    moveSpeed: 26,
    damage: 20,
    experience: 20,
    faction: EnemyFaction.anomaly,
    rank: EnemyRank.boss,
    behaviorProfileId: 'tank',
    behaviorType: EnemyBehaviorType.tank,
  ),
  patterns: [
    BossPatternDefinition(
      id: 'cavalry_charge',
      name: '기마 돌진',
      kind: BossPatternKind.charge,
      warningSeconds: 0.75,
      chargeSeconds: 0.35,
      chargeSpeedMultiplier: 4,
    ),
    BossPatternDefinition(
      id: 'commanders_sweep',
      name: '대장군의 휩쓸기',
      kind: BossPatternKind.cone,
      warningSeconds: 0.60,
      damageMultiplier: 1.5,
      radius: 130,
      angleRadians: math.pi / 2,
      knockback: 90,
    ),
    BossPatternDefinition(
      id: 'call_vengeful_spirits',
      name: '원혼 소집',
      kind: BossPatternKind.summon,
      warningSeconds: 0.70,
      healthThreshold: 0.40,
      summonEnemyIds: [vengefulSpirit, vengefulSpirit, vengefulSpirit],
    ),
  ],
  enrage: BossEnrageDefinition(
    afterSeconds: 25,
    movementMultiplier: 1.25,
    patternTimeMultiplier: 1.25,
  ),
);

const plagueMagistrateBossDefinition = BossDefinition(
  enemy: EnemyDefinition(
    id: plagueMagistrate,
    name: '역병 판관',
    maxHealth: 820,
    moveSpeed: 30,
    damage: 18,
    experience: 22,
    faction: EnemyFaction.plague,
    rank: EnemyRank.boss,
    behaviorProfileId: 'tank',
    behaviorType: EnemyBehaviorType.tank,
  ),
  patterns: [
    BossPatternDefinition(
      id: 'pestilent_decree',
      name: '역병 교지',
      kind: BossPatternKind.radial,
      warningSeconds: 0.80,
      damageMultiplier: 1.2,
      radius: 145,
      knockback: 65,
    ),
    BossPatternDefinition(
      id: 'infected_rush',
      name: '감염 돌진',
      kind: BossPatternKind.charge,
      warningSeconds: 0.70,
      chargeSeconds: 0.30,
      chargeSpeedMultiplier: 4.4,
    ),
    BossPatternDefinition(
      id: 'carrion_sentence',
      name: '부패 선고',
      kind: BossPatternKind.cone,
      warningSeconds: 0.65,
      damageMultiplier: 1.4,
      radius: 175,
      angleRadians: 55 * math.pi / 180,
      knockback: 75,
    ),
  ],
  enrage: BossEnrageDefinition(
    afterSeconds: 22,
    movementMultiplier: 1.30,
    patternTimeMultiplier: 1.30,
  ),
);

const maskedExecutionerBossDefinition = BossDefinition(
  enemy: EnemyDefinition(
    id: maskedExecutioner,
    name: '가면 처형인',
    maxHealth: 980,
    moveSpeed: 24,
    damage: 22,
    experience: 24,
    faction: EnemyFaction.bandit,
    rank: EnemyRank.boss,
    behaviorProfileId: 'tank',
    behaviorType: EnemyBehaviorType.tank,
  ),
  patterns: [
    BossPatternDefinition(
      id: 'headsmans_rush',
      name: '망나니 돌진',
      kind: BossPatternKind.charge,
      warningSeconds: 0.65,
      chargeSeconds: 0.40,
      chargeSpeedMultiplier: 4.2,
    ),
    BossPatternDefinition(
      id: 'execution_corridor',
      name: '처형 회랑',
      kind: BossPatternKind.cone,
      warningSeconds: 0.70,
      damageMultiplier: 1.8,
      radius: 210,
      angleRadians: 28 * math.pi / 180,
      knockback: 110,
    ),
    BossPatternDefinition(
      id: 'blood_ring',
      name: '혈환',
      kind: BossPatternKind.radial,
      warningSeconds: 0.75,
      damageMultiplier: 1.35,
      radius: 120,
      knockback: 85,
    ),
  ],
  enrage: BossEnrageDefinition(
    afterSeconds: 20,
    movementMultiplier: 1.35,
    patternTimeMultiplier: 1.35,
  ),
);

const bossDefinitions = <BossDefinition>[
  fallenGeneralBossDefinition,
  plagueMagistrateBossDefinition,
  maskedExecutionerBossDefinition,
];

BossDefinition? bossDefinitionForId(EnemyId id) {
  for (final definition in bossDefinitions) {
    if (definition.id == id) return definition;
  }
  return null;
}

BossDefinition bossDefinitionForStage(String stageId, {required double roll}) {
  if (stageId == plagueMarket) return plagueMagistrateBossDefinition;
  if (stageId == moonlitAbandonedOffice) {
    return roll.isFinite && roll >= 0.60
        ? maskedExecutionerBossDefinition
        : fallenGeneralBossDefinition;
  }
  return fallenGeneralBossDefinition;
}

List<String> validateBossContent() =>
    validateBossDefinitions(bossDefinitions, enemies: enemyDefinitions);

List<String> validateBossDefinitions(
  Iterable<BossDefinition> definitions, {
  Iterable<EnemyDefinition> enemies = enemyDefinitions,
}) {
  final errors = <String>[];
  final enemyIds = enemies.map((enemy) => enemy.id).toSet();
  final bossIds = <EnemyId>{};
  for (final boss in definitions) {
    if (!bossIds.add(boss.id)) errors.add('Duplicate boss id: ${boss.id}');
    if (boss.enemy.rank != EnemyRank.boss) {
      errors.add('Boss rank required: ${boss.id}');
    }
    if (!boss.enemy.maxHealth.isFinite || boss.enemy.maxHealth <= 0) {
      errors.add('Invalid boss health: ${boss.id}');
    }
    if (!boss.enemy.moveSpeed.isFinite || boss.enemy.moveSpeed < 0) {
      errors.add('Invalid boss speed: ${boss.id}');
    }
    if (!boss.enemy.damage.isFinite || boss.enemy.damage < 0) {
      errors.add('Invalid boss damage: ${boss.id}');
    }
    if (boss.enemy.experience < 0) {
      errors.add('Invalid boss experience: ${boss.id}');
    }
    if (boss.patterns.length < 3) {
      errors.add('At least three patterns required: ${boss.id}');
    }
    final patternIds = <String>{};
    final patternKinds = <BossPatternKind>{};
    for (final pattern in boss.patterns) {
      if (!patternIds.add(pattern.id)) {
        errors.add('Duplicate boss pattern: ${boss.id}/${pattern.id}');
      }
      patternKinds.add(pattern.kind);
      if (!pattern.warningSeconds.isFinite || pattern.warningSeconds < 0.6) {
        errors.add('Unreadable boss warning: ${boss.id}/${pattern.id}');
      }
      if (!pattern.recoverySeconds.isFinite || pattern.recoverySeconds < 0) {
        errors.add('Invalid boss recovery: ${boss.id}/${pattern.id}');
      }
      if (!pattern.damageMultiplier.isFinite || pattern.damageMultiplier <= 0) {
        errors.add('Invalid boss damage multiplier: ${boss.id}/${pattern.id}');
      }
      if (!pattern.knockback.isFinite || pattern.knockback < 0) {
        errors.add('Invalid boss knockback: ${boss.id}/${pattern.id}');
      }
      if (pattern.healthThreshold case final threshold?) {
        if (!threshold.isFinite || threshold <= 0 || threshold > 1) {
          errors.add('Invalid boss health threshold: ${boss.id}/${pattern.id}');
        }
      }
      if (pattern.kind == BossPatternKind.charge &&
          (!pattern.chargeSeconds.isFinite ||
              pattern.chargeSeconds <= 0 ||
              !pattern.chargeSpeedMultiplier.isFinite ||
              pattern.chargeSpeedMultiplier <= 0)) {
        errors.add('Invalid boss charge: ${boss.id}/${pattern.id}');
      }
      if ((pattern.kind == BossPatternKind.cone ||
              pattern.kind == BossPatternKind.radial) &&
          (!pattern.radius.isFinite ||
              pattern.radius <= 0 ||
              !pattern.angleRadians.isFinite ||
              pattern.angleRadians <= 0 ||
              pattern.angleRadians > math.pi * 2)) {
        errors.add('Invalid boss area: ${boss.id}/${pattern.id}');
      }
      if (pattern.kind == BossPatternKind.summon &&
          pattern.summonEnemyIds.isEmpty) {
        errors.add('Empty boss summon: ${boss.id}/${pattern.id}');
      }
      if (pattern.kind == BossPatternKind.summon) {
        for (final enemyId in pattern.summonEnemyIds) {
          if (!enemyIds.contains(enemyId)) {
            errors.add(
              'Unknown boss summon enemy: ${boss.id}/${pattern.id}/$enemyId',
            );
          }
        }
      }
    }
    if (patternKinds.length < 3) {
      errors.add('Three distinct boss patterns required: ${boss.id}');
    }
    if (!boss.enrage.afterSeconds.isFinite ||
        boss.enrage.afterSeconds <= 0 ||
        !boss.enrage.movementMultiplier.isFinite ||
        boss.enrage.movementMultiplier <= 1 ||
        !boss.enrage.patternTimeMultiplier.isFinite ||
        boss.enrage.patternTimeMultiplier <= 1) {
      errors.add('Invalid boss enrage: ${boss.id}');
    }
  }
  return errors;
}
