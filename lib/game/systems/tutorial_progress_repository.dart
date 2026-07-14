import 'package:shared_preferences/shared_preferences.dart';

class TutorialProgressRepository {
  TutorialProgressRepository({this.preferences});

  static const _completionKey = 'first_run_tutorial_completed';

  final SharedPreferences? preferences;

  Future<bool> isCompleted() async {
    final activePreferences =
        preferences ?? await SharedPreferences.getInstance();
    return activePreferences.getBool(_completionKey) ?? false;
  }

  Future<void> markCompleted() async {
    final activePreferences =
        preferences ?? await SharedPreferences.getInstance();
    await activePreferences.setBool(_completionKey, true);
  }
}
