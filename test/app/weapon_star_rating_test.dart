import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/weapon_star_rating.dart';

void main() {
  testWidgets('level six renders mastery instead of a sixth star', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(const WeaponStarRating(level: 6)));

    expect(find.text('통달'), findsOneWidget);
    expect(find.byKey(const Key('filled-star-5')), findsNothing);
  });
}

Widget _testApp(Widget child) => MaterialApp(home: Scaffold(body: child));
