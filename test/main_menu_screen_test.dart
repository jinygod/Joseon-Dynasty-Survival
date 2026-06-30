import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/app/pixel_survivor_app.dart';

void main() {
  testWidgets('shows the Pixel Survivor main menu', (tester) async {
    await tester.pumpWidget(const PixelSurvivorApp());

    expect(find.text('Pixel Survivor'), findsOneWidget);
    expect(find.text('Start Run'), findsOneWidget);
  });
}
