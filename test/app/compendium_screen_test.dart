import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/compendium_screen.dart';
import 'package:pixel_survivor/game/content/character_definitions.dart';
import 'package:pixel_survivor/game/content/weapon_definitions.dart';
import 'package:pixel_survivor/game/systems/save_system.dart';

void main() {
  testWidgets('shows three Korean sections and unseen unlocked badges', (
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
    expect(find.text('도감'), findsOneWidget);
    expect(find.text('인물'), findsOneWidget);
    expect(find.text('무기'), findsOneWidget);
    expect(find.text('증강'), findsOneWidget);
    expect(find.text('신참 포졸'), findsOneWidget);
    expect(find.text('새 항목'), findsWidgets);
    expect(viewed, contains('character:$rookieConstable'));
    expect(viewed, contains('weapon:$hwandoSlash'));
  });

  testWidgets('locked weapon shows Korean condition and progress', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        CompendiumScreen(state: SaveState.defaults().copyWith(totalKills: 120)),
      ),
    );

    await tester.tap(find.text('무기'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('벽력진천뢰'),
      180,
      scrollable: find.byType(Scrollable).last,
    );

    expect(find.text('벽력진천뢰'), findsOneWidget);
    expect(find.text('누적 적 300명 처치'), findsOneWidget);
    expect(find.text('120 / 300'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsWidgets);
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
}

Widget _app(Widget home) => MaterialApp(
  theme: ThemeData(splashFactory: NoSplash.splashFactory),
  home: home,
);
