import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/stage_select_screen.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';

void main() {
  testWidgets('stage card explains the five-minute run contract', (
    tester,
  ) async {
    String? launchedStageId;
    await tester.pumpWidget(
      MaterialApp(
        home: StageSelectScreen(
          onStart: (stageId) => launchedStageId = stageId,
        ),
      ),
    );

    expect(find.text('달빛 폐관아'), findsOneWidget);
    expect(find.textContaining('5:00'), findsOneWidget);
    expect(find.textContaining('4:30'), findsOneWidget);
    expect(find.textContaining('보스 처치'), findsOneWidget);
    expect(
      find.byKey(const Key('stage-moonlit_abandoned_office')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('stage-start')));
    expect(launchedStageId, moonlitAbandonedOffice);
  });
}
