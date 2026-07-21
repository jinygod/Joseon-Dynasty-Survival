import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/mobile_preview.dart';

void main() {
  group('MobilePreviewPolicy', () {
    test('enables only requested debug web previews', () {
      expect(
        MobilePreviewPolicy.shouldEnable(
          isWeb: true,
          isDebug: true,
          requested: true,
        ),
        isTrue,
      );
      expect(
        MobilePreviewPolicy.shouldEnable(
          isWeb: false,
          isDebug: true,
          requested: true,
        ),
        isFalse,
      );
      expect(
        MobilePreviewPolicy.shouldEnable(
          isWeb: true,
          isDebug: false,
          requested: true,
        ),
        isFalse,
      );
      expect(
        MobilePreviewPolicy.shouldEnable(
          isWeb: true,
          isDebug: true,
          requested: false,
        ),
        isFalse,
      );
    });
  });

  group('MobilePreviewFrame', () {
    testWidgets('contains a 390x844 portrait viewport', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox.expand(
            child: MobilePreviewFrame(enabled: true, child: _MediaQueryProbe()),
          ),
        ),
      );

      expect(MobilePreviewFrame.referenceSize, const Size(390, 844));
      expect(
        tester.getSize(find.byKey(MobilePreviewFrame.frameKey)),
        const Size(390, 844),
      );
      expect(find.text('390x844:24:16'), findsOneWidget);
      expect(find.byKey(MobilePreviewFrame.backgroundKey), findsOneWidget);
    });

    testWidgets('keeps the reference aspect ratio in a smaller browser', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 600);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: MobilePreviewFrame(
            enabled: true,
            child: ColoredBox(color: Colors.red),
          ),
        ),
      );

      final fittedBox = tester.widget<FittedBox>(find.byType(FittedBox));
      expect(fittedBox.fit, BoxFit.contain);
      expect(
        tester.getSize(find.byKey(MobilePreviewFrame.frameKey)).aspectRatio,
        closeTo(390 / 844, 0.000001),
      );
    });

    testWidgets('disabled mode leaves platform layout untouched', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 600);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: MobilePreviewFrame(enabled: false, child: _MediaQueryProbe()),
        ),
      );

      expect(find.byKey(MobilePreviewFrame.backgroundKey), findsNothing);
      expect(find.byKey(MobilePreviewFrame.frameKey), findsNothing);
      expect(find.text('800x600:0:0'), findsOneWidget);
    });
  });
}

class _MediaQueryProbe extends StatelessWidget {
  const _MediaQueryProbe();

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Text(
      '${media.size.width.round()}x${media.size.height.round()}:'
      '${media.padding.top.round()}:${media.padding.bottom.round()}',
      textDirection: TextDirection.ltr,
    );
  }
}
