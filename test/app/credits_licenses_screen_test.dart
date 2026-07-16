import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/credits_ledger.dart';
import 'package:pixel_survivor/app/credits_licenses_screen.dart';

void main() {
  test('ledger parser reads bundled art and audio attribution', () {
    final ledger = CreditsLedger.fromCsv(
      assetCsv: File('docs/assets/asset-rights-ledger.csv').readAsStringSync(),
      audioCsv: File('docs/assets/audio-rights-ledger.csv').readAsStringSync(),
    );

    expect(ledger.assets, isNotEmpty);
    expect(ledger.audio, isNotEmpty);
    expect(ledger.assets.first.runtimePath, startsWith('assets/images/'));
    expect(ledger.assets.first.license, 'OpenAI Terms of Use');
    expect(ledger.audio.first.creator, 'Kenney');
    expect(ledger.audio.first.license, 'CC0-1.0');
  });

  testWidgets('credits screen shows art and audio sources and licenses', (
    tester,
  ) async {
    final ledger = CreditsLedger.fromCsv(
      assetCsv: File('docs/assets/asset-rights-ledger.csv').readAsStringSync(),
      audioCsv: File('docs/assets/audio-rights-ledger.csv').readAsStringSync(),
    );
    await tester.pumpWidget(
      MaterialApp(home: CreditsLicensesScreen(ledger: ledger)),
    );

    expect(
      find.text('\uD06C\uB808\uB527 \uBC0F \uB77C\uC774\uC120\uC2A4'),
      findsOneWidget,
    );
    expect(
      find.text('\uBC88\uB4E4 \uC774\uBBF8\uC9C0 \uC790\uC0B0'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('\uBC88\uB4E4 \uC74C\uC6D0'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('\uBC88\uB4E4 \uC74C\uC6D0'), findsOneWidget);
    expect(find.textContaining('OpenAI Terms of Use'), findsWidgets);
    await tester.scrollUntilVisible(
      find.textContaining('Kenney').first,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('CC0-1.0'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
