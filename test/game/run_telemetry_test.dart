import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/models/run_outcome.dart';
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
}
