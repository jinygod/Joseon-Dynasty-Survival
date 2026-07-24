import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/training_screen.dart';
import 'package:pixel_survivor/game/models/meta_progress.dart';

void main() {
  testWidgets('training screen presents persisted progress as read-only', (
    tester,
  ) async {
    const progress = TrainingProgress(
      commonRanks: {'common.max_health': 2},
      characterRanks: {
        'rookie_constable': {'base_damage': 1},
      },
      activeCoreTraitIds: {'rookie_constable': 'constable.stalwart'},
    );

    await tester.pumpWidget(
      const MaterialApp(home: TrainingScreen(progress: progress)),
    );

    expect(find.byKey(const Key('training-screen')), findsOneWidget);
    expect(find.byKey(const Key('training-read-only-notice')), findsOneWidget);
    expect(find.text('common.max_health'), findsOneWidget);
    expect(find.text('Rank 2'), findsOneWidget);
    expect(find.text('rookie_constable'), findsOneWidget);
    expect(
      find.textContaining('constable.stalwart', skipOffstage: false),
      findsOneWidget,
    );
    expect(find.byType(FilledButton), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
