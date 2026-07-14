import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/models/run_outcome.dart';
import 'package:pixel_survivor/game/systems/run_stats_tracker.dart';

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
  });
}
