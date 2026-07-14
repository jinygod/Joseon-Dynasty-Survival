import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';
import 'package:pixel_survivor/game/content/wave_definitions.dart';
import 'package:pixel_survivor/game/systems/wave_director.dart';

void main() {
  group('waveDefinitionForSecond', () {
    test('returns the exact definition at every time boundary', () {
      expect(waveDefinitionForSecond(0), same(waveDefinitions[0]));
      expect(waveDefinitionForSecond(59), same(waveDefinitions[0]));
      expect(waveDefinitionForSecond(60), same(waveDefinitions[1]));
      expect(waveDefinitionForSecond(120), same(waveDefinitions[2]));
      expect(waveDefinitionForSecond(180), same(waveDefinitions[3]));
      expect(waveDefinitionForSecond(240), same(waveDefinitions[4]));
      expect(waveDefinitionForSecond(270), same(waveDefinitions[5]));
      expect(waveDefinitionForSecond(330), same(waveDefinitions[5]));
    });
  });

  group('WaveDirector', () {
    test('uses the current enemy pool and respects active and frame caps', () {
      final director = WaveDirector(random: Random(7));

      final early = director.tick(
        elapsedSeconds: 30,
        dt: 8,
        activeEnemyCount: 0,
      );
      final late = director.tick(
        elapsedSeconds: 210,
        dt: 8,
        activeEnemyCount: 50,
      );

      expect(
        early.spawnRequests.map((request) => request.enemyId),
        everyElement(plagueRatSwarm),
      );
      expect(
        late.spawnRequests.map((request) => request.enemyId),
        everyElement(isIn(waveDefinitionForSecond(210).enemyWeights.keys)),
      );
      expect(late.spawnRequests.length, lessThanOrEqualTo(4));
      expect(late.spawnRequests.length, lessThanOrEqualTo(8));
      expect(late.maxActiveEnemies, 54);
    });

    test('limits consecutive requests for a selected enemy to group size', () {
      final director = WaveDirector(random: Random(4));
      final result = director.tick(
        elapsedSeconds: 120,
        dt: 20,
        activeEnemyCount: 0,
      );

      var consecutiveCount = 0;
      String? previousEnemyId;
      for (final request in result.spawnRequests) {
        if (request.enemyId == previousEnemyId) {
          consecutiveCount += 1;
        } else {
          previousEnemyId = request.enemyId;
          consecutiveCount = 1;
        }
        expect(consecutiveCount, lessThanOrEqualTo(3));
      }
    });

    test('returns a boss request only when 270 seconds is first crossed', () {
      final director = WaveDirector(random: Random(1));

      expect(
        director
            .tick(elapsedSeconds: 269.9, dt: 0.1, activeEnemyCount: 0)
            .spawnBoss,
        isFalse,
      );
      expect(
        director
            .tick(elapsedSeconds: 270, dt: 0.1, activeEnemyCount: 0)
            .spawnBoss,
        isTrue,
      );
      expect(
        director
            .tick(elapsedSeconds: 271, dt: 1, activeEnemyCount: 0)
            .spawnBoss,
        isFalse,
      );
    });
  });
}
