import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/ids.dart';
import 'package:pixel_survivor/game/world/world_chunk_repository.dart';

void main() {
  test('sleeping enemies restore once without losing state', () {
    final repository = WorldChunkRepository(chunkSize: 512);
    final record = SleepingEnemyRecord(
      enemyId: 'plague_rat_swarm',
      position: Vector2(700, 1200),
      healthFraction: .35,
      rank: EnemyRank.normal,
      stateSeed: 91,
    );

    repository.sleepEnemy(record);
    final restored = repository.restoreEnemiesNear(
      const Rect.fromLTWH(512, 1024, 512, 512),
    );

    expect(restored, hasLength(1));
    expect(restored.single.enemyId, record.enemyId);
    expect(restored.single.healthFraction, .35);
    expect(repository.sleepingCount, 0);
    expect(
      repository.restoreEnemiesNear(
        const Rect.fromLTRB(-10000, -10000, 10000, 10000),
      ),
      isEmpty,
    );
  });

  test('recycled records retain visit pressure for future spawn planning', () {
    final repository = WorldChunkRepository(chunkSize: 512);
    repository.sleepEnemy(
      SleepingEnemyRecord(
        enemyId: 'bandit',
        position: Vector2(1500, 3500),
        healthFraction: 1,
        rank: EnemyRank.normal,
        stateSeed: 7,
      ),
    );

    expect(
      repository.recycleFarRecords(const Rect.fromLTWH(0, 0, 512, 512)),
      1,
    );
    expect(repository.sleepingCount, 0);
    expect(repository.visitPressureAt(Vector2(1500, 3500)), greaterThan(0));
  });

  test(
    'an overlapping chunk restores only records inside the active bounds',
    () {
      final repository = WorldChunkRepository(chunkSize: 512);
      for (final position in [Vector2(500, 100), Vector2(100, 100)]) {
        repository.sleepEnemy(
          SleepingEnemyRecord(
            enemyId: 'bandit',
            position: position,
            healthFraction: 1,
            rank: EnemyRank.normal,
            stateSeed: position.x.round(),
          ),
        );
      }

      final restored = repository.restoreEnemiesNear(
        const Rect.fromLTWH(450, 0, 100, 200),
      );

      expect(restored.map((record) => record.position.x), [500]);
      expect(repository.sleepingCount, 1);
    },
  );
}
