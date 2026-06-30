import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/pixel_survivor_app.dart';

void main() {
  testWidgets('shows the Joseon Dynasty Survival main menu', (tester) async {
    await tester.pumpWidget(const PixelSurvivorApp());

    expect(find.text('Joseon Dynasty Survival'), findsOneWidget);
    expect(find.text('Start Run'), findsOneWidget);
  });
}
