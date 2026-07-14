import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/models/run_outcome.dart';
import 'package:pixel_survivor/game/models/run_result.dart';
import 'package:pixel_survivor/game/models/run_telemetry.dart';
import 'package:pixel_survivor/game/systems/run_telemetry_service.dart';

void main() {
  const result = RunResult(
    outcome: RunOutcome.victory,
    survivalSeconds: 300,
    kills: 420,
    level: 10,
    bossDefeated: true,
    wonWithLowHealth: false,
    weaponKillCounts: {'hwando_slash': 420},
    weaponLevels: {'hwando_slash': 5},
    weaponDamageTotals: {'hwando_slash': 6000},
  );
  final startedAtUtc = DateTime.utc(2026, 7, 14, 1);
  final endedAtUtc = DateTime.utc(2026, 7, 14, 1, 5);

  test('service maps a completed run with runtime app version', () async {
    RunTelemetry? saved;
    final service = RunTelemetryService(
      append: (telemetry) async => saved = telemetry,
      loadAppVersion: () async => '0.1.0+1',
      now: () => endedAtUtc,
    );

    await service.record(result, startedAtUtc: startedAtUtc);

    expect(saved, isNotNull);
    expect(
      saved!.runId,
      '${startedAtUtc.microsecondsSinceEpoch}-${endedAtUtc.microsecondsSinceEpoch}',
    );
    expect(saved!.appVersion, '0.1.0+1');
    expect(saved!.startedAtUtc, startedAtUtc);
    expect(saved!.endedAtUtc, endedAtUtc);
    expect(saved!.kills, 420);
    expect(saved!.weaponDamageTotals, {'hwando_slash': 6000});
  });

  test('service isolates telemetry persistence failures', () async {
    final service = RunTelemetryService(
      append: (_) async => throw StateError('disk full'),
      loadAppVersion: () async => '0.1.0+1',
      now: () => endedAtUtc,
    );

    await expectLater(
      service.record(result, startedAtUtc: startedAtUtc),
      completes,
    );
  });

  test('service isolates package metadata failures', () async {
    final service = RunTelemetryService(
      append: (_) async => fail('append must not run'),
      loadAppVersion: () async => throw StateError('platform unavailable'),
      now: () => endedAtUtc,
    );

    await expectLater(
      service.record(result, startedAtUtc: startedAtUtc),
      completes,
    );
  });
}
