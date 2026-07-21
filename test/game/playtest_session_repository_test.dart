import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/systems/playtest_session_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('second begun run is reported as repeat play', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final repository = PlaytestSessionRepository(preferences: preferences);

    expect(await repository.beginRun(), 1);
    expect(await repository.beginRun(), 2);
  });
}
