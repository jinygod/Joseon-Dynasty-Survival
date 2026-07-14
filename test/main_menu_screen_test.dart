import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/game_screen.dart';
import 'package:pixel_survivor/app/pixel_survivor_app.dart';
import 'package:pixel_survivor/game/systems/tutorial_progress_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows the Joseon Dynasty Survival main menu', (tester) async {
    await tester.pumpWidget(const PixelSurvivorApp());

    expect(find.text('Joseon Dynasty Survival'), findsOneWidget);
    expect(find.text('Start Run'), findsOneWidget);
  });

  testWidgets('navigates to the game screen when Start Run is pressed', (
    tester,
  ) async {
    await tester.pumpWidget(const PixelSurvivorApp());

    await tester.tap(find.widgetWithText(FilledButton, 'Start Run'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.byKey(const Key('tutorial-next')), findsOneWidget);
  });

  testWidgets('returning players bypass the first-run tutorial', (
    tester,
  ) async {
    await TutorialProgressRepository().markCompleted();
    await tester.pumpWidget(const PixelSurvivorApp());

    await tester.tap(find.widgetWithText(FilledButton, 'Start Run'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.byKey(const Key('tutorial-next')), findsNothing);
  });
}
