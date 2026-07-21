import 'package:shared_preferences/shared_preferences.dart';

class PlaytestSessionRepository {
  PlaytestSessionRepository({this.preferences});

  static const _runCountKey = 'playtest_run_count';

  final SharedPreferences? preferences;

  Future<int> beginRun() async {
    final activePreferences =
        preferences ?? await SharedPreferences.getInstance();
    final ordinal = (activePreferences.getInt(_runCountKey) ?? 0) + 1;
    await activePreferences.setInt(_runCountKey, ordinal);
    return ordinal;
  }
}
