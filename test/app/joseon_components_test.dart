import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/joseon_buttons.dart';
import 'package:pixel_survivor/app/joseon_codex_card.dart';
import 'package:pixel_survivor/app/joseon_panel.dart';
import 'package:pixel_survivor/app/joseon_resource_chip.dart';
import 'package:pixel_survivor/app/joseon_selection_card.dart';
import 'package:pixel_survivor/app/joseon_tab_bar.dart';
import 'package:pixel_survivor/app/joseon_ui_theme.dart';

void main() {
  test('theme exposes Joseon surface tokens', () {
    expect(JoseonUiTheme.navy, isA<Color>());
    expect(JoseonUiTheme.ivory, isA<Color>());
    expect(JoseonUiTheme.gold, isA<Color>());
    expect(JoseonUiTheme.danger, isA<Color>());
    expect(JoseonUiTheme.unlocked, isA<Color>());
    expect(JoseonUiTheme.panelBorderWidth, 1);
    expect(JoseonUiTheme.compactSpacing, greaterThan(0));
  });

  testWidgets('panel and resource chip render supplied content', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const JoseonPanel(
          child: JoseonResourceChip(label: '엽전', value: '120'),
        ),
      ),
    );

    expect(find.text('엽전'), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
  });

  testWidgets('buttons invoke their supplied callbacks', (tester) async {
    var primaryPressed = 0;
    var secondaryPressed = 0;
    await tester.pumpWidget(
      _app(
        Row(
          children: [
            JoseonPrimaryButton(label: '시작', onPressed: () => primaryPressed++),
            JoseonSecondaryButton(
              label: '닫기',
              onPressed: () => secondaryPressed++,
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('시작'));
    await tester.tap(find.text('닫기'));
    expect(primaryPressed, 1);
    expect(secondaryPressed, 1);
  });

  testWidgets('tab bar reports the tapped tab index', (tester) async {
    var selectedIndex = -1;
    await tester.pumpWidget(
      _app(
        JoseonTabBar(
          labels: const ['정보', '기록'],
          selectedIndex: 0,
          onChanged: (index) => selectedIndex = index,
        ),
      ),
    );

    await tester.tap(find.text('기록'));
    expect(selectedIndex, 1);
  });

  testWidgets('selection card exposes selected semantics and indicator', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        const JoseonSelectionCard(
          selected: true,
          locked: false,
          semanticsLabel: '호랑이 부적 선택됨',
          child: Text('호랑이 부적'),
        ),
      ),
    );

    expect(find.bySemanticsLabel('호랑이 부적 선택됨'), findsOneWidget);
    expect(find.byKey(const Key('selection-check')), findsOneWidget);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('호랑이 부적 선택됨'))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
    semantics.dispose();
  });

  testWidgets('locked selection and codex cards expose locked semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(
        const Column(
          children: [
            JoseonSelectionCard(
              selected: false,
              locked: true,
              semanticsLabel: '잠긴 부적',
              child: Text('부적'),
            ),
            JoseonCodexCard(
              title: '도감 항목',
              description: '아직 발견하지 못했습니다.',
              locked: true,
            ),
          ],
        ),
      ),
    );

    final lockedSelection = tester.getSemantics(find.bySemanticsLabel('잠긴 부적'));
    expect(lockedSelection.flagsCollection.isSelected, Tristate.isFalse);
    expect(lockedSelection.flagsCollection.isEnabled, Tristate.isFalse);
    expect(find.bySemanticsLabel('도감 항목, 잠김'), findsOneWidget);
    semantics.dispose();
  });
}

Widget _app(Widget child) => MaterialApp(
  theme: JoseonUiTheme.create(),
  home: Scaffold(body: Center(child: child)),
);
