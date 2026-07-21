import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/balance/wave_regression_simulator.dart';
import 'package:pixel_survivor/game/balance/combat_rhythm.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';

void main() {
  test('twenty five-minute seeds preserve all wave invariants', () {
    const simulator = WaveRegressionSimulator();
    final reports = [
      for (var seed = 0; seed < 20; seed += 1) simulator.run(seed),
    ];

    for (final report in reports) {
      expect(report.durationSeconds, 300);
      expect(report.bossRequests, 1, reason: 'seed ${report.seed}');
      expect(report.capViolations, 0, reason: 'seed ${report.seed}');
      expect(
        report.overCapFrames,
        lessThanOrEqualTo(60),
        reason: 'pre-boss enemies drain naturally after the boss cap reset',
      );
      expect(report.invalidPoolRequests, 0, reason: 'seed ${report.seed}');
      expect(report.maxFrameSpawns, lessThanOrEqualTo(8));
      expect(report.maxActiveEnemies, lessThanOrEqualTo(96));
      expect(report.totalSpawns, greaterThanOrEqualTo(400));
      for (final enemyId in {
        plagueRatSwarm,
        vengefulSpirit,
        sakkatSpecter,
        dokkaebi,
      }) {
        expect(
          report.lateSliceEnemySpawnCounts[enemyId],
          greaterThan(0),
          reason:
              'seed ${report.seed} must spawn slice role $enemyId '
              'between 240 and 270 seconds',
        );
      }
      expect(
        report.phaseSpawnCounts.keys.toSet(),
        CombatRhythmPhaseId.values.toSet(),
      );
    }

    final pressureElites = reports.fold<int>(
      0,
      (sum, report) =>
          sum + (report.phaseEliteCounts[CombatRhythmPhaseId.pressure] ?? 0),
    );
    expect(pressureElites, greaterThan(0));
    expect(
      reports.map((report) => report.fingerprint).toSet().length,
      greaterThan(10),
    );

    final fixed = simulator.run(3107);
    expect(fixed.lateSliceEnemySpawnCounts, {
      plagueRatSwarm: 33,
      vengefulSpirit: 20,
      sakkatSpecter: 21,
      dokkaebi: 23,
      brokenJangseungSpirit: 7,
      sorrowfulMaidenGhost: 6,
    });
  });

  test('the same seed produces an identical regression fingerprint', () {
    const simulator = WaveRegressionSimulator();
    final first = simulator.run(7);
    final second = simulator.run(7);

    expect(first.fingerprint, second.fingerprint);
    expect(first.toJson(), second.toJson());
  });
}
