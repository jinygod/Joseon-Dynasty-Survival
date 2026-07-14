import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/models/run_choice_record.dart';
import 'package:pixel_survivor/game/models/run_outcome.dart';
import 'package:pixel_survivor/game/models/run_result.dart';
import 'package:pixel_survivor/game/models/run_telemetry.dart';

void main() {
  test('run telemetry JSON round trip preserves schema one fields', () {
    final telemetry = RunTelemetry(
      runId: 'run-20260714-001',
      appVersion: '0.1.0+1',
      startedAtUtc: DateTime.utc(2026, 7, 14, 1),
      endedAtUtc: DateTime.utc(2026, 7, 14, 1, 5),
      outcome: RunOutcome.victory,
      survivalSeconds: 300,
      level: 10,
      kills: 427,
      bossDefeated: true,
      weaponKillCounts: const {'basic_slash': 300, 'talisman_throw': 127},
    );

    final decoded = RunTelemetry.fromJson(telemetry.toJson());

    expect(decoded.schemaVersion, RunTelemetry.currentSchemaVersion);
    expect(decoded.runId, telemetry.runId);
    expect(decoded.appVersion, telemetry.appVersion);
    expect(decoded.startedAtUtc, telemetry.startedAtUtc);
    expect(decoded.endedAtUtc, telemetry.endedAtUtc);
    expect(decoded.outcome, telemetry.outcome);
    expect(decoded.survivalSeconds, telemetry.survivalSeconds);
    expect(decoded.level, telemetry.level);
    expect(decoded.kills, telemetry.kills);
    expect(decoded.bossDefeated, telemetry.bossDefeated);
    expect(decoded.weaponKillCounts, telemetry.weaponKillCounts);
  });

  test('run telemetry rejects a future schema version', () {
    expect(
      () => RunTelemetry.fromJson(const {'schemaVersion': 999}),
      throwsFormatException,
    );
  });

  test('run telemetry round trip preserves extended playtest metrics', () {
    final telemetry = RunTelemetry(
      runId: 'extended-run',
      appVersion: '0.1.0+1',
      startedAtUtc: DateTime.utc(2026, 7, 14, 2),
      endedAtUtc: DateTime.utc(2026, 7, 14, 2, 4),
      outcome: RunOutcome.defeat,
      survivalSeconds: 240,
      level: 8,
      kills: 200,
      bossDefeated: false,
      weaponKillCounts: const {'basic_slash': 200},
      weaponDamageTotals: const {'basic_slash': 1234.5},
      choices: const [
        RunChoiceRecord(
          type: RunChoiceType.weapon,
          contentId: 'basic_slash',
          selectedAtSeconds: 20,
          selectedLevel: 2,
        ),
        RunChoiceRecord(
          type: RunChoiceType.augment,
          contentId: 'inner_breath',
          selectedAtSeconds: 45,
          selectedLevel: 1,
        ),
      ],
      totalDamageTaken: 105.5,
      lastDamageSource: 'vengeful_spirit',
      deathAtSeconds: 240,
    );

    final decoded = RunTelemetry.fromJson(telemetry.toJson());

    expect(decoded.weaponDamageTotals, telemetry.weaponDamageTotals);
    expect(decoded.choices, telemetry.choices);
    expect(decoded.totalDamageTaken, 105.5);
    expect(decoded.lastDamageSource, 'vengeful_spirit');
    expect(decoded.deathAtSeconds, 240);
  });

  test('run telemetry maps every run result metric', () {
    const result = RunResult(
      outcome: RunOutcome.victory,
      survivalSeconds: 300,
      kills: 400,
      level: 10,
      bossDefeated: true,
      wonWithLowHealth: false,
      weaponKillCounts: {'basic_slash': 400},
      weaponLevels: {'basic_slash': 5},
      weaponDamageTotals: {'basic_slash': 5000},
      choices: [
        RunChoiceRecord(
          type: RunChoiceType.weapon,
          contentId: 'basic_slash',
          selectedAtSeconds: 12,
          selectedLevel: 2,
        ),
      ],
      totalDamageTaken: 20,
      lastDamageSource: 'plague_rat',
    );

    final telemetry = RunTelemetry.fromRunResult(
      result: result,
      runId: 'mapped-run',
      appVersion: '0.1.0+1',
      startedAtUtc: DateTime.utc(2026, 7, 14),
      endedAtUtc: DateTime.utc(2026, 7, 14, 0, 5),
    );

    expect(telemetry.runId, 'mapped-run');
    expect(telemetry.outcome, RunOutcome.victory);
    expect(telemetry.weaponDamageTotals, {'basic_slash': 5000});
    expect(telemetry.choices, result.choices);
    expect(telemetry.totalDamageTaken, 20);
    expect(telemetry.lastDamageSource, 'plague_rat');
    expect(telemetry.deathAtSeconds, isNull);
  });

  test('schema one payload without extended fields remains readable', () {
    final decoded = RunTelemetry.fromJson({
      'schemaVersion': 1,
      'runId': 'legacy-run',
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

    expect(decoded.weaponDamageTotals, isEmpty);
    expect(decoded.choices, isEmpty);
    expect(decoded.totalDamageTaken, 0);
    expect(decoded.lastDamageSource, isNull);
    expect(decoded.deathAtSeconds, isNull);
  });
}
