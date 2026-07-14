import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/balance/enemy_balance_baseline.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';

void main() {
  group('EnemyBalanceAnalyzer', () {
    test('learning fodder dies in one starter hit', () {
      final report = const EnemyBalanceAnalyzer().analyze();
      final rat = report.rowFor(plagueRatSwarm);

      expect(rat.starterHitsToKill, 1);
      expect(rat.starterTimeToKillSeconds, 0);
    });

    test('regular enemy roles stay inside combat safety targets', () {
      final report = const EnemyBalanceAnalyzer().analyze();

      expect(report.rows, hasLength(4));
      expect(report.meetsSafetyTargets, isTrue);
      expect(
        report.rows.every((row) => row.starterTimeToKillSeconds <= 3),
        isTrue,
      );
      expect(
        report.rows.every((row) => row.continuousContactSurvivalSeconds >= 4),
        isTrue,
      );
      expect(report.rows.every((row) => row.speedRatio < 0.5), isTrue);
    });

    test('pressure caps rise before boss relief', () {
      final report = const EnemyBalanceAnalyzer().analyze();

      expect(report.preBossActiveCaps, [24, 32, 42, 54, 64]);
      expect(report.preBossSpawnRates, [0.65, 0.90, 1.15, 1.45, 1.80]);
      expect(report.bossActiveCap, 28);
      expect(report.hasMonotonicPreBossPressure, isTrue);
      expect(report.bossActiveCap, lessThan(report.preBossActiveCaps.last));
    });
  });
}
