import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/lobby_status_bar.dart';

void main() {
  testWidgets(
    'status bar keeps resource values, raster frames, and controls accessible',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: LobbyStatusBar(
                coin: 1200,
                spiritJade: 34,
                trainingRank: '\uac80\uc218',
                premiumEntry: GestureDetector(
                  onTap: () {},
                  child: const Text('\uc81c\ud488 \uc0c1\uc810'),
                ),
                onSettings: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('1200'), findsOneWidget);
      expect(find.text('34'), findsOneWidget);
      expect(find.text('\uac80\uc218'), findsOneWidget);
      expect(find.byKey(const Key('lobby-profile-frame')), findsOneWidget);
      expect(find.byKey(const Key('lobby-resource-frame')), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(const Key('lobby-settings'))),
        matchesSemantics(
          label: '\uc124\uc815',
          isButton: true,
          hasTapAction: true,
        ),
      );

      for (final finder in [
        find.byKey(const Key('lobby-settings')),
        find.descendant(
          of: find.byKey(const Key('lobby-premium-entry')),
          matching: find.byType(GestureDetector),
        ),
      ]) {
        final size = tester.getSize(finder);
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
    },
  );
}
