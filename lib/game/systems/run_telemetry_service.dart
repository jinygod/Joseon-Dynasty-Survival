import 'package:package_info_plus/package_info_plus.dart';

import '../models/run_result.dart';
import '../models/run_telemetry.dart';
import 'telemetry_repository.dart';

typedef TelemetryAppend = Future<void> Function(RunTelemetry telemetry);
typedef AppVersionLoader = Future<String> Function();
typedef UtcClock = DateTime Function();

class RunTelemetryService {
  RunTelemetryService({
    TelemetryAppend? append,
    AppVersionLoader? loadAppVersion,
    UtcClock? now,
  }) : _append = append ?? TelemetryRepository().append,
       _loadAppVersion = loadAppVersion ?? _platformAppVersion,
       _now = now ?? DateTime.now;

  final TelemetryAppend _append;
  final AppVersionLoader _loadAppVersion;
  final UtcClock _now;

  Future<void> record(
    RunResult result, {
    required DateTime startedAtUtc,
  }) async {
    try {
      final endedAtUtc = _now().toUtc();
      final appVersion = await _loadAppVersion();
      final normalizedStart = startedAtUtc.toUtc();
      final telemetry = RunTelemetry.fromRunResult(
        result: result,
        runId:
            '${normalizedStart.microsecondsSinceEpoch}-${endedAtUtc.microsecondsSinceEpoch}',
        appVersion: appVersion,
        startedAtUtc: normalizedStart,
        endedAtUtc: endedAtUtc,
      );
      await _append(telemetry);
    } on Object {
      // Playtest telemetry must never block progression saving or navigation.
    }
  }

  static Future<String> _platformAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final buildNumber = packageInfo.buildNumber;
    return buildNumber.isEmpty
        ? packageInfo.version
        : '${packageInfo.version}+$buildNumber';
  }
}
