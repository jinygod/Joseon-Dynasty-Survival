import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/compendium_screen.dart';
import 'package:pixel_survivor/app/joseon_tab_bar.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';

void main() {
  testWidgets('shows three sections and records unseen base entries', (
    tester,
  ) async {
    Set<String>? viewed;
    await tester.pumpWidget(
      _app(
        CompendiumScreen(
          state: SaveState.defaults(),
          onEntriesViewed: (keys) async => viewed = keys,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(SafeArea), findsWidgets);
    expect(find.byType(JoseonTabBar), findsOneWidget);
    expect(find.text(characterDefinitions.first.name), findsOneWidget);
    expect(viewed, contains('character:$rookieConstable'));
    expect(viewed, contains('weapon:$hwandoSlash'));
  });

  testWidgets('base weapon is available without legacy unlock progress', (
    tester,
  ) async {
    final bombName = weaponDefinitions
        .firstWhere((weapon) => weapon.id == thunderCrashBomb)
        .name;
    await tester.pumpWidget(
      _app(
        CompendiumScreen(state: SaveState.defaults().copyWith(totalKills: 120)),
      ),
    );

    await tester.tap(find.text('무기'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(bombName),
      180,
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.text(bombName), findsOneWidget);
    expect(find.text('120 / 300'), findsNothing);
    expect(find.byIcon(Icons.lock_outline), findsNothing);
  });

  testWidgets('small phone can scroll without layout overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(CompendiumScreen(state: SaveState.defaults())),
    );
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -300));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('locked codex entry hides original asset and shows condition', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(
        CompendiumScreen(
          state: SaveState.defaults().copyWith(unlockedAugmentIds: const {}),
        ),
      ),
    );
    await tester.tap(find.text('증강'));
    await tester.pumpAndSettle();

    expect(find.byType(GridView), findsOneWidget);
    expect(find.byKey(const Key('locked-silhouette')), findsWidgets);
    expect(find.byKey(const Key('locked-original-image')), findsNothing);
    expect(find.textContaining('해금 조건'), findsWidgets);
  });
}

Widget _app(Widget home) => MaterialApp(
  theme: ThemeData(splashFactory: NoSplash.splashFactory),
  home: home,
);
