import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/character_select_screen.dart';
import 'package:pixel_survivor/game/content/asset_catalog.dart';
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
          key: ValueKey(initialCharacterId),
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

  testWidgets('locked character card states its actual boss-defeat condition', (
    tester,
  ) async {
    await pumpCharacterSelect(tester, size: const Size(375, 667));

    await tester.drag(find.byType(PageView), const Offset(-320, 0));
    await tester.pumpAndSettle();

    expect(
      find.text('\uBCF4\uC2A4 1\uD68C \uACA9\uD30C \uC2DC \uD574\uAE08'),
      findsOneWidget,
    );
  });

  testWidgets('missing logical portrait shows its debug asset key', (
    tester,
  ) async {
    await tester.pumpWidget(
      DefaultAssetBundle(
        bundle: _FailingAssetBundle(),
        child: _app(
          CharacterSelectScreen(
            initialCharacterId: rookieConstable,
            unlockedCharacterIds: const {rookieConstable},
            onSelected: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        Key(
          'missing-asset-${AssetCatalog.characterPortraits[rookieConstable]}',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('character cards show their presentation-only role tag', (
    tester,
  ) async {
    for (final entry in const {
      rookieConstable: '균형형',
      exorcistDosa: '술법형',
      mountainHunter: '기동형',
    }.entries) {
      await pumpCharacterSelect(
        tester,
        size: const Size(390, 844),
        initialCharacterId: entry.key,
        unlockedCharacterIds: characterDefinitions
            .map((item) => item.id)
            .toSet(),
      );
      expect(find.text(entry.value), findsOneWidget);
    }
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

Widget _app(Widget home) => MaterialApp(
  theme: ThemeData(splashFactory: NoSplash.splashFactory),
  home: home,
);

class _FailingAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) =>
      Future<ByteData>.error(StateError('Missing test asset: $key'));
}
