import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/systems/run_stats_tracker.dart';

void main() {
  group('RunStatsTracker', () {
    test('records kills and boss defeats in run results', () {
      final tracker = RunStatsTracker()
        ..recordEnemyDefeat(isBoss: false)
        ..recordEnemyDefeat(isBoss: true);

      final result = tracker.toRunResult(
        survivalSeconds: 91,
        level: 4,
        wonWithLowHealth: false,
      );

      expect(result.survivalSeconds, 91);
      expect(result.kills, 2);
      expect(result.level, 4);
      expect(result.bossDefeated, isTrue);
      expect(result.weaponKillCounts, isEmpty);
    });
  });
}
