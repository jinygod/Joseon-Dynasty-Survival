import 'dart:convert';

import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/game_screen.dart';
import 'package:pixel_survivor/game/models/run_result.dart';
import 'package:pixel_survivor/game/models/run_telemetry.dart';
import 'package:pixel_survivor/game/pixel_survivor_game.dart';
import 'package:pixel_survivor/game/systems/run_telemetry_service.dart';
import 'package:pixel_survivor/game/systems/telemetry_export_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingTelemetryService extends RunTelemetryService {
  RunResult? recordedResult;
  DateTime? recordedStart;

  @override
  Future<RunTelemetry?> record(
    RunResult result, {
    required DateTime startedAtUtc,
  }) async {
    recordedResult = result;
    recordedStart = startedAtUtc;
    return RunTelemetry.fromRunResult(
      result: result,
      runId: 'screen-run-id',
      appVersion: '0.1.0+1',
      startedAtUtc: startedAtUtc,
      endedAtUtc: startedAtUtc.add(const Duration(minutes: 3)),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('game screen records telemetry after a run ends', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    SharedPreferences.setMockInitialValues({});
    final service = _RecordingTelemetryService();
    final startedAtUtc = DateTime.utc(2026, 7, 14, 3);
    String? copiedJson;
    final exportService = TelemetryExportService(
      load: () async => [
        RunTelemetry.fromRunResult(
          result: service.recordedResult!,
          runId: 'screen-run-id',
          appVersion: '0.1.0+1',
          startedAtUtc: startedAtUtc,
          endedAtUtc: startedAtUtc.add(const Duration(minutes: 3)),
        ),
      ],
      writeClipboard: (value) async => copiedJson = value,
      shareJsonFile: (_, _, _) async {},
    );
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(
          telemetryService: service,
          telemetryExportService: exportService,
          now: () => startedAtUtc,
        ),
      ),
    );
    await tester.pump();
    final gameWidget = tester.widget<GameWidget<PixelSurvivorGame>>(
      find.byGame<PixelSurvivorGame>(),
    );
    final game = gameWidget.game!;
    await tester.runAsync(game.ready);

    game.debugKillPlayer();
    game.update(0.016);
    await tester.pump();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(service.recordedResult, isNotNull);
    expect(service.recordedStart, startedAtUtc);
    final copyFinder = find.byKey(const Key('copy-run-json'));
    await tester.ensureVisible(copyFinder);
    await tester.tap(copyFinder);
    await tester.pump();
    expect(
      (jsonDecode(copiedJson!) as Map<String, dynamic>)['runId'],
      'screen-run-id',
    );
  });
}
