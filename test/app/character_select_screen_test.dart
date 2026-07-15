import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/character_select_screen.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';

void main() {
  testWidgets('starts at saved character and returns the selected id', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: CharacterSelectScreen(
          initialCharacterId: exorcistDosa,
          unlockedCharacterIds: const {
            rookieConstable,
            exorcistDosa,
            mountainHunter,
          },
          onSelected: (value) => selected = value,
        ),
      ),
    );

    expect(
      find.byKey(const Key('character-selected-exorcist_dosa')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('character-confirm')));
    expect(selected, exorcistDosa);
  });

  testWidgets('locked character cannot replace the current selection', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: CharacterSelectScreen(
          initialCharacterId: rookieConstable,
          unlockedCharacterIds: const {rookieConstable},
          onSelected: (value) => selected = value,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('character-exorcist_dosa')));
    await tester.tap(find.byKey(const Key('character-confirm')));
    expect(selected, rookieConstable);
  });
}
