import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/joseon_scaffold.dart';

void main() {
  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.clearAllTestValues();
  });

  testWidgets('bottom action stays visible at 375x667 with view padding', (
    tester,
  ) async {
    await _pumpScaffold(
      tester,
      size: const Size(375, 667),
      viewPadding: const EdgeInsets.only(top: 24, bottom: 20),
    );

    final action = find.byKey(const Key('fixed-action'));
    expect(action, findsOneWidget);
    expect(tester.getRect(action).bottom, 647);
    expect(tester.takeException(), isNull);
  });

  testWidgets('top and bottom bars respect portrait insets at 390x844', (
    tester,
  ) async {
    await _pumpScaffold(
      tester,
      size: const Size(390, 844),
      viewPadding: const EdgeInsets.only(top: 24, bottom: 20),
    );

    expect(tester.getRect(find.byKey(const Key('top-bar'))).top, 24);
    expect(tester.getRect(find.byKey(const Key('fixed-action'))).bottom, 824);
  });

  testWidgets('bottom action remains fixed outside body scroll at 430x932', (
    tester,
  ) async {
    await _pumpScaffold(
      tester,
      size: const Size(430, 932),
      viewPadding: const EdgeInsets.only(top: 24, bottom: 20),
    );

    final action = find.byKey(const Key('fixed-action'));
    final beforeScroll = tester.getRect(action);
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();

    expect(tester.getRect(action), beforeScroll);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpScaffold(
  WidgetTester tester, {
  required Size size,
  required EdgeInsets viewPadding,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(padding: viewPadding, viewPadding: viewPadding),
          child: child!,
        );
      },
      home: JoseonScaffold(
        topBar: const SizedBox(key: Key('top-bar'), height: 48),
        body: ListView(children: const [SizedBox(height: 1600)]),
        bottomBar: const SizedBox(key: Key('fixed-action'), height: 48),
      ),
    ),
  );
}
