import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/records_screen.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/models/run_outcome.dart';
import 'package:pixel_survivor/game/models/run_telemetry.dart';
import 'package:pixel_survivor/game/systems/meta_history_service.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';

void main() {
  testWidgets('shows best record character victories and weapon usage', (
    tester,
  ) async {
    final state = SaveState.defaults().copyWith(
      bestSurvivalSeconds: 240,
      characterVictoryCounts: {rookieConstable: 3},
    );
    await tester.pumpWidget(
      _app(
        RecordsScreen(
          state: state,
          historyService: MetaHistoryService(
            loadHistory: () async => [
              _run(kills: {hwandoSlash: 7}, damage: {hwandoSlash: 20}),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('최고 생존 4:00'), findsOneWidget);
    expect(find.text('캐릭터별 승리'), findsOneWidget);
    expect(find.text('신참 포졸 3승'), findsOneWidget);
    expect(find.text('퇴마 도사 0승'), findsOneWidget);
    expect(find.text('무기 사용 기록'), findsOneWidget);
    expect(find.text('환도 베기'), findsOneWidget);
    expect(find.text('사용 1판 · 처치 7 · 피해 20'), findsOneWidget);
  });

  testWidgets('shows a Korean empty state when telemetry is empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        RecordsScreen(
          state: SaveState.defaults(),
          historyService: MetaHistoryService(loadHistory: () async => []),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('아직 저장된 무기 사용 기록이 없습니다.'), findsOneWidget);
  });

  testWidgets('records remain scrollable inside a small safe area', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app(
        RecordsScreen(
          state: SaveState.defaults(),
          historyService: MetaHistoryService(loadHistory: () async => []),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -300));
    await tester.pump();

    expect(find.byType(SafeArea), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps record summaries in two compact columns', (tester) async {
    tester.view.physicalSize = const Size(375, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        RecordsScreen(
          state: SaveState.defaults(),
          historyService: MetaHistoryService(loadHistory: () async => []),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('records-summary-grid')), findsOneWidget);
    expect(find.byKey(const Key('record-summary-card')), findsNWidgets(5));
  });
}

Widget _app(Widget home) => MaterialApp(
  theme: ThemeData(splashFactory: NoSplash.splashFactory),
  home: home,
);

RunTelemetry _run({
  Map<String, int> kills = const {},
  Map<String, double> damage = const {},
}) => RunTelemetry(
  runId: 'run',
  appVersion: 'test',
  startedAtUtc: DateTime.utc(2026),
  endedAtUtc: DateTime.utc(2026, 1, 1, 0, 1),
  outcome: RunOutcome.defeat,
  survivalSeconds: 60,
  level: 1,
  kills: 7,
  bossDefeated: false,
  weaponKillCounts: kills,
  weaponDamageTotals: damage,
);
