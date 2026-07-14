import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/pause_menu_overlay.dart';

void main() {
  testWidgets('pause menu exposes every run action', (tester) async {
    var resumes = 0;
    var restarts = 0;
    var exits = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PauseMenuOverlay(
          onResume: () => resumes += 1,
          onRestart: () => restarts += 1,
          onExitToMenu: () => exits += 1,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('pause-resume')));
    await tester.tap(find.byKey(const Key('pause-restart')));
    await tester.tap(find.byKey(const Key('pause-menu')));

    expect((resumes, restarts, exits), (1, 1, 1));
  });

  testWidgets('settings entry can return to pause menu', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PauseMenuOverlay(
          onResume: () {},
          onRestart: () {},
          onExitToMenu: () {},
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('pause-settings')));
    await tester.pump();
    expect(find.text('설정'), findsOneWidget);
    expect(find.textContaining('정식 설정은'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pause-settings-back')));
    await tester.pump();
    expect(find.byKey(const Key('pause-resume')), findsOneWidget);
  });
}
