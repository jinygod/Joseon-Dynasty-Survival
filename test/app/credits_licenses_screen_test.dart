import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/credits_ledger.dart';
import 'package:pixel_survivor/app/credits_licenses_screen.dart';

void main() {
  testWidgets('asset bundle loader parses the packaged art and audio ledgers', (
    tester,
  ) async {
    final ledger = await CreditsLedger.fromAssetBundle(rootBundle);

    expect(ledger.assets.length, greaterThan(1));
    expect(ledger.audio.length, greaterThan(1));
    expect(
      ledger.assets.first.runtimePath,
      'assets/images/player/rookie_constable_player_32.png',
    );
    expect(ledger.assets.first.status, 'approved');
    expect(ledger.audio.first.status, 'temporary');
  });

  testWidgets('async credits show every field and status at text scale two', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var loadCount = 0;
    const ledger = CreditsLedger(
      assets: [
        CreditEntry(
          runtimePath: 'assets/images/player/reviewer.png',
          creator: 'OpenAI',
          sourceUrl: 'https://openai.com/policies/terms-of-use/',
          license: 'OpenAI Terms of Use',
          status: 'approved',
        ),
      ],
      audio: [
        CreditEntry(
          runtimePath: 'assets/audio/music/reviewer.ogg',
          creator: 'Kenney',
          sourceUrl: 'https://kenney.nl/assets/music-jingles',
          license: 'CC0-1.0',
          status: 'temporary',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: CreditsLicensesScreen(
          loader: () async {
            loadCount += 1;
            return ledger;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(loadCount, 1);
    expect(find.text('assets/images/player/reviewer.png'), findsOneWidget);
    expect(
      find.text('https://openai.com/policies/terms-of-use/'),
      findsOneWidget,
    );
    expect(find.text('\uC2B9\uC778\uB428'), findsOneWidget);
    expect(find.byIcon(Icons.verified_outlined), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('assets/audio/music/reviewer.ogg'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('https://kenney.nl/assets/music-jingles'), findsOneWidget);
    expect(find.text('\uC784\uC2DC'), findsOneWidget);
    expect(find.byIcon(Icons.schedule_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
