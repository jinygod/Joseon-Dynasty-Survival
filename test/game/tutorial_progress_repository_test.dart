import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/systems/tutorial_progress_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'unrelated': true});
  });

  test('tutorial is unseen by default and completion persists', () async {
    final preferences = await SharedPreferences.getInstance();
    final repository = TutorialProgressRepository(preferences: preferences);

    expect(await repository.isCompleted(), isFalse);
    await repository.markCompleted();

    expect(await repository.isCompleted(), isTrue);
    expect(preferences.getBool('unrelated'), isTrue);
  });
}
