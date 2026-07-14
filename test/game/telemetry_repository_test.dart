import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/models/run_outcome.dart';
import 'package:pixel_survivor/game/models/run_feedback.dart';
import 'package:pixel_survivor/game/models/run_telemetry.dart';
import 'package:pixel_survivor/game/systems/telemetry_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  RunTelemetry telemetry(int index) => RunTelemetry(
    runId: 'run-$index',
    appVersion: '0.1.0+1',
    startedAtUtc: DateTime.utc(2026, 7, 14).add(Duration(minutes: index)),
    endedAtUtc: DateTime.utc(2026, 7, 14).add(Duration(minutes: index + 5)),
    outcome: RunOutcome.victory,
    survivalSeconds: 300,
    level: 10,
    kills: index,
    bossDefeated: true,
    weaponKillCounts: const {},
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'repository appends and loads telemetry in chronological order',
    () async {
      final repository = TelemetryRepository();

      await repository.append(telemetry(1));
      await repository.append(telemetry(2));

      final loaded = await repository.load();
      expect(loaded.map((run) => run.runId), ['run-1', 'run-2']);
    },
  );

  test('repository treats a malformed store as empty', () async {
    SharedPreferences.setMockInitialValues({
      TelemetryRepository.storageKey: '{broken-json',
    });

    final loaded = await TelemetryRepository().load();

    expect(loaded, isEmpty);
  });

  test('repository skips malformed individual rows', () async {
    SharedPreferences.setMockInitialValues({
      TelemetryRepository.storageKey: jsonEncode([
        telemetry(1).toJson(),
        {'schemaVersion': 999},
        'not-a-map',
      ]),
    });

    final loaded = await TelemetryRepository().load();

    expect(loaded.map((run) => run.runId), ['run-1']);
  });

  test('repository retains only the latest fifty runs', () async {
    final repository = TelemetryRepository();

    for (var index = 1; index <= 51; index += 1) {
      await repository.append(telemetry(index));
    }

    final loaded = await repository.load();
    expect(loaded, hasLength(50));
    expect(loaded.first.runId, 'run-2');
    expect(loaded.last.runId, 'run-51');
  });

  test('repository updates feedback by run id without reordering', () async {
    final repository = TelemetryRepository();
    await repository.append(telemetry(1));
    await repository.append(telemetry(2));
    final feedback = RunFeedback(
      funRating: 4,
      difficultyRating: 3,
      retryIntent: true,
      comment: '다시 하고 싶음',
    );

    final updated = await repository.updateFeedback('run-2', feedback);
    final loaded = await repository.load();

    expect(updated, isTrue);
    expect(loaded.map((run) => run.runId), ['run-1', 'run-2']);
    expect(loaded.first.feedback, isNull);
    expect(loaded.last.feedback, feedback);
  });

  test('repository returns false for unknown feedback run id', () async {
    final repository = TelemetryRepository();
    await repository.append(telemetry(1));
    final feedback = RunFeedback(
      funRating: 4,
      difficultyRating: 3,
      retryIntent: false,
      comment: '',
    );

    final updated = await repository.updateFeedback('missing', feedback);

    expect(updated, isFalse);
    expect((await repository.load()).single.feedback, isNull);
  });
}
