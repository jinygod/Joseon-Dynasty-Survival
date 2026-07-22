import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/joseon_game_button.dart';

void main() {
  testWidgets('game button exposes face, depth, and a 72px target', (
    tester,
  ) async {
    var taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: JoseonGameButton(
            debugId: 'test-button',
            semanticLabel: '시험 버튼',
            minimumSize: const Size(96, 72),
            onPressed: () => taps += 1,
            child: const Text('시험'),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('test-button-face')), findsOneWidget);
    expect(find.byKey(const Key('test-button-depth')), findsOneWidget);
    expect(
      tester.getSize(find.byType(JoseonGameButton)).height,
      greaterThanOrEqualTo(72),
    );

    await tester.tap(find.byType(JoseonGameButton));
    expect(taps, 1);
  });

  testWidgets('game button keeps at least a 64 by 72 target', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: JoseonGameButton(
            debugId: 'small-button',
            semanticLabel: '작은 버튼',
            minimumSize: const Size(1, 1),
            onPressed: () {},
            child: const Text('작은'),
          ),
        ),
      ),
    );

    final size = tester.getSize(find.byType(JoseonGameButton));
    expect(size.width, greaterThanOrEqualTo(64));
    expect(size.height, greaterThanOrEqualTo(72));
  });
}
