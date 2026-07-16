import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/boss_definitions.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';
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
}
