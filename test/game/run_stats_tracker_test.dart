import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/models/run_choice_record.dart';
import 'package:pixel_survivor/game/models/run_outcome.dart';
import 'package:pixel_survivor/game/systems/run_stats_tracker.dart';
import 'package:pixel_survivor/game/systems/weapon_synergy_resolver.dart';

void main() {
  group('RunStatsTracker', () {
    test('records kills and boss defeats in run results', () {
      final tracker = RunStatsTracker()
        ..recordEnemyDefeat(isBoss: false)
        ..recordEnemyDefeat(isBoss: true);

      final result = tracker.toRunResult(
        outcome: RunOutcome.defeat,
        survivalSeconds: 91,
        level: 4,
        wonWithLowHealth: false,
        weaponLevels: const {hwandoSlash: 2},
      );

      expect(result.outcome, RunOutcome.defeat);
      expect(result.survivalSeconds, 91);
      expect(result.kills, 2);
      expect(result.level, 4);
      expect(result.bossDefeated, isTrue);
      expect(result.weaponKillCounts, isEmpty);
      expect(result.weaponLevels, {hwandoSlash: 2});
    });

    test('tracks elite kills and collected spirit jade', () {
      final tracker = RunStatsTracker()
        ..recordEnemyDefeat(isBoss: false, isElite: true)
        ..recordEnemyDefeat(isBoss: false)
        ..recordSpiritJadeCollected();

      final result = tracker.toRunResult(
        outcome: RunOutcome.defeat,
        survivalSeconds: 30,
        level: 2,
        wonWithLowHealth: false,
        weaponLevels: const {},
      );

      expect(result.eliteKills, 1);
      expect(result.spiritJadeCollected, 1);
    });

    test('accumulates effective damage and kills for the same weapon', () {
      final tracker = RunStatsTracker()
        ..recordWeaponDamage(weaponId: hwandoSlash, amount: 8.5)
        ..recordWeaponDamage(weaponId: hwandoSlash, amount: 3.5)
        ..recordEnemyDefeat(isBoss: false, weaponId: hwandoSlash)
        ..recordEnemyDefeat(isBoss: false, weaponId: hwandoSlash);

      final result = tracker.toRunResult(
        outcome: RunOutcome.victory,
        survivalSeconds: 300,
        level: 10,
        wonWithLowHealth: false,
        weaponLevels: const {hwandoSlash: 5},
      );

      expect(result.weaponDamageTotals, {hwandoSlash: 12});
      expect(result.weaponKillCounts, {hwandoSlash: 2});
    });

    test('attributes sealing slash damage and kills to its own source', () {
      final tracker = RunStatsTracker()
        ..recordWeaponDamage(weaponId: hwandoSlash, amount: 8)
        ..recordDamageSource(sourceId: sealingSlash, amount: 12)
        ..recordEnemyDefeat(isBoss: false, weaponId: sealingSlash);

      final result = tracker.toRunResult(
        outcome: RunOutcome.victory,
        survivalSeconds: 30,
        level: 2,
        wonWithLowHealth: false,
        weaponLevels: const {hwandoSlash: 1, talismanThrow: 1},
      );

      expect(result.weaponDamageTotals, {hwandoSlash: 8, sealingSlash: 12});
      expect(result.weaponKillCounts, {sealingSlash: 1});
      expect(result.weaponDamageTotals, isNot(contains(talismanThrow)));
    });

    test('preserves choice order time and selected level', () {
      final tracker = RunStatsTracker()
        ..recordChoice(
          const RunChoiceRecord(
            type: RunChoiceType.weapon,
            contentId: hwandoSlash,
            selectedAtSeconds: 20,
            selectedLevel: 2,
          ),
        )
        ..recordChoice(
          const RunChoiceRecord(
            type: RunChoiceType.augment,
            contentId: 'inner_breath',
            selectedAtSeconds: 45,
            selectedLevel: 1,
          ),
        );

      final result = tracker.toRunResult(
        outcome: RunOutcome.defeat,
        survivalSeconds: 100,
        level: 4,
        wonWithLowHealth: false,
        weaponLevels: const {},
      );

      expect(result.choices.map((choice) => choice.contentId), [
        hwandoSlash,
        'inner_breath',
      ]);
      expect(result.choices.last.selectedAtSeconds, 45);
      expect(result.choices.last.selectedLevel, 1);
    });

    test('tracks damage source and first lethal time', () {
      final tracker = RunStatsTracker()
        ..recordPlayerDamage(
          amount: 12.5,
          sourceId: 'plague_rat',
          atSeconds: 80,
          isLethal: false,
        )
        ..recordPlayerDamage(
          amount: 20,
          sourceId: 'vengeful_spirit',
          atSeconds: 95,
          isLethal: true,
        )
        ..recordPlayerDamage(
          amount: 10,
          sourceId: 'fallen_general',
          atSeconds: 96,
          isLethal: true,
        );

      final result = tracker.toRunResult(
        outcome: RunOutcome.defeat,
        survivalSeconds: 95,
        level: 4,
        wonWithLowHealth: false,
        weaponLevels: const {},
      );

      expect(result.totalDamageTaken, 42.5);
      expect(result.lastDamageSource, 'fallen_general');
      expect(result.deathAtSeconds, 95);
    });
  });
}
