import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/character_select_screen.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';

void main() {
  Future<void> pumpCharacterSelect(
    WidgetTester tester, {
    required Size size,
    String initialCharacterId = rookieConstable,
    Set<String> unlockedCharacterIds = const {rookieConstable},
    ValueChanged<String>? onSelected,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: CharacterSelectScreen(
          initialCharacterId: initialCharacterId,
          unlockedCharacterIds: unlockedCharacterIds,
          onSelected: onSelected ?? (_) {},
        ),
      ),
    );
  }

  testWidgets(
    'portrait carousel shows integer stats and fixed confirm action',
    (tester) async {
      await pumpCharacterSelect(tester, size: const Size(390, 844));

      expect(find.byType(PageView), findsOneWidget);
      expect(find.textContaining('105'), findsOneWidget);
      expect(find.byKey(const Key('character-confirm')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('locked character page can be browsed but cannot be confirmed', (
    tester,
  ) async {
    String? selected;
    await pumpCharacterSelect(
      tester,
      size: const Size(375, 667),
      onSelected: (value) => selected = value,
    );

    await tester.drag(find.byType(PageView), const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('character-lock-exorcist_dosa')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('character-confirm')));
    expect(selected, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('portrait character carousel has no overflow at tall width', (
    tester,
  ) async {
    await pumpCharacterSelect(tester, size: const Size(430, 932));
    expect(tester.takeException(), isNull);
  });

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
    expect(
      find.descendant(
        of: find.byKey(const Key('character-exorcist_dosa')),
        matching: find.text('\uC120\uD0DD\uB428'),
      ),
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

    await tester.drag(find.byType(PageView), const Offset(-320, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('character-confirm')));
    expect(selected, rookieConstable);
  });
}
