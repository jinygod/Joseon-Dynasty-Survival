import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/run_telemetry.dart';
import '../models/run_feedback.dart';

class TelemetryRepository {
  TelemetryRepository({this.preferences});

  static const storageKey = 'run_telemetry_history';
  static const maxRuns = 50;

  final SharedPreferences? preferences;

  Future<List<RunTelemetry>> load() async {
    final activePreferences =
        preferences ?? await SharedPreferences.getInstance();
    final rawHistory = activePreferences.getString(storageKey);
    if (rawHistory == null) return const [];

    Object? decoded;
    try {
      decoded = jsonDecode(rawHistory);
    } on Object {
      return const [];
    }
    if (decoded is! List) return const [];

    final history = <RunTelemetry>[];
    for (final entry in decoded) {
      if (entry is! Map) continue;
      try {
        history.add(RunTelemetry.fromJson(Map<String, dynamic>.from(entry)));
      } on Object {
        continue;
      }
    }
    return List.unmodifiable(history);
  }

  Future<void> append(RunTelemetry telemetry) async {
    final activePreferences =
        preferences ?? await SharedPreferences.getInstance();
    final history = [...await load(), telemetry];
    final retained = history.length <= maxRuns
        ? history
        : history.sublist(history.length - maxRuns);
    await _saveHistory(activePreferences, retained);
  }

  Future<bool> updateFeedback(String runId, RunFeedback feedback) async {
    final activePreferences =
        preferences ?? await SharedPreferences.getInstance();
    final history = [...await load()];
    final index = history.indexWhere((run) => run.runId == runId);
    if (index < 0) return false;

    history[index] = history[index].copyWith(feedback: feedback);
    await _saveHistory(activePreferences, history);
    return true;
  }

  Future<void> _saveHistory(
    SharedPreferences activePreferences,
    List<RunTelemetry> history,
  ) async {
    final saved = await activePreferences.setString(
      storageKey,
      jsonEncode(history.map((run) => run.toJson()).toList()),
    );
    if (!saved) {
      throw StateError('Telemetry history write was rejected');
    }
  }
}
