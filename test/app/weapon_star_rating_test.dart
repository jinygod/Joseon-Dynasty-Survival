import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/weapon_star_rating.dart';

void main() {
  testWidgets('level six renders mastery instead of a sixth star', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(const WeaponStarRating(level: 6)));

    expect(find.text('통달'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNWidgets(5));
    for (var index = 0; index < 5; index++) {
      expect(find.byKey(Key('filled-star-$index')), findsOneWidget);
    }
    expect(find.byKey(const Key('filled-star-5')), findsNothing);
  });

  testWidgets('levels one through five use five slots with matching fills', (
    tester,
  ) async {
    for (var level = 1; level <= 5; level++) {
      await tester.pumpWidget(_testApp(WeaponStarRating(level: level)));

      expect(find.byIcon(Icons.star), findsNWidgets(level));
      expect(find.byIcon(Icons.star_border), findsNWidgets(5 - level));
      for (var index = 0; index < 5; index++) {
        expect(
          find.byKey(Key('${index < level ? 'filled' : 'empty'}-star-$index')),
          findsOneWidget,
        );
      }
    }
  });

  testWidgets('out of range levels clamp to the supported rating range', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(const WeaponStarRating(level: 0)));
    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(find.byIcon(Icons.star_border), findsNWidgets(4));

    await tester.pumpWidget(_testApp(const WeaponStarRating(level: 7)));
    expect(find.byIcon(Icons.star), findsNWidgets(5));
    expect(find.text('통달'), findsOneWidget);
    expect(find.byKey(const Key('filled-star-5')), findsNothing);
  });

  testWidgets('compact mastery retains the mastery label', (tester) async {
    await tester.pumpWidget(
      _testApp(const WeaponStarRating(level: 6, compact: true)),
    );

    expect(find.text('통달'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNWidgets(5));
    expect(find.byIcon(Icons.star_border), findsNothing);
  });
}

Widget _testApp(Widget child) => MaterialApp(home: Scaffold(body: child));
