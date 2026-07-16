import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/stage_select_screen.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';

void main() {
  testWidgets('starts at saved stage and returns its id', (tester) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: StageSelectScreen(
          initialStageId: moonlitAbandonedOffice,
          unlockedStageIds: const {moonlitAbandonedOffice, plagueMarket},
          onSelected: (value) => selected = value,
        ),
      ),
    );

    expect(find.text('달빛 폐관아'), findsOneWidget);
    expect(find.textContaining('5:00'), findsOneWidget);
    await tester.tap(find.byKey(const Key('stage-confirm')));
    expect(selected, moonlitAbandonedOffice);
  });

  testWidgets('selects plague market and shows its risk', (tester) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: StageSelectScreen(
          initialStageId: moonlitAbandonedOffice,
          unlockedStageIds: const {moonlitAbandonedOffice, plagueMarket},
          onSelected: (value) => selected = value,
        ),
      ),
    );

    expect(find.text('달빛 폐관아'), findsOneWidget);
    expect(find.text('역병 장터'), findsOneWidget);
    await tester.tap(find.byKey(const Key('stage-plague_market')));
    await tester.pump();

    expect(find.textContaining('위험'), findsOneWidget);
    await tester.tap(find.byKey(const Key('stage-confirm')));
    expect(selected, plagueMarket);
  });

  testWidgets('locked plague market cannot be selected or confirmed', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: StageSelectScreen(
          initialStageId: plagueMarket,
          unlockedStageIds: const {moonlitAbandonedOffice},
          onSelected: (value) => selected = value,
        ),
      ),
    );

    expect(find.byKey(const Key('stage-lock-plague_market')), findsOneWidget);
    await tester.tap(find.byKey(const Key('stage-plague_market')));
    await tester.tap(find.byKey(const Key('stage-confirm')));

    expect(selected, moonlitAbandonedOffice);
  });
}
