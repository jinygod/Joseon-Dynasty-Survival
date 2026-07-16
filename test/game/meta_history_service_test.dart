import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/models/run_outcome.dart';
import 'package:pixel_survivor/game/models/run_telemetry.dart';
import 'package:pixel_survivor/game/systems/meta_history_service.dart';

void main() {
  test('aggregates existing telemetry in weapon definition order', () async {
    final service = MetaHistoryService(
      loadHistory: () async => [
        _run(
          'one',
          kills: {hwandoSlash: 3, gakgungShot: 2},
          damage: {hwandoSlash: 20},
        ),
        _run(
          'two',
          kills: {hwandoSlash: 4, 'unknown': 99},
          damage: {gakgungShot: 12.5, 'unknown': 999},
        ),
      ],
    );

    final records = await service.loadWeaponUsage();

    expect(records.map((record) => record.weaponId), [
      hwandoSlash,
      gakgungShot,
    ]);
    expect(records.first.usageRuns, 2);
    expect(records.first.kills, 7);
    expect(records.first.damage, 20);
    expect(records.last.usageRuns, 2);
    expect(records.last.kills, 2);
    expect(records.last.damage, 12.5);
  });

  test('returns an empty history when no weapon was recorded', () async {
    final service = MetaHistoryService(loadHistory: () async => [_run('one')]);

    expect(await service.loadWeaponUsage(), isEmpty);
  });

  test('recovers repository read failures as an empty history', () async {
    final service = MetaHistoryService(
      loadHistory: () async => throw StateError('damaged'),
    );

    expect(await service.loadWeaponUsage(), isEmpty);
  });
}

RunTelemetry _run(
  String id, {
  Map<String, int> kills = const {},
  Map<String, double> damage = const {},
}) => RunTelemetry(
  runId: id,
  appVersion: 'test',
  startedAtUtc: DateTime.utc(2026),
  endedAtUtc: DateTime.utc(2026, 1, 1, 0, 1),
  outcome: RunOutcome.defeat,
  survivalSeconds: 60,
  level: 1,
  kills: kills.values.fold(0, (sum, value) => sum + value),
  bossDefeated: false,
  weaponKillCounts: kills,
  weaponDamageTotals: damage,
);
