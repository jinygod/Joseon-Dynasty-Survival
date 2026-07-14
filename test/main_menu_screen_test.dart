import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/character_select_screen.dart';
import 'package:pixel_survivor/app/game_screen.dart';
import 'package:pixel_survivor/app/pixel_survivor_app.dart';
import 'package:pixel_survivor/app/stage_select_screen.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/pixel_survivor_game.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';
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

  testWidgets('navigates through character selection into the first run', (
    tester,
  ) async {
    await tester.pumpWidget(const PixelSurvivorApp());

    await tester.tap(find.widgetWithText(FilledButton, 'Start Run'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(CharacterSelectScreen), findsOneWidget);
    expect(find.byType(GameScreen), findsNothing);

    await tester.tap(find.byKey(const Key('character-start')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(StageSelectScreen), findsOneWidget);
    expect(find.byType(GameScreen), findsNothing);
    await tester.tap(find.byKey(const Key('stage-start')));
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
    await tester.tap(find.byKey(const Key('character-start')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('stage-start')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(GameScreen), findsOneWidget);
    expect(find.byKey(const Key('tutorial-next')), findsNothing);
  });

  testWidgets('selected unlocked character reaches the actual game slot', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await SaveSystem(preferences: preferences).save(
      SaveState.defaults().copyWith(
        unlockedCharacterIds: {rookieConstable, exorcistDosa},
      ),
    );
    await TutorialProgressRepository(preferences: preferences).markCompleted();
    await tester.pumpWidget(const PixelSurvivorApp());

    await tester.tap(find.widgetWithText(FilledButton, 'Start Run'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('character-exorcist_dosa')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('character-start')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('stage-start')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final gameWidget = tester.widget<GameWidget<PixelSurvivorGame>>(
      find.byType(GameWidget<PixelSurvivorGame>),
    );
    expect(gameWidget.game!.playerSlot.characterId, exorcistDosa);
  });
}
