import 'package:flame/game.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/game_screen.dart';
import 'package:pixel_survivor/game/models/run_result.dart';
import 'package:pixel_survivor/game/pixel_survivor_game.dart';
import 'package:pixel_survivor/game/systems/run_telemetry_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingTelemetryService extends RunTelemetryService {
  RunResult? recordedResult;
  DateTime? recordedStart;

  @override
  Future<void> record(
    RunResult result, {
    required DateTime startedAtUtc,
  }) async {
    recordedResult = result;
    recordedStart = startedAtUtc;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('game screen records telemetry after a run ends', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final service = _RecordingTelemetryService();
    final startedAtUtc = DateTime.utc(2026, 7, 14, 3);
    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(telemetryService: service, now: () => startedAtUtc),
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

    expect(service.recordedResult, isNotNull);
    expect(service.recordedStart, startedAtUtc);
  });
}
