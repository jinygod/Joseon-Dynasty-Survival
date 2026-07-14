import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/models/run_feedback.dart';
import 'package:pixel_survivor/game/models/run_outcome.dart';
import 'package:pixel_survivor/game/models/run_telemetry.dart';
import 'package:pixel_survivor/game/systems/telemetry_export_service.dart';

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
}
