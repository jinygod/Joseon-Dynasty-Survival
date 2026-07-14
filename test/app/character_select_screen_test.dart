import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/character_select_screen.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/models/player_slot.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('defaults select constable and show dosa as locked', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    PlayerSlot? launched;
    await tester.pumpWidget(
      MaterialApp(
        home: CharacterSelectScreen(
          saveSystem: SaveSystem(preferences: preferences),
          onStart: (slot) => launched = slot,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('character-rookie_constable')), findsOneWidget);
    expect(find.byKey(const Key('character-exorcist_dosa')), findsOneWidget);
    expect(
      find.byKey(const Key('character-lock-exorcist_dosa')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('character-start')));
    expect(launched?.characterId, rookieConstable);
  });

  testWidgets('an unlocked dosa can be selected and launched', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final saveSystem = SaveSystem(preferences: preferences);
    await saveSystem.save(
      SaveState.defaults().copyWith(
        unlockedCharacterIds: {rookieConstable, exorcistDosa},
      ),
    );
    PlayerSlot? launched;
    await tester.pumpWidget(
      MaterialApp(
        home: CharacterSelectScreen(
          saveSystem: saveSystem,
          onStart: (slot) => launched = slot,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('character-exorcist_dosa')));
    await tester.pump();
    expect(
      find.byKey(const Key('character-selected-exorcist_dosa')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('character-start')));

    expect(launched?.characterId, exorcistDosa);
    expect(launched?.index, 0);
    expect(launched?.isActive, isTrue);
  });
}
