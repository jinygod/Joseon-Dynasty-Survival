import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/compendium_screen.dart';
import 'package:pixel_survivor/app/joseon_tab_bar.dart';
import 'package:pixel_survivor/game/content/asset_catalog.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/models/compendium_entry.dart';
import 'package:pixel_survivor/game/systems/compendium_service.dart';
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

  testWidgets('unlocked character missing portrait shows its logical asset key', (
    tester,
  ) async {
    await tester.pumpWidget(_app(CompendiumScreen(state: SaveState.defaults())));
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        Key('missing-asset-${AssetCatalog.characterPortraits[rookieConstable]}'),
      ),
      findsOneWidget,
    );
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

    final lockedEntry = const CompendiumService()
        .entries(SaveState.defaults().copyWith(unlockedAugmentIds: const {}))
        .firstWhere((entry) => entry.section == CompendiumSection.augment);
    final grid = tester.widget<GridView>(find.byType(GridView));
    expect(
      (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      2,
    );
    expect(find.byKey(const Key('locked-silhouette')), findsWidgets);
    expect(find.byKey(const Key('locked-original-image')), findsNothing);
    expect(find.text(lockedEntry.name), findsNothing);
    expect(find.text(lockedEntry.detail), findsNothing);
    expect(find.textContaining(lockedEntry.unlockCondition), findsWidgets);
  });

  testWidgets('large text scale uses a single codex column', (tester) async {
    tester.view.physicalSize = const Size(375, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: CompendiumScreen(state: SaveState.defaults()),
        ),
      ),
    );

    final grid = tester.widget<GridView>(find.byType(GridView));
    expect(
      (grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
          .crossAxisCount,
      1,
    );
  });

  testWidgets('new unlocked codex entries expose a visible NEW state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(CompendiumScreen(state: SaveState.defaults())),
    );

    expect(find.byKey(const Key('new-entry')), findsWidgets);
    expect(find.text('NEW'), findsWidgets);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == '새 항목',
      ),
      findsWidgets,
    );
  });
}

Widget _app(Widget home) => MaterialApp(
  theme: ThemeData(splashFactory: NoSplash.splashFactory),
  home: home,
);
