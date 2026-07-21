import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/enemy_definitions.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';
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

    test('pressure interpolates continuously inside the opening phase', () {
      expect(wavePressureForSecond(0).spawnsPerSecond, 1.0);
      expect(wavePressureForSecond(30).spawnsPerSecond, closeTo(1.2, 0.001));
      expect(
        wavePressureForSecond(59.999).spawnsPerSecond,
        closeTo(1.4, 0.001),
      );
      expect(wavePressureForSecond(30).maxActiveEnemies, 36);
      expect(wavePressureForSecond(-10).spawnsPerSecond, 1.0);
    });

    test('pre-boss cap peaks and boss phase stays populated', () {
      expect(wavePressureForSecond(240).maxActiveEnemies, 86);
      expect(wavePressureForSecond(269.999).maxActiveEnemies, 96);
      expect(wavePressureForSecond(270).spawnsPerSecond, 1.5);
      expect(wavePressureForSecond(329.999).maxActiveEnemies, 64);
    });

    test('each 180-270 second wave contains all four slice roles', () {
      final lateWaves = moonlitAbandonedOfficeWaves.where(
        (wave) => wave.startSecond >= 180 && wave.startSecond < 270,
      );

      for (final wave in lateWaves) {
        expect(
          wave.enemyWeights.keys,
          containsAll({
            plagueRatSwarm,
            vengefulSpirit,
            sakkatSpecter,
            dokkaebi,
          }),
          reason: '${wave.startSecond}-${wave.endSecond} seconds',
        );
      }
    });

    test('late pressure prioritizes count without inflating normal health', () {
      final pressure = wavePressureForSecond(255);

      expect(pressure.maxActiveEnemies, greaterThanOrEqualTo(90));
      expect(enemyDefinitionFor(plagueRatSwarm)!.maxHealth, 8);
      expect(enemyDefinitionFor(vengefulSpirit)!.maxHealth, 22);
      expect(enemyDefinitionFor(sakkatSpecter)!.maxHealth, 25);
      expect(enemyDefinitionFor(dokkaebi)!.maxHealth, 38);
    });

    test('stage rosters differ and plague market has higher pressure', () {
      final moonlit = waveDefinitionsForStage(moonlitAbandonedOffice);
      final plague = waveDefinitionsForStage(plagueMarket);

      expect(moonlit, same(waveDefinitions));
      expect(plague, isNot(same(moonlit)));
      expect(plague.first.enemyWeights, contains(plagueCrow));
      expect(plague[2].enemyWeights, contains(rottenHerbalist));
      for (final second in [0.0, 120.0, 240.0]) {
        final moonlitPressure = wavePressureForSecond(
          second,
          definitions: moonlit,
        );
        final plaguePressure = wavePressureForSecond(
          second,
          definitions: plague,
        );
        expect(
          plaguePressure.spawnsPerSecond,
          greaterThan(moonlitPressure.spawnsPerSecond),
        );
        expect(
          plaguePressure.maxActiveEnemies,
          greaterThan(moonlitPressure.maxActiveEnemies),
        );
      }
    });
  });

  group('WaveDirector', () {
    test('elite rolls select only explicit elite definitions', () {
      const definition = WaveDefinition(
        startSecond: 0,
        endSecond: 60,
        enemyWeights: {bandit: 1},
        eliteWeights: {blackHatAssassin: 1},
        startSpawnsPerSecond: 8,
        endSpawnsPerSecond: 8,
        groupSize: 8,
        startEliteChance: 1,
        endEliteChance: 1,
        startMaxActiveEnemies: 8,
        endMaxActiveEnemies: 8,
      );
      final director = WaveDirector(
        random: Random(1),
        definitions: [definition],
      );

      final requests = director
          .tick(elapsedSeconds: 1, dt: 1, activeEnemyCount: 0)
          .spawnRequests;

      expect(
        requests.map((request) => request.enemyId),
        everyElement(blackHatAssassin),
      );
      expect(requests.map((request) => request.isElite), everyElement(isTrue));
    });

    test('empty elite pool falls back to unscaled normal requests', () {
      const definition = WaveDefinition(
        startSecond: 0,
        endSecond: 60,
        enemyWeights: {bandit: 1},
        eliteWeights: {},
        startSpawnsPerSecond: 1,
        endSpawnsPerSecond: 1,
        groupSize: 1,
        startEliteChance: 1,
        endEliteChance: 1,
        startMaxActiveEnemies: 1,
        endMaxActiveEnemies: 1,
      );
      final request = WaveDirector(random: Random(2), definitions: [definition])
          .tick(elapsedSeconds: 1, dt: 1, activeEnemyCount: 0)
          .spawnRequests
          .single;

      expect(request.enemyId, bandit);
      expect(request.isElite, isFalse);
    });

    test('wave content references valid ranks and positive weights', () {
      expect(validateWaveContent(), isEmpty);
    });

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
        activeEnemyCount: 68,
      );

      expect(
        early.spawnRequests.map((request) => request.enemyId),
        everyElement(plagueRatSwarm),
      );
      expect(
        late.spawnRequests
            .where((request) => !request.isElite)
            .map((request) => request.enemyId),
        everyElement(isIn(waveDefinitionForSecond(210).enemyWeights.keys)),
      );
      expect(
        late.spawnRequests
            .where((request) => request.isElite)
            .map((request) => request.enemyId),
        everyElement(isIn(waveDefinitionForSecond(210).eliteWeights.keys)),
      );
      expect(late.spawnRequests.length, lessThanOrEqualTo(8));
      expect(late.maxActiveEnemies, 77);
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
        expect(consecutiveCount, lessThanOrEqualTo(4));
      }
    });

    test('spawn budget cannot retain more than one frame of backlog', () {
      final director = WaveDirector(random: Random(2));

      final blocked = director.tick(
        elapsedSeconds: 260,
        dt: 100,
        activeEnemyCount: 96,
      );
      final released = director.tick(
        elapsedSeconds: 260.1,
        dt: 0,
        activeEnemyCount: 0,
      );

      expect(blocked.spawnRequests, isEmpty);
      expect(released.spawnRequests, hasLength(WaveDirector.frameSpawnCap));
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
