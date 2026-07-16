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

      expect(report.rows, hasLength(8));
      expect(report.rows.map((row) => row.enemyId).toSet(), {
        plagueRatSwarm,
        bandit,
        dokkaebi,
        vengefulSpirit,
        plagueCrow,
        spearBandit,
        rottenHerbalist,
        graveEmber,
      });
      expect(report.eliteRows, hasLength(3));
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

      expect(report.preBossActiveCaps, [40, 52, 66, 80, 92]);
      expect(report.preBossSpawnRates, [
        closeTo(1.4, 0.001),
        closeTo(1.9, 0.001),
        closeTo(2.5, 0.001),
        closeTo(3.2, 0.001),
        closeTo(4.0, 0.001),
      ]);
      expect(report.bossActiveCap, 48);
      expect(report.hasMonotonicPreBossPressure, isTrue);
      expect(report.bossActiveCap, lessThan(report.preBossActiveCaps.last));
    });
  });
}
