import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/boss_definitions.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';
import 'package:pixel_survivor/game/content/ids.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';

void main() {
  test('three bosses define three readable patterns and explicit enrages', () {
    expect(validateBossContent(), isEmpty);
    expect(bossDefinitions, hasLength(3));
    expect(bossDefinitions.map((boss) => boss.id).toSet(), hasLength(3));

    for (final boss in bossDefinitions) {
      expect(boss.patterns, hasLength(3), reason: boss.id);
      expect(
        boss.patterns.map((pattern) => pattern.id).toSet(),
        hasLength(3),
        reason: boss.id,
      );
      expect(
        boss.patterns.map((pattern) => pattern.kind).toSet(),
        hasLength(3),
        reason: boss.id,
      );
      expect(
        boss.patterns.map((pattern) => pattern.warningSeconds),
        everyElement(greaterThanOrEqualTo(0.6)),
        reason: boss.id,
      );
      expect(boss.enrage.afterSeconds, greaterThan(0), reason: boss.id);
      expect(boss.enrage.movementMultiplier, greaterThan(1), reason: boss.id);
      expect(
        boss.enrage.patternTimeMultiplier,
        greaterThan(1),
        reason: boss.id,
      );
    }
  });

  test('stage boss selection reaches the existing and both new bosses', () {
    expect(
      bossDefinitionForStage(moonlitAbandonedOffice, roll: 0).id,
      fallenGeneral,
    );
    expect(
      bossDefinitionForStage(moonlitAbandonedOffice, roll: 0.99).id,
      maskedExecutioner,
    );
    expect(bossDefinitionForStage(plagueMarket, roll: 0).id, plagueMagistrate);
    expect(
      bossDefinitionForStage('unknown-stage', roll: 0.99).id,
      fallenGeneral,
    );
  });

  test('boss enrage timings and multipliers match the design', () {
    final general = bossDefinitionForId(fallenGeneral)!;
    final magistrate = bossDefinitionForId(plagueMagistrate)!;
    final executioner = bossDefinitionForId(maskedExecutioner)!;

    expect(
      (general.enrage.afterSeconds, general.enrage.movementMultiplier),
      (25, 1.25),
    );
    expect(
      (magistrate.enrage.afterSeconds, magistrate.enrage.movementMultiplier),
      (22, 1.30),
    );
    expect(
      (executioner.enrage.afterSeconds, executioner.enrage.movementMultiplier),
      (20, 1.35),
    );
  });

  test('validation rejects non-positive and non-finite boss tuning', () {
    const invalid = BossDefinition(
      enemy: EnemyDefinition(
        id: 'invalid_boss',
        name: 'Invalid',
        maxHealth: 0,
        moveSpeed: double.nan,
        damage: -1,
        experience: -1,
        faction: EnemyFaction.anomaly,
        rank: EnemyRank.boss,
        behaviorProfileId: 'tank',
      ),
      patterns: [
        BossPatternDefinition(
          id: 'invalid_charge',
          name: 'Invalid charge',
          kind: BossPatternKind.charge,
          warningSeconds: 0.6,
          recoverySeconds: -1,
          chargeSeconds: 0,
          chargeSpeedMultiplier: double.infinity,
        ),
        BossPatternDefinition(
          id: 'invalid_cone',
          name: 'Invalid cone',
          kind: BossPatternKind.cone,
          warningSeconds: 0.6,
          damageMultiplier: 0,
          radius: -1,
        ),
        BossPatternDefinition(
          id: 'invalid_summon',
          name: 'Invalid summon',
          kind: BossPatternKind.summon,
          warningSeconds: 0.6,
          summonEnemyIds: ['missing_enemy'],
        ),
      ],
      enrage: BossEnrageDefinition(
        afterSeconds: double.infinity,
        movementMultiplier: double.nan,
        patternTimeMultiplier: 0,
      ),
    );

    expect(validateBossDefinitions([invalid]), isNotEmpty);
  });
}
