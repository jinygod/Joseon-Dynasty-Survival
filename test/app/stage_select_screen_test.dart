import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/stage_select_screen.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';

void main() {
  testWidgets('starts at saved stage and returns its id', (tester) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: StageSelectScreen(
          initialStageId: moonlitAbandonedOffice,
          onSelected: (value) => selected = value,
        ),
      ),
    );

    expect(find.text('달빛 폐관아'), findsOneWidget);
    expect(find.textContaining('5:00'), findsOneWidget);
    await tester.tap(find.byKey(const Key('stage-confirm')));
    expect(selected, moonlitAbandonedOffice);
  });
}
