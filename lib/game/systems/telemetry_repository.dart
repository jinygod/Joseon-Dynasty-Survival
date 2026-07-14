import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/run_telemetry.dart';

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
    final saved = await activePreferences.setString(
      storageKey,
      jsonEncode(retained.map((run) => run.toJson()).toList()),
    );
    if (!saved) {
      throw StateError('Telemetry history write was rejected');
    }
  }
}
