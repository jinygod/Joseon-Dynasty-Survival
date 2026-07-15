import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/balance/weapon_balance_baseline.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/models/run_choice_record.dart';
import 'package:pixel_survivor/game/models/run_outcome.dart';
import 'package:pixel_survivor/game/models/run_telemetry.dart';

void main() {
  group('WeaponBaselineSimulator', () {
    test('simulates all forty implemented weapon levels', () {
      final report = const WeaponBaselineSimulator().simulate();

      expect(report.rows, hasLength(40));
      expect(report.rows.map((row) => row.weaponId).toSet(), {
        hwandoSlash,
        gakgungShot,
        talismanThrow,
        thunderCrashBomb,
        jangseungWard,
        singijeonVolley,
        frostFlask,
        windThunderFan,
      });
      expect(report.unsupportedWeaponIds, isEmpty);
      expect(report.rows.every((row) => row.dps > 0), isTrue);
      expect(report.rows.every((row) => row.killsPerMinute > 0), isTrue);
    });

    test('is deterministic and level five improves over level one', () {
      final first = const WeaponBaselineSimulator().simulate();
      final second = const WeaponBaselineSimulator().simulate();

      expect(first.toJson(), second.toJson());
      for (final weaponId in first.supportedWeaponIds) {
        final levelOne = first.rowFor(weaponId, 1);
        final levelFive = first.rowFor(weaponId, 5);
        expect(levelFive.dps, greaterThan(levelOne.dps), reason: weaponId);
        expect(
          levelFive.killsPerMinute,
          greaterThan(levelOne.killsPerMinute),
          reason: weaponId,
        );
      }
    });

    test('uses the documented 60-second damage budget', () {
      final row = const WeaponBaselineSimulator().simulate().rowFor(
        hwandoSlash,
        1,
      );

      expect(row.attacks, 84);
      expect(row.damage, 672);
      expect(row.dps, 11.2);
      expect(row.killsPerMinute, 33);
    });
  });

  group('WeaponUsageAggregator', () {
    test('calculates run usage observed DPS and kills per minute', () {
      final rows = const WeaponUsageAggregator().aggregate([
        _run(
          id: 'a',
          seconds: 60,
          damage: {hwandoSlash: 600, talismanThrow: 120},
          kills: {hwandoSlash: 20, talismanThrow: 4},
        ),
        _run(
          id: 'b',
          seconds: 60,
          damage: {hwandoSlash: 300},
          kills: {hwandoSlash: 10},
        ),
      ]);

      final hwando = rows.singleWhere((row) => row.weaponId == hwandoSlash);
      final talisman = rows.singleWhere((row) => row.weaponId == talismanThrow);
      expect(hwando.usedRuns, 2);
      expect(hwando.usageRate, 1);
      expect(hwando.observedDps, 7.5);
      expect(hwando.killsPerMinute, 15);
      expect(talisman.usedRuns, 1);
      expect(talisman.usageRate, 0.5);
      expect(talisman.observedDps, 2);
      expect(talisman.killsPerMinute, 4);
    });

    test('ignores zero-duration runs for rate denominators safely', () {
      final rows = const WeaponUsageAggregator().aggregate([
        _run(
          id: 'zero',
          seconds: 0,
          damage: {hwandoSlash: 10},
          kills: const {},
        ),
      ]);

      expect(rows.single.observedDps, 0);
      expect(rows.single.killsPerMinute, 0);
      expect(rows.single.usageRate, 1);
    });

    test('counts a selected weapon even before it deals damage', () {
      final rows = const WeaponUsageAggregator().aggregate([
        _run(
          id: 'choice',
          seconds: 30,
          damage: const {},
          kills: const {},
          choices: const [
            RunChoiceRecord(
              type: RunChoiceType.weapon,
              contentId: talismanThrow,
              selectedAtSeconds: 20,
              selectedLevel: 1,
            ),
          ],
        ),
      ]);

      expect(rows.single.weaponId, talismanThrow);
      expect(rows.single.usageRate, 1);
      expect(rows.single.observedDps, 0);
    });
  });
}

RunTelemetry _run({
  required String id,
  required int seconds,
  required Map<String, double> damage,
  required Map<String, int> kills,
  List<RunChoiceRecord> choices = const [],
}) {
  final started = DateTime.utc(2026, 7, 15);
  return RunTelemetry(
    runId: id,
    appVersion: 'test',
    startedAtUtc: started,
    endedAtUtc: started.add(Duration(seconds: seconds)),
    outcome: RunOutcome.defeat,
    survivalSeconds: seconds,
    level: 1,
    kills: kills.values.fold(0, (total, value) => total + value),
    bossDefeated: false,
    weaponKillCounts: kills,
    weaponDamageTotals: damage,
    choices: choices,
  );
}
