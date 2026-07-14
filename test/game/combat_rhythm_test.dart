import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/balance/combat_rhythm.dart';

void main() {
  group('combat rhythm phases', () {
    test('cover the full run with exact product boundaries', () {
      expect(
        combatRhythmPhases.map((phase) => phase.id),
        CombatRhythmPhaseId.values,
      );
      expect(combatRhythmPhases.first.startSecond, 0);
      expect(combatRhythmPhases.last.endSecond, 330);

      for (var index = 1; index < combatRhythmPhases.length; index += 1) {
        expect(
          combatRhythmPhases[index].startSecond,
          combatRhythmPhases[index - 1].endSecond,
        );
      }

      expect(combatRhythmPhaseForSecond(-1).id, CombatRhythmPhaseId.learning);
      expect(combatRhythmPhaseForSecond(59.9).id, CombatRhythmPhaseId.learning);
      expect(combatRhythmPhaseForSecond(60).id, CombatRhythmPhaseId.build);
      expect(combatRhythmPhaseForSecond(179.9).id, CombatRhythmPhaseId.build);
      expect(combatRhythmPhaseForSecond(180).id, CombatRhythmPhaseId.pressure);
      expect(
        combatRhythmPhaseForSecond(269.9).id,
        CombatRhythmPhaseId.pressure,
      );
      expect(combatRhythmPhaseForSecond(270).id, CombatRhythmPhaseId.boss);
      expect(combatRhythmPhaseForSecond(999).id, CombatRhythmPhaseId.boss);
    });

    test('declare a measurable intent for every phase', () {
      for (final phase in combatRhythmPhases) {
        expect(phase.playerIntent, isNotEmpty);
        expect(phase.balanceSignals, isNotEmpty);
      }
    });
  });

  group('CombatRhythmSnapshot', () {
    test('serializes stable balance log fields and derives phase', () {
      final snapshot = CombatRhythmSnapshot(
        second: 195,
        activeEnemies: 38,
        spawnedEnemies: 17,
        eliteSpawns: 1,
        playerLevel: 7,
        healthFraction: 0.72,
        kills: 93,
        damageDealt: 1240.5,
        damageTaken: 18,
        weaponDamageTotals: const {'hwando_slash': 800.5, 'talisman': 440},
        bossHealthFraction: null,
      );

      expect(snapshot.phase.id, CombatRhythmPhaseId.pressure);
      expect(snapshot.toJson(), {
        'second': 195,
        'phase': 'pressure',
        'activeEnemies': 38,
        'spawnedEnemies': 17,
        'eliteSpawns': 1,
        'playerLevel': 7,
        'healthFraction': 0.72,
        'kills': 93,
        'damageDealt': 1240.5,
        'damageTaken': 18.0,
        'weaponDamageTotals': {'hwando_slash': 800.5, 'talisman': 440.0},
        'bossHealthFraction': null,
      });
    });

    test('accepts only 15-second samples and valid fractions', () {
      CombatRhythmSnapshot valid({int second = 15, double health = 1}) =>
          CombatRhythmSnapshot(
            second: second,
            activeEnemies: 0,
            spawnedEnemies: 0,
            eliteSpawns: 0,
            playerLevel: 1,
            healthFraction: health,
            kills: 0,
            damageDealt: 0,
            damageTaken: 0,
            weaponDamageTotals: const {},
            bossHealthFraction: null,
          );

      expect(() => valid(second: 14), throwsArgumentError);
      expect(() => valid(health: 1.1), throwsArgumentError);
      expect(() => valid(second: 345), throwsArgumentError);
      expect(valid().toJson()['phase'], 'learning');
    });
  });
}
