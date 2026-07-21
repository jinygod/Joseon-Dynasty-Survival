import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/models/combat_playtest_metrics.dart';
import 'package:pixel_survivor/game/models/run_feedback.dart';
import 'package:pixel_survivor/game/models/run_outcome.dart';
import 'package:pixel_survivor/game/models/run_telemetry.dart';
import 'package:pixel_survivor/game/systems/telemetry_export_service.dart';
import 'package:pixel_survivor/game/systems/combat_playtest_tracker.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';

void main() {
  RunTelemetry telemetry(String runId) => RunTelemetry(
    runId: runId,
    appVersion: '0.1.0+1',
    startedAtUtc: DateTime.utc(2026, 7, 14),
    endedAtUtc: DateTime.utc(2026, 7, 14, 0, 5),
    outcome: RunOutcome.victory,
    survivalSeconds: 300,
    level: 10,
    kills: 400,
    bossDefeated: true,
    weaponKillCounts: const {},
    feedback: RunFeedback(
      funRating: 4,
      difficultyRating: 3,
      retryIntent: true,
      comment: '재미있음',
    ),
  );

  test('copyRun writes requested run JSON including feedback', () async {
    String? copied;
    final service = TelemetryExportService(
      load: () async => [telemetry('run-1'), telemetry('run-2')],
      writeClipboard: (value) async => copied = value,
      shareJsonFile: (_, _, _) async {},
    );

    final copiedRun = await service.copyRun('run-2');
    final decoded = jsonDecode(copied!) as Map<String, dynamic>;

    expect(copiedRun, isTrue);
    expect(decoded['runId'], 'run-2');
    expect((decoded['feedback'] as Map<String, dynamic>)['funRating'], 4);
  });

  test('copyRun returns false when the run does not exist', () async {
    var writes = 0;
    final service = TelemetryExportService(
      load: () async => [telemetry('run-1')],
      writeClipboard: (_) async => writes += 1,
      shareJsonFile: (_, _, _) async {},
    );

    expect(await service.copyRun('missing'), isFalse);
    expect(writes, 0);
  });

  test('exportAll shares UTF-8 JSON history with a stable filename', () async {
    String? fileName;
    String? mimeType;
    List<int>? bytes;
    final service = TelemetryExportService(
      load: () async => [telemetry('run-1'), telemetry('run-2')],
      writeClipboard: (_) async {},
      shareJsonFile: (name, mime, data) async {
        fileName = name;
        mimeType = mime;
        bytes = data;
      },
    );

    final exported = await service.exportAll();
    final decoded = jsonDecode(utf8.decode(bytes!)) as List<dynamic>;

    expect(exported, isTrue);
    expect(fileName, 'run-telemetry.json');
    expect(mimeType, 'application/json');
    expect(decoded, hasLength(2));
    expect((decoded.last as Map<String, dynamic>)['runId'], 'run-2');
  });

  test('exportAll returns false without sharing an empty history', () async {
    var shares = 0;
    final service = TelemetryExportService(
      load: () async => const [],
      writeClipboard: (_) async {},
      shareJsonFile: (_, _, _) async => shares += 1,
    );

    expect(await service.exportAll(), isFalse);
    expect(shares, 0);
  });

  RunTelemetry combatTelemetry({
    required String runId,
    required RunOutcome outcome,
    required Map<String, double> weaponDamageTotals,
    required CombatPlaytestMetrics combatMetrics,
  }) => RunTelemetry(
    runId: runId,
    appVersion: '0.1.0+1',
    startedAtUtc: DateTime.utc(2026, 7, 14),
    endedAtUtc: DateTime.utc(2026, 7, 14, 0, 5),
    outcome: outcome,
    survivalSeconds: 300,
    level: 10,
    kills: 400,
    bossDefeated: outcome == RunOutcome.victory,
    weaponKillCounts: const {},
    weaponDamageTotals: weaponDamageTotals,
    combatMetrics: combatMetrics,
  );

  CombatPlaytestMetrics metrics({
    Map<String, int> offers = const {},
    Map<String, int> selections = const {},
    Map<String, Map<int, double>> levelTimes = const {},
    Map<String, double> masterTimes = const {},
    Map<String, int> masterKills = const {},
    Map<String, double> synergyTimes = const {},
    Map<String, double> synergyDamage = const {},
    Map<String, double> roleDamage = const {},
    Map<String, int> deathCauses = const {},
    double averageEnemyCount = 0,
    int maxEnemyCount = 0,
    double lateAverageFps = 0,
    double lateMinFps = 0,
    Set<String> mastered = const {},
    bool repeat = false,
  }) => CombatPlaytestMetrics(
    weaponOfferCounts: offers,
    weaponSelectionCounts: selections,
    weaponLevelTimes: levelTimes,
    firstMasterAtSeconds: masterTimes,
    masterKillsInTenSeconds: masterKills,
    firstSynergyAtSeconds: synergyTimes,
    synergyDamageTotals: synergyDamage,
    enemyRoleDamageToPlayer: roleDamage,
    enemyRoleDeathCauses: deathCauses,
    averageEnemyCount: averageEnemyCount,
    maxEnemyCount: maxEnemyCount,
    lateAverageFps: lateAverageFps,
    lateMinFps: lateMinFps,
    masteredWeaponIds: mastered,
    isRepeatRun: repeat,
  );

  test('aggregate exposes all typed combat report metrics', () {
    final masterWin = combatTelemetry(
      runId: 'master-win',
      outcome: RunOutcome.victory,
      weaponDamageTotals: const {'hwando_slash': 600, 'sealing_slash': 100},
      combatMetrics: metrics(
        offers: const {'hwando_slash': 2, 'talisman_throw': 1},
        selections: const {'hwando_slash': 1, 'talisman_throw': 1},
        levelTimes: const {
          'hwando_slash': {3: 80, 6: 180},
        },
        masterTimes: const {'hwando_slash': 180},
        masterKills: const {'hwando_slash': 12},
        synergyTimes: const {'sealing_slash': 120},
        synergyDamage: const {'sealing_slash': 100},
        roleDamage: const {'ranged': 20},
        deathCauses: const {'charge': 1},
        averageEnemyCount: 30,
        maxEnemyCount: 60,
        lateAverageFps: 58,
        lateMinFps: 45,
        mastered: const {'hwando_slash'},
        repeat: true,
      ),
    );
    final masterLoss = combatTelemetry(
      runId: 'master-loss',
      outcome: RunOutcome.defeat,
      weaponDamageTotals: const {'hwando_slash': 200},
      combatMetrics: metrics(
        offers: const {'hwando_slash': 2},
        selections: const {'hwando_slash': 1},
        levelTimes: const {
          'hwando_slash': {3: 100, 6: 220},
        },
        masterTimes: const {'hwando_slash': 220},
        masterKills: const {'hwando_slash': 8},
        roleDamage: const {'ranged': 10, 'tank': 15},
        averageEnemyCount: 20,
        maxEnemyCount: 50,
        lateAverageFps: 54,
        lateMinFps: 40,
        mastered: const {'hwando_slash'},
      ),
    );
    final noMasterLoss = combatTelemetry(
      runId: 'no-master-loss',
      outcome: RunOutcome.defeat,
      weaponDamageTotals: const {'talisman_throw': 100},
      combatMetrics: metrics(
        offers: const {'talisman_throw': 1, 'zero-offer': 0},
        selections: const {'talisman_throw': 1, 'zero-offer': 1},
        averageEnemyCount: 10,
        maxEnemyCount: 40,
        lateAverageFps: 50,
        lateMinFps: 35,
      ),
    );

    final report = TelemetryExportService().aggregate([
      masterWin,
      masterLoss,
      noMasterLoss,
    ]);

    expect(report.runCount, 3);
    expect(report.weaponOfferCounts, {
      'hwando_slash': 4,
      'talisman_throw': 2,
      'zero-offer': 0,
    });
    expect(report.weaponSelectionCounts, {
      'hwando_slash': 2,
      'talisman_throw': 2,
      'zero-offer': 1,
    });
    expect(report.weaponSelectionRates, {
      'hwando_slash': .5,
      'talisman_throw': 1,
      'zero-offer': 0,
    });
    expect(report.weaponDamageShares['hwando_slash'], closeTo(.8, .0001));
    expect(report.weaponDamageShares['sealing_slash'], closeTo(.1, .0001));
    expect(report.weaponLevelAverageTimes['hwando_slash'], {3: 90, 6: 200});
    expect(report.firstMasterAverageSeconds, {'hwando_slash': 200});
    expect(report.masterKillsInTenSecondsAverage, {'hwando_slash': 10});
    expect(report.firstSynergyAverageSeconds, {'sealing_slash': 120});
    expect(report.synergyDamageShares, {'sealing_slash': closeTo(.1, .0001)});
    expect(report.synergyDamageShare, closeTo(.1, .0001));
    expect(report.enemyRoleDamageToPlayer, {'ranged': 30, 'tank': 15});
    expect(report.enemyRoleDeathCauses, {'charge': 1});
    expect(report.averageEnemyCount, 20);
    expect(report.maxEnemyCount, 60);
    expect(report.lateAverageFps, 54);
    expect(report.lateMinFps, 35);
    expect(report.masteredRunWinRate, .5);
    expect(report.nonMasteredRunWinRate, 0);
    expect(report.repeatRunRate, closeTo(1 / 3, .0001));
  });

  test(
    'level six selected before run end aggregates as mastered before firing',
    () {
      final metrics =
          (CombatPlaytestTracker()
                ..recordLevel(weaponId: hwandoSlash, level: 6, atSeconds: 299))
              .snapshot();
      final run = combatTelemetry(
        runId: 'mastered-before-next-fire',
        outcome: RunOutcome.defeat,
        weaponDamageTotals: const {},
        combatMetrics: metrics,
      );

      final report = TelemetryExportService().aggregate([run]);

      expect(report.firstMasterAverageSeconds, {hwandoSlash: 299});
      expect(report.masteredRunWinRate, 0);
      expect(report.nonMasteredRunWinRate, 0);
      expect(report.masterKillsInTenSecondsAverage, isEmpty);
    },
  );

  test('aggregate handles empty and schema one metrics without NaN', () {
    final legacy = RunTelemetry.fromJson({
      'schemaVersion': 1,
      'runId': 'legacy',
      'appVersion': '0.1.0+1',
      'startedAtUtc': '2026-07-14T00:00:00.000Z',
      'endedAtUtc': '2026-07-14T00:05:00.000Z',
      'outcome': 'victory',
      'survivalSeconds': 300,
      'level': 10,
      'kills': 400,
      'bossDefeated': true,
      'weaponKillCounts': <String, int>{},
    });

    for (final report in [
      TelemetryExportService().aggregate(const []),
      TelemetryExportService().aggregate([legacy]),
    ]) {
      expect(report.weaponSelectionRates, isEmpty);
      expect(report.weaponDamageShares, isEmpty);
      expect(report.synergyDamageShare, 0);
      expect(report.averageEnemyCount, 0);
      expect(report.lateAverageFps, 0);
      expect(report.lateMinFps, 0);
      expect(report.masteredRunWinRate, 0);
      expect(report.nonMasteredRunWinRate, 0);
      expect(report.repeatRunRate, 0);
    }
  });

  test('aggregate excludes unobserved late FPS sentinels', () {
    RunTelemetry run(
      String id,
      double averageFps,
      double minFps,
      double averageEnemies, {
      bool repeat = false,
    }) => combatTelemetry(
      runId: id,
      outcome: RunOutcome.defeat,
      weaponDamageTotals: const {},
      combatMetrics: metrics(
        averageEnemyCount: averageEnemies,
        lateAverageFps: averageFps,
        lateMinFps: minFps,
        repeat: repeat,
      ),
    );

    final report = TelemetryExportService().aggregate([
      run('early-ended', 0, 0, 3, repeat: true),
      run('measured-a', 58, 41, 6),
      run('measured-b', 52, 35, 9),
    ]);

    expect(report.lateAverageFps, 55);
    expect(report.lateMinFps, 35);
    expect(report.averageEnemyCount, 6);
    expect(report.repeatRunRate, closeTo(1 / 3, .0001));
  });
}
