import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/first_run_tutorial_overlay.dart';

void main() {
  testWidgets('tutorial explains the five run mechanics in order', (
    tester,
  ) async {
    var completions = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: FirstRunTutorialOverlay(onCompleted: () => completions += 1),
      ),
    );

    for (final title in const ['이동', '자동 공격', '경험치', '레벨업', '보스 경고']) {
      expect(find.text(title), findsOneWidget);
      if (title != '보스 경고') {
        await tester.tap(find.byKey(const Key('tutorial-next')));
        await tester.pump();
      }
    }

    expect(find.text('게임 시작'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tutorial-finish')));
    expect(completions, 1);
  });

  testWidgets('tutorial can be skipped from any page', (tester) async {
    var completions = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: FirstRunTutorialOverlay(onCompleted: () => completions += 1),
      ),
    );

    await tester.tap(find.byKey(const Key('tutorial-skip')));
    expect(completions, 1);
  });
}
