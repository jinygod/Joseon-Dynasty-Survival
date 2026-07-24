import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/stage_select_screen.dart';
import 'package:pixel_survivor/game/content/stage_definitions.dart';

void main() {
  Future<void> pumpStageSelect(
    WidgetTester tester, {
    required Size size,
    String initialStageId = moonlitAbandonedOffice,
    Set<String> unlockedStageIds = const {moonlitAbandonedOffice},
    ValueChanged<String>? onSelected,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: StageSelectScreen(
          initialStageId: initialStageId,
          unlockedStageIds: unlockedStageIds,
          onSelected: onSelected ?? (_) {},
        ),
      ),
    );
  }

  testWidgets('portrait stage carousel keeps details inside its card', (
    tester,
  ) async {
    await pumpStageSelect(tester, size: const Size(390, 844));
    await tester.pumpAndSettle();

    expect(find.byType(PageView), findsOneWidget);
    expect(
      find.byKey(const Key('stage-illustration-moonlit_abandoned_office')),
      findsOneWidget,
    );
    expect(find.textContaining('5:00'), findsAtLeastNWidgets(1));
    final illustration = tester.getRect(
      find.byKey(const Key('stage-illustration-slot-moonlit_abandoned_office')),
    );
    expect(illustration.width / illustration.height, closeTo(16 / 9, .02));
    expect(find.textContaining('ASSET MISSING'), findsAtLeastNWidgets(1));
    expect(
      find.textContaining('moonlit_abandoned_office_presentation'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('locked stage page can be browsed but cannot be confirmed', (
    tester,
  ) async {
    String? selected;
    await pumpStageSelect(
      tester,
      size: const Size(375, 667),
      onSelected: (value) => selected = value,
    );

    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stage-lock-plague_market')), findsOneWidget);
    await tester.tap(find.byKey(const Key('stage-confirm')));
    expect(selected, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('portrait stage carousel has no overflow at tall width', (
    tester,
  ) async {
    await pumpStageSelect(tester, size: const Size(430, 932));
    expect(tester.takeException(), isNull);
  });

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
    expect(find.textContaining('5:00'), findsAtLeastNWidgets(1));
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
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();

    expect(find.textContaining('위험'), findsAtLeastNWidgets(1));
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

    await tester.drag(find.byType(PageView), const Offset(-320, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stage-lock-plague_market')), findsOneWidget);
    await tester.tap(find.byKey(const Key('stage-confirm')));

    expect(selected, moonlitAbandonedOffice);
  });
}
